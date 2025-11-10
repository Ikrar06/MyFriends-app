import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myfriends_app/services/auth_service.dart';
import 'package:myfriends_app/services/notification_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  // Stream subscription to listen for auth changes
  StreamSubscription<User?>? _authSubscription;

  // --- Getters ---
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  String? get userId => _currentUser?.uid;
  String? get userEmail => _currentUser?.email;
  String? get displayName => _currentUser?.displayName;

  // Constructor: Start listening to auth state immediately
  AuthProvider() {
    listenToAuthState();
  }

  /// Get phone number from Firestore
  Future<String?> getPhoneNumber() async {
    if (_currentUser == null) return null;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .get();

      if (doc.exists) {
        return doc.data()?['phoneNumber'] as String?;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting phone number: $e');
      }
      return null;
    }
  }

  /// Helper to set loading state and notify UI
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Listen to auth state changes (login/logout)
  void listenToAuthState() {
    // Cancel old subscription if exists
    _authSubscription?.cancel();

    _authSubscription = _authService.authStateChanges.listen((user) async {
      _currentUser = user;
      _errorMessage = null; // Clear error when state changes

      if (kDebugMode) {
        print('Auth State Changed: ${user?.email}');
      }

      // Save FCM token when user logs in
      if (user != null) {
        try {
          await NotificationService().saveFCMToken(userId: user.uid);
        } catch (e) {
          if (kDebugMode) {
            print('Error saving FCM token on auth state change: $e');
          }
        }
      }

      // Notify all listening widgets that auth state has changed
      notifyListeners();
    });
  }

  /// Sign In
  Future<void> signIn(String email, String password) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _authService.signInWithEmail(email, password);

      // Save FCM token after successful login
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await NotificationService().saveFCMToken(userId: user.uid);
      }

      _errorMessage = null; // Success
    } catch (e) {
      _errorMessage = e.toString();
      rethrow; // Throw error so UI can handle it
    } finally {
      _setLoading(false);
    }
  }

  /// Sign Up
  Future<void> signUp(String name, String email, String password) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _authService.signUpWithEmail(name, email, password);

      // Save FCM token after successful signup
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await NotificationService().saveFCMToken(userId: user.uid);
      }

      _errorMessage = null; // Success
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign Out
  Future<void> signOut() async {
    _setLoading(true);
    try {
      // Delete FCM token before signout
      await NotificationService().deleteToken();

      await _authService.signOut();
      _currentUser = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  /// Update display name
  Future<void> updateDisplayName(String displayName) async {
    if (_currentUser == null) {
      throw Exception('User not logged in');
    }

    _setLoading(true);
    try {
      // 1. Update displayName in Firebase Auth
      await _currentUser!.updateDisplayName(displayName);
      await _currentUser!.reload();
      _currentUser = FirebaseAuth.instance.currentUser;

      // 2. Update in Firestore users collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .set({
        'displayName': displayName,
        'uid': _currentUser!.uid,
        'email': _currentUser!.email,
      }, SetOptions(merge: true));

      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to update display name: $e';
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Update phone number
  Future<void> updatePhoneNumber(String phoneNumber) async {
    if (_currentUser == null) {
      throw Exception('User not logged in');
    }

    _setLoading(true);
    try {
      // Update phone number in Firestore users collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .set({
        'phoneNumber': phoneNumber,
        'uid': _currentUser!.uid,
        'email': _currentUser!.email,
      }, SetOptions(merge: true));

      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to update phone number: $e';
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Update profile photo
  Future<void> updateProfilePhoto(File imageFile) async {
    if (_currentUser == null) {
      throw Exception('User not logged in');
    }

    _setLoading(true);
    try {
      // 1. Upload photo to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_photos')
          .child('${_currentUser!.uid}.jpg');

      final uploadTask = await storageRef.putFile(imageFile);
      final photoURL = await uploadTask.ref.getDownloadURL();

      // 2. Update photoURL in Firebase Auth
      await _currentUser!.updatePhotoURL(photoURL);
      await _currentUser!.reload();
      _currentUser = FirebaseAuth.instance.currentUser;

      // 3. Update or create photoURL in Firestore users collection
      // Use set with merge:true to create or update
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .set({
        'photoURL': photoURL,
        'uid': _currentUser!.uid,
        'email': _currentUser!.email,
        'displayName': _currentUser!.displayName,
      }, SetOptions(merge: true));

      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to update photo: $e';
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Pick image from gallery or camera
  Future<File?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      _errorMessage = 'Failed to pick photo: $e';
      rethrow;
    }
  }

  /// Clean up stream when provider is no longer used
  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}