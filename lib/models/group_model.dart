import 'package:cloud_firestore/cloud_firestore.dart';

class Group {
  final String? id; // Firestore document ID
  final String nama; // Group name (required, max 50)
  final String colorHex; // Color in hex format "#FF5733"
  final List<String> contactIds; // Array of contact document IDs
  final String userId; // Owner's Firebase Auth UID
  final DateTime createdAt; // Creation timestamp
  final DateTime updatedAt; // Last update timestamp

  Group({
    this.id,
    required this.nama,
    required this.colorHex,
    required this.contactIds,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory constructor untuk membuat Group kosong
  factory Group.empty() {
    return Group(
      id: null,
      nama: '',
      colorHex: '#808080', // Default color (e.g., grey)
      contactIds: [],
      userId: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // Method untuk mengonversi ke Map untuk Firestore
  Map<String, dynamic> toMap() {
    return {
      'nama': nama,
      'colorHex': colorHex,
      'contactIds': contactIds,
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Factory constructor untuk membuat dari Firestore DocumentSnapshot
  factory Group.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Group(
      id: doc.id,
      nama: data['nama'] ?? '',
      colorHex: data['colorHex'] ?? '#808080',
      // Pastikan contactIds adalah List<String>
      contactIds: List<String>.from(data['contactIds'] ?? []),
      userId: data['userId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp? ?? Timestamp.now()).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp? ?? Timestamp.now()).toDate(),
    );
  }

  // Method untuk membuat salinan objek dengan modifikasi
  Group copyWith({
    String? id,
    String? nama,
    String? colorHex,
    List<String>? contactIds,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Group(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      colorHex: colorHex ?? this.colorHex,
      contactIds: contactIds ?? this.contactIds,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Method untuk mendapatkan jumlah kontak 
  int getContactCount() {
    return contactIds.length;
  }

  // Override toString untuk debugging [cite: 380]
  @override
  String toString() {
    return 'Group(id: $id, nama: $nama, contacts: ${getContactCount()})';
  }
}