import 'package:cloud_firestore/cloud_firestore.dart';

class Contact {
  final String? id; // Firestore document ID [cite: 265]
  final String nama; // Contact name (required, max 100) [cite: 265]
  final String nomor; // Phone number (required, max 20) [cite: 265]
  final String email; // Email (required, max 100) [cite: 265]
  final String? photoUrl; // Firebase Storage URL (optional) [cite: 265]
  final bool
  isEmergency; // Emergency contact status (renamed from isFavorite) [cite: 265]
  final String userId; // Owner's Firebase Auth UID [cite: 265]
  final List<String> groupIds; // List of Group IDs assigned to this contact
  final String? note; // Private note for the contact (max 500 chars)
  final DateTime createdAt; // Creation timestamp [cite: 265]
  final DateTime updatedAt; // Last update timestamp [cite: 265]

  Contact({
    this.id,
    required this.nama,
    required this.nomor,
    required this.email,
    this.photoUrl,
    required this.isEmergency,
    required this.userId,
    this.groupIds = const [],
    this.note,
    required this.createdAt,
    required this.updatedAt,
  }); // [cite: 267]

  // Factory constructor untuk membuat Contact kosong [cite: 268]
  factory Contact.empty() {
    return Contact(
      id: null,
      nama: '',
      nomor: '',
      email: '',
      photoUrl: null,
      isEmergency: false,
      userId: '',
      groupIds: [],
      note: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // Method untuk mengonversi ke Map untuk Firestore [cite: 269]
  Map<String, dynamic> toMap() {
    return {
      'nama': nama,
      'nomor': nomor,
      'email': email,
      'photoUrl': photoUrl,
      'isEmergency': isEmergency,
      'userId': userId,
      'groupIds': groupIds,
      'note': note,
      'createdAt': Timestamp.fromDate(
        createdAt,
      ), // Konversi DateTime ke Timestamp
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Factory constructor untuk membuat dari Firestore DocumentSnapshot [cite: 270]
  factory Contact.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Contact(
      id: doc.id,
      nama: data['nama'] ?? '',
      nomor: data['nomor'] ?? '',
      email: data['email'] ?? '',
      photoUrl: data['photoUrl'],
      isEmergency:
          data['isEmergency'] ??
          data['isFavorite'] ??
          false, // Support both old and new field
      userId: data['userId'] ?? '',
      groupIds: List<String>.from(data['groupIds'] ?? []),
      note: data['note'],
      // Konversi Timestamp dari Firestore ke DateTime
      createdAt: (data['createdAt'] as Timestamp? ?? Timestamp.now()).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp? ?? Timestamp.now()).toDate(),
    );
  }

  // Method untuk membuat salinan objek dengan modifikasi [cite: 271]
  Contact copyWith({
    String? id,
    String? nama,
    String? nomor,
    String? email,
    String? photoUrl,
    bool? isEmergency,
    String? userId,
    List<String>? groupIds,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Contact(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      nomor: nomor ?? this.nomor,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      isEmergency: isEmergency ?? this.isEmergency,
      userId: userId ?? this.userId,
      groupIds: groupIds ?? this.groupIds,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Override toString untuk debugging [cite: 272]
  @override
  String toString() {
    return 'Contact(id: $id, nama: $nama, nomor: $nomor, email: $email, isEmergency: $isEmergency, userId: $userId, groupIds: $groupIds, note: $note)';
  }
}
