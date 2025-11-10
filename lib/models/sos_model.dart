import 'package:cloud_firestore/cloud_firestore.dart';

/// SOS Model
///
/// Represents an emergency SOS message with location data.
/// Stored in Firestore `sos_messages` collection.
class SOSMessage {
  final String? id; // Firestore document ID
  final String senderId; // User ID who sent SOS
  final String senderName; // Sender's display name
  final String senderPhone; // Sender's phone number
  final SOSLocation location; // Location data
  final String googleMapsUrl; // Google Maps link
  final String message; // SOS message text
  final String status; // 'active' | 'cancelled'
  final List<String> emergencyContactIds; // UIDs of emergency contacts
  final DateTime createdAt; // When SOS was created
  final DateTime? cancelledAt; // When SOS was cancelled

  SOSMessage({
    this.id,
    required this.senderId,
    required this.senderName,
    required this.senderPhone,
    required this.location,
    required this.googleMapsUrl,
    required this.message,
    required this.status,
    required this.emergencyContactIds,
    required this.createdAt,
    this.cancelledAt,
  });

  /// Factory constructor untuk membuat SOS kosong
  factory SOSMessage.empty() {
    return SOSMessage(
      id: null,
      senderId: '',
      senderName: '',
      senderPhone: '',
      location: SOSLocation.empty(),
      googleMapsUrl: '',
      message: '',
      status: 'active',
      emergencyContactIds: [],
      createdAt: DateTime.now(),
      cancelledAt: null,
    );
  }

  /// Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'senderPhone': senderPhone,
      'location': location.toMap(),
      'googleMapsUrl': googleMapsUrl,
      'message': message,
      'status': status,
      'emergencyContactIds': emergencyContactIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'cancelledAt': cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
    };
  }

  /// Factory constructor dari Firestore DocumentSnapshot
  factory SOSMessage.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return SOSMessage(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderPhone: data['senderPhone'] ?? '',
      location: SOSLocation.fromMap(data['location'] ?? {}),
      googleMapsUrl: data['googleMapsUrl'] ?? '',
      message: data['message'] ?? '',
      status: data['status'] ?? 'active',
      emergencyContactIds: List<String>.from(data['emergencyContactIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      cancelledAt: (data['cancelledAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Copy with modifications
  SOSMessage copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? senderPhone,
    SOSLocation? location,
    String? googleMapsUrl,
    String? message,
    String? status,
    List<String>? emergencyContactIds,
    DateTime? createdAt,
    DateTime? cancelledAt,
  }) {
    return SOSMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderPhone: senderPhone ?? this.senderPhone,
      location: location ?? this.location,
      googleMapsUrl: googleMapsUrl ?? this.googleMapsUrl,
      message: message ?? this.message,
      status: status ?? this.status,
      emergencyContactIds: emergencyContactIds ?? this.emergencyContactIds,
      createdAt: createdAt ?? this.createdAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
    );
  }

  /// Check if SOS is active
  bool get isActive => status == 'active';

  /// Check if SOS is cancelled
  bool get isCancelled => status == 'cancelled';

  @override
  String toString() {
    return 'SOSMessage(id: $id, sender: $senderName, status: $status, location: ${location.toString()})';
  }
}

/// SOS Location data
class SOSLocation {
  final double latitude;
  final double longitude;
  final double accuracy; // in meters

  SOSLocation({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
  });

  factory SOSLocation.empty() {
    return SOSLocation(
      latitude: 0.0,
      longitude: 0.0,
      accuracy: 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
    };
  }

  factory SOSLocation.fromMap(Map<String, dynamic> map) {
    return SOSLocation(
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      accuracy: (map['accuracy'] ?? 0.0).toDouble(),
    );
  }

  @override
  String toString() {
    return '$latitude, $longitude (±${accuracy.toStringAsFixed(1)}m)';
  }
}
