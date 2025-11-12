import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myfriends_app/models/sos_model.dart';
import 'package:myfriends_app/services/location_service.dart';
import 'package:myfriends_app/services/notification_service.dart';

/// SOS Provider
///
/// Manages SOS message state and handles sending/cancelling SOS alerts
class SOSProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocationService _locationService = LocationService();
  final NotificationService _notificationService = NotificationService();

  // Current user ID
  String? _currentUserId;

  // Active SOS messages
  SOSMessage? _activeSOS;
  List<SOSMessage> _receivedSOSMessages = [];

  // Loading state
  bool _isSending = false;
  String? _errorMessage;

  // Stream subscriptions
  StreamSubscription<QuerySnapshot>? _sentSOSSubscription;
  StreamSubscription<QuerySnapshot>? _receivedSOSSubscription;

  // --- Getters ---
  SOSMessage? get activeSOS => _activeSOS;
  List<SOSMessage> get receivedSOSMessages => _receivedSOSMessages;
  bool get isSending => _isSending;
  String? get errorMessage => _errorMessage;
  bool get hasActiveSOS => _activeSOS != null && _activeSOS!.isActive;

  /// Set current user ID and start listening to SOS messages
  void setUserId(String? userId) {
    _currentUserId = userId;
    if (userId != null) {
      listenToSentSOS();
      listenToReceivedSOS();
    } else {
      _sentSOSSubscription?.cancel();
      _receivedSOSSubscription?.cancel();
      _activeSOS = null;
      _receivedSOSMessages = [];
      notifyListeners();
    }
  }

  /// Listen to SOS messages sent by current user
  void listenToSentSOS() {
    if (_currentUserId == null) return;

    _sentSOSSubscription?.cancel();

    _sentSOSSubscription = _firestore
        .collection('sos_messages')
        .where('senderId', isEqualTo: _currentUserId)
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        _activeSOS = SOSMessage.fromFirestore(snapshot.docs.first);
      } else {
        _activeSOS = null;
      }
      notifyListeners();

      if (kDebugMode) {
        print('🚨 Active SOS updated: ${_activeSOS?.id}');
      }
    });
  }

  /// Listen to SOS messages received by current user (as emergency contact)
  void listenToReceivedSOS() {
    if (_currentUserId == null) return;

    _receivedSOSSubscription?.cancel();

    _receivedSOSSubscription = _firestore
        .collection('sos_messages')
        .where('emergencyContactIds', arrayContains: _currentUserId)
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      _receivedSOSMessages = snapshot.docs
          .map((doc) => SOSMessage.fromFirestore(doc))
          .toList();
      notifyListeners();

      if (kDebugMode) {
        print('📨 Received SOS messages: ${_receivedSOSMessages.length}');
      }
    });
  }

  /// Send SOS to emergency contacts
  ///
  /// Parameters:
  /// - emergencyContactIds: List of user IDs to send SOS to
  /// - senderName: Name of the user sending SOS
  /// - senderPhone: Phone number of the user sending SOS
  /// - message: Optional custom message (default: "I need help!")
  Future<void> sendSOS({
    required List<String> emergencyContactIds,
    required String senderName,
    required String senderPhone,
    String message = 'I need help! Please check my location.',
  }) async {
    if (_currentUserId == null) {
      throw Exception('User not logged in');
    }

    if (emergencyContactIds.isEmpty) {
      throw Exception('No emergency contacts registered');
    }

    _isSending = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Get current location
      final locationData = await _locationService.getCurrentLocationWithUrl();

      if (kDebugMode) {
        print('📍 Location obtained: ${locationData['latitude']}, ${locationData['longitude']}');
      }

      // 2. Create SOS message
      final sosMessage = SOSMessage(
        senderId: _currentUserId!,
        senderName: senderName,
        senderPhone: senderPhone,
        location: SOSLocation(
          latitude: locationData['latitude'],
          longitude: locationData['longitude'],
          accuracy: locationData['accuracy'],
        ),
        googleMapsUrl: locationData['url'],
        message: message,
        status: 'active',
        emergencyContactIds: emergencyContactIds,
        createdAt: DateTime.now(),
      );

      if (kDebugMode) {
        print('📤 Creating SOS message:');
        print('   Sender ID: $_currentUserId');
        print('   Sender Name: $senderName');
        print('   Emergency Contact IDs: $emergencyContactIds');
      }

      // 3. Save to Firestore
      DocumentReference docRef = await _firestore
          .collection('sos_messages')
          .add(sosMessage.toMap());

      if (kDebugMode) {
        print('🚨 SOS sent successfully! ID: ${docRef.id}');
      }

      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      if (kDebugMode) {
        print('❌ Error sending SOS: $e');
      }
      rethrow;
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  /// Cancel active SOS
  Future<void> cancelSOS() async {
    if (_activeSOS == null || _activeSOS!.id == null) {
      throw Exception('No active SOS to cancel');
    }

    try {
      // Update status to 'cancelled'
      await _firestore
          .collection('sos_messages')
          .doc(_activeSOS!.id)
          .update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });

      // Cancel notification
      await _notificationService.cancelSOSNotification(_activeSOS!.id!);

      if (kDebugMode) {
        print('✅ SOS cancelled: ${_activeSOS!.id}');
      }

      _activeSOS = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to cancel SOS: $e';
      if (kDebugMode) {
        print('❌ Error cancelling SOS: $e');
      }
      rethrow;
    }
  }

  /// Resolve SOS (for receivers/emergency contacts)
  Future<void> resolveSOS(String sosId) async {
    try {
      // Update status to 'resolved'
      await _firestore
          .collection('sos_messages')
          .doc(sosId)
          .update({
        'status': 'resolved',
        'resolvedAt': FieldValue.serverTimestamp(),
        'resolvedBy': _currentUserId,
      });

      // Cancel notification for this receiver
      await _notificationService.stopSOSAlert();

      if (kDebugMode) {
        print('✅ SOS resolved: $sosId');
      }

      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to resolve SOS: $e';
      if (kDebugMode) {
        print('❌ Error resolving SOS: $e');
      }
      rethrow;
    }
  }

  /// Dismiss received SOS notification (cancel notification only)
  Future<void> dismissReceivedSOS(String sosId) async {
    try {
      await _notificationService.cancelSOSNotification(sosId);

      if (kDebugMode) {
        print('🔕 Dismissed SOS notification: $sosId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error dismissing SOS notification: $e');
      }
    }
  }

  /// Get emergency contact user IDs from contact service
  ///
  /// This method should be called from ContactProvider to get the list
  /// of emergency contact user IDs to send SOS to.
  Future<List<String>> getEmergencyContactUserIds(
    List<dynamic> emergencyContacts,
  ) async {
    List<String> userIds = [];

    try {
      // Query Firestore users collection to find users with matching email
      for (var contact in emergencyContacts) {
        final email = contact.email;

        if (email.isEmpty) {
          if (kDebugMode) {
            print('⚠️ Contact ${contact.nama} has no email');
          }
          continue;
        }

        // Query users by email (match with Firebase Auth email)
        final querySnapshot = await _firestore
            .collection('users')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final userId = querySnapshot.docs.first.id;
          userIds.add(userId);
          if (kDebugMode) {
            print('✅ Found user ID for ${contact.nama}: $userId');
          }
        } else {
          if (kDebugMode) {
            print('⚠️ No user found with email: $email');
          }
        }
      }

      // Remove current user from the list (don't send SOS to yourself)
      if (_currentUserId != null) {
        userIds.remove(_currentUserId);
      }

      if (kDebugMode) {
        print('👥 Found ${userIds.length} registered emergency contacts');
        print('📋 User IDs: $userIds');
      }

      return userIds;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting emergency contact user IDs: $e');
      }
      return [];
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _sentSOSSubscription?.cancel();
    _receivedSOSSubscription?.cancel();
    super.dispose();
  }
}