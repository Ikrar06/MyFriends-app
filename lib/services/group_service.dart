import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/group_model.dart';
import '../models/contact_model.dart';
import '../core/constants/firebase_constants.dart';
import 'firebase_service.dart';

/// Group Service
///
/// Handles all Group CRUD operations with Firestore.
/// Manages group-contact relationships using denormalized contactIds array.
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
      Map<String, dynamic> groupMap = group.copyWith(
        userId: _currentUserId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ).toMap();

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
  ///
  /// Note: contactIds in contacts remain (denormalized data, no cleanup needed)
  Future<void> deleteGroup(String id) async {
    try {
      await _firestore
          .collection(FirebaseConstants.groupsCollection)
          .doc(id)
          .delete();
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

  /// Add contact to group
  ///
  /// Uses FieldValue.arrayUnion to add contactId to contactIds array.
  Future<void> addContactToGroup(String groupId, String contactId) async {
    if (groupId.isEmpty || contactId.isEmpty) {
      throw Exception('Group ID and Contact ID cannot be empty');
    }

    try {
      await _firestore
          .collection(FirebaseConstants.groupsCollection)
          .doc(groupId)
          .update({
        FirebaseConstants.contactIds: FieldValue.arrayUnion([contactId]),
        FirebaseConstants.updatedAt: FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to add contact to group: $e');
    }
  }

  /// Remove contact from group
  ///
  /// Uses FieldValue.arrayRemove to remove contactId from contactIds array.
  Future<void> removeContactFromGroup(String groupId, String contactId) async {
    if (groupId.isEmpty || contactId.isEmpty) {
      throw Exception('Group ID and Contact ID cannot be empty');
    }

    try {
      await _firestore
          .collection(FirebaseConstants.groupsCollection)
          .doc(groupId)
          .update({
        FirebaseConstants.contactIds: FieldValue.arrayRemove([contactId]),
        FirebaseConstants.updatedAt: FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to remove contact from group: $e');
    }
  }

  /// Get contacts in a specific group (stream)
  ///
  /// Fetches all contacts whose IDs are in the group's contactIds array.
  /// Filters out null values (deleted contacts).
  Stream<List<Contact>> getContactsInGroupStream(String groupId) async* {
    try {
      // First, get the group to access contactIds
      DocumentSnapshot groupDoc = await _firestore
          .collection(FirebaseConstants.groupsCollection)
          .doc(groupId)
          .get();

      if (!groupDoc.exists) {
        yield [];
        return;
      }

      Group group = Group.fromFirestore(groupDoc);
      List<String> contactIds = group.contactIds;

      if (contactIds.isEmpty) {
        yield [];
        return;
      }

      // Fetch contacts by IDs (Firestore 'in' query supports up to 10 items)
      // If more than 10 contacts, we need to batch the queries
      List<Contact> allContacts = [];

      // Split contactIds into chunks of 10
      for (int i = 0; i < contactIds.length; i += 10) {
        int end = (i + 10 < contactIds.length) ? i + 10 : contactIds.length;
        List<String> chunk = contactIds.sublist(i, end);

        QuerySnapshot snapshot = await _firestore
            .collection(FirebaseConstants.contactsCollection)
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        List<Contact> contacts = snapshot.docs
            .map((doc) => Contact.fromFirestore(doc))
            .toList();

        allContacts.addAll(contacts);
      }

      yield allContacts;
    } catch (e) {
      throw Exception('Failed to get contacts in group: $e');
    }
  }

  /// Get groups that contain a specific contact
  ///
  /// Uses arrayContains query to find groups where contactIds array contains the contactId.
  Future<List<Group>> getGroupsByContactId(String contactId) async {
    if (_currentUserId == null) return [];

    try {
      QuerySnapshot snapshot = await _firestore
          .collection(FirebaseConstants.groupsCollection)
          .where(FirebaseConstants.userId, isEqualTo: _currentUserId)
          .where(FirebaseConstants.contactIds, arrayContains: contactId)
          .get();

      return snapshot.docs.map((doc) => Group.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to get groups by contact: $e');
    }
  }
}
