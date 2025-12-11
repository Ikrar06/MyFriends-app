import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/group_model.dart';
import '../models/contact_model.dart';
import '../core/constants/firebase_constants.dart';
import 'firebase_service.dart';

/// Group Service
///
/// Handles all Group CRUD operations with Firestore.
/// Relationship with Contacts is now managed in Contact model (groupIds).
class GroupService {
  final FirebaseFirestore _firestore = FirebaseService.firestore;

  // Current user ID for filtering
  String? _currentUserId;

  /// Set current user ID for filtering groups
  ///
  /// Called by GroupProvider after auth state changes.
  void setUserId(String? userId) {
    _currentUserId = userId;
  }

  /// Get all groups stream for current user
  ///
  /// Returns real-time stream of groups ordered by name.
  Stream<List<Group>> getGroupsStream() {
    if (_currentUserId == null) return Stream.value([]);

    return _firestore
        .collection(FirebaseConstants.groupsCollection)
        .where(FirebaseConstants.userId, isEqualTo: _currentUserId)
        .orderBy(FirebaseConstants.nama, descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Group.fromFirestore(doc)).toList();
        });
  }

  /// Add new group
  ///
  /// Returns the document ID of the created group.
  Future<String> addGroup(Group group) async {
    if (_currentUserId == null) throw Exception('User not logged in');

    try {
      Map<String, dynamic> groupMap = group
          .copyWith(
            userId: _currentUserId,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          )
          .toMap();

      // Use server timestamp
      groupMap[FirebaseConstants.createdAt] = FieldValue.serverTimestamp();
      groupMap[FirebaseConstants.updatedAt] = FieldValue.serverTimestamp();

      DocumentReference docRef = await _firestore
          .collection(FirebaseConstants.groupsCollection)
          .add(groupMap);

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add group: $e');
    }
  }

  /// Update existing group
  Future<void> updateGroup(Group group) async {
    if (group.id == null) throw Exception('Group ID is null');

    try {
      Map<String, dynamic> groupMap = group.toMap();
      groupMap[FirebaseConstants.updatedAt] = FieldValue.serverTimestamp();

      await _firestore
          .collection(FirebaseConstants.groupsCollection)
          .doc(group.id)
          .update(groupMap);
    } catch (e) {
      throw Exception('Failed to update group: $e');
    }
  }

  /// Delete group by ID
  Future<void> deleteGroup(String id) async {
    try {
      await _firestore
          .collection(FirebaseConstants.groupsCollection)
          .doc(id)
          .delete();

      // Note: Ideally we should also remove this groupId from all contacts that have it.
      // But for simplicity/MVP, we can leave the danglig ID or handle it in the UI (filter it out).
      // If we strictly follow "clean data", we should query all contacts with this groupId and remove it.
    } catch (e) {
      throw Exception('Failed to delete group: $e');
    }
  }

  /// Get group by ID (one-time fetch)
  Future<Group?> getGroupById(String id) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(FirebaseConstants.groupsCollection)
          .doc(id)
          .get();

      if (doc.exists) {
        return Group.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get group: $e');
    }
  }

  /// Get contacts in a specific group (stream)
  ///
  /// Queries Contacts collection where 'groupIds' contains groupId.
  Stream<List<Contact>> getContactsInGroupStream(String groupId) {
    if (_currentUserId == null) return Stream.value([]);

    return _firestore
        .collection(FirebaseConstants.contactsCollection)
        .where(FirebaseConstants.userId, isEqualTo: _currentUserId)
        .where('groupIds', arrayContains: groupId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Contact.fromFirestore(doc))
              .toList();
        });
  }
}
