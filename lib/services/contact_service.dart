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

  // Store the currently logged in user ID
  String? _currentUserId;

  /// Set the current user ID.
  /// This is IMPORTANT to filter contact data only for the logged in user.
  void setUserId(String? userId) {
    _currentUserId = userId;
  }

  /// Get stream (real-time) of all contacts belonging to user
  Stream<List<Contact>> getContactsStream() {
    if (_currentUserId == null)
      return Stream.value([]); // Return empty list if user is null

    return _firestore
        .collection(FirebaseConstants.contactsCollection)
        .where(FirebaseConstants.userId, isEqualTo: _currentUserId)
        .orderBy(FirebaseConstants.createdAt, descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Contact.fromFirestore(doc))
              .toList();
        });
  }

  /// Get stream (real-time) of emergency contacts belonging to user
  Stream<List<Contact>> getEmergencyContactsStream() {
    if (_currentUserId == null) return Stream.value([]);

    return _firestore
        .collection(FirebaseConstants.contactsCollection)
        .where(FirebaseConstants.userId, isEqualTo: _currentUserId)
        .where(FirebaseConstants.isEmergency, isEqualTo: true)
        .orderBy(FirebaseConstants.createdAt, descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Contact.fromFirestore(doc))
              .toList();
        });
  }

  /// Search contacts by name (case-sensitive)
  Stream<List<Contact>> searchContactsStream(String query) {
    if (_currentUserId == null) return Stream.value([]);

    // Query Firestore for 'starts-with'
    return _firestore
        .collection(FirebaseConstants.contactsCollection)
        .where(FirebaseConstants.userId, isEqualTo: _currentUserId)
        .where(FirebaseConstants.nama, isGreaterThanOrEqualTo: query)
        .where(FirebaseConstants.nama, isLessThan: '$query\uf8ff')
        .orderBy(FirebaseConstants.nama)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Contact.fromFirestore(doc))
              .toList();
        });
  }

  /// Add new contact
  Future<String> addContact(Contact contact) async {
    if (_currentUserId == null) throw Exception('User not logged in');

    try {
      // Add timestamp data and userId
      Map<String, dynamic> contactMap = contact
          .copyWith(
            userId: _currentUserId,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          )
          .toMap();

      // Use FieldValue.serverTimestamp()
      contactMap['createdAt'] = FieldValue.serverTimestamp();
      contactMap['updatedAt'] = FieldValue.serverTimestamp();

      DocumentReference docRef = await _firestore
          .collection(FirebaseConstants.contactsCollection)
          .add(contactMap);
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add contact: $e');
    }
  }

  /// Update existing contact
  Future<void> updateContact(Contact contact) async {
    if (contact.id == null) throw Exception('Invalid contact ID');

    try {
      Map<String, dynamic> contactMap = contact.toMap();
      // Only update updatedAt
      contactMap['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore
          .collection(FirebaseConstants.contactsCollection)
          .doc(contact.id)
          .update(contactMap);
    } catch (e) {
      throw Exception('Failed to update contact: $e');
    }
  }

  /// Toggle emergency status of contact
  Future<void> toggleEmergency(String id, bool newValue) async {
    try {
      await _firestore
          .collection(FirebaseConstants.contactsCollection)
          .doc(id)
          .update({
            FirebaseConstants.isEmergency: newValue,
            FirebaseConstants.updatedAt: FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Failed to change emergency status: $e');
    }
  }

  /// Upload contact photo to Firebase Storage
  Future<String> uploadContactPhoto(File imageFile, String contactId) async {
    if (_currentUserId == null) throw Exception('User not logged in');

    try {
      // 1. Validate size (according to guidelines < 5MB)
      if (imageFile.lengthSync() > 5 * 1024 * 1024) {
        throw Exception('File size too large (Max 5MB)');
      }

      // 2. Generate unique filename
      String fileName =
          'contact_${contactId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // 3. Define path in Storage
      Reference storageRef = _storage
          .ref()
          .child(FirebaseConstants.contactPhotosStoragePath)
          .child(_currentUserId!)
          .child(fileName);

      // 4. Upload file
      UploadTask uploadTask = storageRef.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;

      // 5. Get download URL
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload photo: $e');
    }
  }

  /// Delete contact photo from Storage
  Future<void> deleteContactPhoto(String photoUrl) async {
    try {
      // Get reference from URL
      Reference photoRef = _storage.refFromURL(photoUrl);
      await photoRef.delete();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to delete photo: $e. May already be deleted.');
      }
    }
  }

  /// Delete contact
  Future<void> deleteContact(String id) async {
    try {
      // Delete photo in Storage if exists
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

      // Delete document
      await _firestore
          .collection(FirebaseConstants.contactsCollection)
          .doc(id)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete contact: $e');
    }
  }

  /// Add contact to a group (update groupIds)
  Future<void> addContactToGroup(String contactId, String groupId) async {
    try {
      await _firestore
          .collection(FirebaseConstants.contactsCollection)
          .doc(contactId)
          .update({
            'groupIds': FieldValue.arrayUnion([groupId]),
            FirebaseConstants.updatedAt: FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Failed to add contact to group: $e');
    }
  }

  /// Remove contact from a group
  Future<void> removeContactFromGroup(String contactId, String groupId) async {
    try {
      await _firestore
          .collection(FirebaseConstants.contactsCollection)
          .doc(contactId)
          .update({
            'groupIds': FieldValue.arrayRemove([groupId]),
            FirebaseConstants.updatedAt: FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Failed to remove contact from group: $e');
    }
  }
}
