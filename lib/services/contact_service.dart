import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:myfriends_app/models/contact_model.dart';
import 'package:myfriends_app/services/firebase_service.dart';
import 'package:myfriends_app/core/constants/firebase_constants.dart';
import 'package:flutter/foundation.dart';

class ContactService {
  final FirebaseFirestore _firestore = FirebaseService.firestore;
  final FirebaseStorage _storage = FirebaseService.storage;

  // Menyimpan ID pengguna yang sedang login
  String? _currentUserId;

  /// Mengatur ID pengguna saat ini.
  /// Ini PENTING untuk memfilter data kontak hanya milik pengguna yang login.
  void setUserId(String? userId) {
    _currentUserId = userId;
  }

  /// Mendapatkan stream (real-time) semua kontak milik pengguna
  Stream<List<Contact>> getContactsStream() {
    if (_currentUserId == null) return Stream.value([]); // Kembalikan list kosong jika user null

    return _firestore
        .collection(FirebaseConstants.contactsCollection)
        .where(FirebaseConstants.userId, isEqualTo: _currentUserId)
        .orderBy(FirebaseConstants.createdAt, descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Contact.fromFirestore(doc)).toList();
    });
  }

  /// Mendapatkan stream (real-time) kontak favorit milik pengguna
  Stream<List<Contact>> getFavoriteContactsStream() {
    if (_currentUserId == null) return Stream.value([]);

    return _firestore
        .collection(FirebaseConstants.contactsCollection)
        .where(FirebaseConstants.userId, isEqualTo: _currentUserId)
        .where(FirebaseConstants.isFavorite, isEqualTo: true)
        .orderBy(FirebaseConstants.createdAt, descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Contact.fromFirestore(doc)).toList();
    });
  }

  /// Mencari kontak berdasarkan nama (case-sensitive)
  Stream<List<Contact>> searchContactsStream(String query) {
    if (_currentUserId == null) return Stream.value([]);

    // Query Firestore untuk 'starts-with'
    return _firestore
        .collection(FirebaseConstants.contactsCollection)
        .where(FirebaseConstants.userId, isEqualTo: _currentUserId)
        .where(FirebaseConstants.nama, isGreaterThanOrEqualTo: query)
        .where(FirebaseConstants.nama, isLessThan: query + '\uf8ff')
        .orderBy(FirebaseConstants.nama)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Contact.fromFirestore(doc)).toList();
    });
  }

  /// Menambah kontak baru
  Future<String> addContact(Contact contact) async {
    if (_currentUserId == null) throw Exception('Pengguna tidak login');

    try {
      // Menambahkan data timestamps dan userId
      Map<String, dynamic> contactMap = contact.copyWith(
        userId: _currentUserId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ).toMap();

      // Menggunakan FieldValue.serverTimestamp()
      contactMap['createdAt'] = FieldValue.serverTimestamp();
      contactMap['updatedAt'] = FieldValue.serverTimestamp();

      DocumentReference docRef = await _firestore
          .collection(FirebaseConstants.contactsCollection)
          .add(contactMap);
      return docRef.id;
    } catch (e) {
      throw Exception('Gagal menambah kontak: $e');
    }
  }

  /// Mengupdate kontak yang ada
  Future<void> updateContact(Contact contact) async {
    if (contact.id == null) throw Exception('ID kontak tidak valid');

    try {
      Map<String, dynamic> contactMap = contact.toMap();
      // Hanya update updatedAt
      contactMap['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore
          .collection(FirebaseConstants.contactsCollection)
          .doc(contact.id)
          .update(contactMap);
    } catch (e) {
      throw Exception('Gagal mengupdate kontak: $e');
    }
  }

  /// Mengganti status favorit kontak
  Future<void> toggleFavorite(String id, bool newValue) async {
    try {
      await _firestore
          .collection(FirebaseConstants.contactsCollection)
          .doc(id)
          .update({
        FirebaseConstants.isFavorite: newValue,
        FirebaseConstants.updatedAt: FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Gagal mengubah favorit: $e');
    }
  }

  /// Mengupload foto kontak ke Firebase Storage
  Future<String> uploadContactPhoto(File imageFile, String contactId) async {
    if (_currentUserId == null) throw Exception('Pengguna tidak login');

    try {
      // 1. Validasi ukuran (sesuai panduan < 5MB)
      if (imageFile.lengthSync() > 5 * 1024 * 1024) {
        throw Exception('Ukuran file terlalu besar (Max 5MB)');
      }

      // 2. Generate filename unik
      String fileName =
          'contact_${contactId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // 3. Tentukan path di Storage
      Reference storageRef = _storage
          .ref()
          .child(FirebaseConstants.contactPhotosStoragePath)
          .child(_currentUserId!)
          .child(fileName);

      // 4. Upload file
      UploadTask uploadTask = storageRef.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;

      // 5. Dapatkan URL download
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Gagal mengupload foto: $e');
    }
  }

  /// Menghapus foto kontak dari Storage
  Future<void> deleteContactPhoto(String photoUrl) async {
    try {
      // Dapatkan referensi dari URL
      Reference photoRef = _storage.refFromURL(photoUrl);
      await photoRef.delete();
    } catch (e) {
      if (kDebugMode) {
        print('Gagal menghapus foto: $e. Mungkin sudah terhapus.');
      }
    }
  }

  /// Menghapus kontak
  Future<void> deleteContact(String id) async {
    try {
      // delete foto di Storage jika ada
      DocumentSnapshot doc = await _firestore
          .collection(FirebaseConstants.contactsCollection)
          .doc(id)
          .get();
      
      if (doc.exists) {
        Contact contact = Contact.fromFirestore(doc);
        if (contact.photoUrl != null && contact.photoUrl!.isNotEmpty) {
          await deleteContactPhoto(contact.photoUrl!);
        }
      }

      // delete dokumen
      await _firestore
          .collection(FirebaseConstants.contactsCollection)
          .doc(id)
          .delete();
    } catch (e) {
      throw Exception('Gagal menghapus kontak: $e');
    }
  }
}