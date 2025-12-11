import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/group_model.dart';
import '../models/contact_model.dart';
import '../services/group_service.dart';
import '../services/contact_service.dart';

class GroupProvider with ChangeNotifier {
  final GroupService _groupService = GroupService();

  List<Group> _groups = [];
  List<Group> get groups => _groups;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // Stream subscription
  StreamSubscription<List<Group>>? _groupsStreamSubscription;

  /// Set user ID and subscribe to groups stream
  void setUserId(String? userId) {
    _groupService.setUserId(userId);
    if (userId != null) {
      _subscribeToGroups();
    } else {
      _groups = [];
      _groupsStreamSubscription?.cancel();
      notifyListeners();
    }
  }

  void _subscribeToGroups() {
    _groupsStreamSubscription?.cancel();
    _groupsStreamSubscription = _groupService.getGroupsStream().listen(
      (groupsData) {
        _groups = groupsData;
        notifyListeners();
      },
      onError: (e) {
        if (kDebugMode) {
          print("Error listening to groups: $e");
        }
        _error = e.toString();
        notifyListeners();
      },
    );
  }

  /// Add new group
  Future<void> addGroup(String name, String colorHex) async {
    _setLoading(true);
    try {
      Group newGroup = Group(
        nama: name,
        colorHex: colorHex,
        userId: '', // Will be set in Service
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _groupService.addGroup(newGroup);
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Update existing group
  Future<void> updateGroup(Group group) async {
    _setLoading(true);
    try {
      await _groupService.updateGroup(group);
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete group
  Future<void> deleteGroup(String groupId) async {
    _setLoading(true);
    try {
      await _groupService.deleteGroup(groupId);
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Get specific group by ID (from local list)
  List<Contact> _contactsInGroup = [];
  List<Contact> get contactsInGroup => _contactsInGroup;
  StreamSubscription<List<Contact>>? _contactsStreamSubscription;
  final ContactService _contactService = ContactService();

  // Alias for legacy support
  void updateUserId(String? userId) => setUserId(userId);

  // ... existing setUserId and _subscribeToGroups ...

  /// Load contacts for a specific group (Real-time)
  void loadContactsInGroup(String groupId) {
    _contactsStreamSubscription?.cancel();
    _setLoading(true);
    _contactsStreamSubscription = _groupService
        .getContactsInGroupStream(groupId)
        .listen(
          (contacts) {
            _contactsInGroup = contacts;
            _isLoading = false;
            notifyListeners();
          },
          onError: (e) {
            _error = e.toString();
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  /// Add contact to group (Update Contact's groupIds)
  Future<void> addContactToGroup(String groupId, String contactId) async {
    try {
      // 1. Get the contact (we need current groupIds)
      // Since we don't have a direct "getContact" in ContactService exposed here easily without a stream,
      // we might need to fetch it.
      // Ideally, the UI passes the Contact object. But the method signature is (groupId, contactId).
      // Let's assume (for this fix) we can fetch it or we change the signature.
      // But to match legacy call `addContactToGroup(groupId, contactId)`, we stick to IDs.
      // We will need a way to fetch a single contact in ContactService or use Firestore directly.
      // For now, let's use a quick fetch via Firestore in GroupService or ContactService if available.
      // Wait, ContactService doesn't have getContactById.
      // Let's rely on the fact that if we are adding, we probably have the Contact object in the UI.
      // But the interface is IDs.
      // Simple fix: fetch doc directly here or add getContact to ContactService.
      // Let's just do a direct update on the contact document to add to array.

      await _contactService.addContactToGroup(contactId, groupId);
    } catch (e) {
      rethrow;
    }
  }

  /// Remove contact from group
  Future<void> removeContactFromGroup(String groupId, String contactId) async {
    try {
      await _contactService.removeContactFromGroup(contactId, groupId);
    } catch (e) {
      rethrow;
    }
  }

  // ... other methods ...

  // ... existing Contact methods ...

  /// Get specific group by ID (from local list)
  Group? getGroupById(String? id) {
    if (id == null) return null;
    try {
      return _groups.firstWhere((g) => g.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get list of groups from a list of IDs (helper for UI)
  List<Group> getGroupsByIds(List<String> ids) {
    return _groups.where((g) => g.id != null && ids.contains(g.id)).toList();
  }

  /// Get groups for a specific contact (helper, though UI can just use getGroupsByIds(contact.groupIds))
  List<Group> getGroupsForContactIds(List<String> groupIds) {
    return getGroupsByIds(groupIds);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _groupsStreamSubscription?.cancel();
    _contactsStreamSubscription?.cancel();
    super.dispose();
  }
}
