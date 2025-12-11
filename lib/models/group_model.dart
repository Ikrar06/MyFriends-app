import 'package:cloud_firestore/cloud_firestore.dart';

class Group {
  final String? id; // Firestore document ID
  final String nama; // Group name (required, max 50)
  final String colorHex; // Color in hex format "#FF5733"
  final String userId; // Owner's Firebase Auth UID
  final DateTime createdAt; // Creation timestamp
  final DateTime updatedAt; // Last update timestamp

  Group({
    this.id,
    required this.nama,
    required this.colorHex,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory constructor untuk membuat Group kosong
  factory Group.empty() {
    return Group(
      id: null,
      nama: '',
      colorHex: '#2196F3', // Default color (Blue)
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
      colorHex: data['colorHex'] ?? '#2196F3',
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
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Group(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      colorHex: colorHex ?? this.colorHex,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Override toString untuk debugging [cite: 380]
  @override
  String toString() {
    return 'Group(id: $id, nama: $nama, color: $colorHex)';
  }
}
