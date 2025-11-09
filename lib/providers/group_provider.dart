import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/group_model.dart';
import '../models/contact_model.dart';
import '../services/group_service.dart';

/// Group Provider
///
/// Manages group state with Provider pattern.
/// Provides real-time updates from Firestore via streams.
///
/// Usage in main.dart:
/// ```dart
/// ChangeNotifierProxyProvider<AuthProvider, GroupProvider>(
///   create: (_) => GroupProvider(),
///   update: (_, auth, previous) {
///     final provider = previous ?? GroupProvider();
///     provider.updateUserId(auth.userId);
///     return provider;
///   },
/// ),
/// ```
class GroupProvider extends ChangeNotifier {
  final GroupService _groupService = GroupService();

  // State
  List<Group> _groups = [];
  List<Contact> _contactsInGroup = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _currentUserId;

  // Stream subscriptions
  StreamSubscription<List<Group>>? _groupsSubscription;

  // Getters
  List<Group> get groups => _groups;
  List<Contact> get contactsInGroup => _contactsInGroup;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get groupCount => _groups.length;

  /// Update user ID and refresh group streams
  ///
  /// Called automatically by ChangeNotifierProxyProvider when auth state changes.
  void updateUserId(String? userId) {
    if (_currentUserId == userId) return;

    _currentUserId = userId;

    if (userId != null) {
      _groupService.setUserId(userId);
      listenToGroups();
    } else {
      // User logged out, clear data
      _groups = [];
      _contactsInGroup = [];
      _groupsSubscription?.cancel();
      notifyListeners();
    }
  }

  /// Listen to all groups stream
  void listenToGroups() {
    _groupsSubscription?.cancel();
    _setLoading(true);

    _groupsSubscription = _groupService.getGroupsStream().listen(
      (groups) {
        _groups = groups;
        _errorMessage = null;
        _setLoading(false);
      },
      onError: (error) {
        _errorMessage = error.toString();
        _setLoading(false);
      },
    );
  }

  /// Add new group
  Future<String> addGroup(Group group) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final id = await _groupService.addGroup(group);
      // Stream will automatically update the list
      return id;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Update existing group
  Future<void> updateGroup(Group group) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _groupService.updateGroup(group);
      // Stream will automatically update the list
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete group by ID
  Future<void> deleteGroup(String id) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _groupService.deleteGroup(id);
      // Stream will automatically update the list
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Load contacts in a specific group
  ///
  /// This is not a stream, but a one-time fetch.
  /// Use this when viewing group details.
  Future<void> loadContactsInGroup(String groupId) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final stream = _groupService.getContactsInGroupStream(groupId);
      final contacts = await stream.first;
      _contactsInGroup = contacts;
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      rethrow;
    }
  }

  /// Add contact to group
  Future<void> addContactToGroup(String groupId, String contactId) async {
    _errorMessage = null;

    try {
      await _groupService.addContactToGroup(groupId, contactId);
      // Reload contacts in group
      await loadContactsInGroup(groupId);
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    }
  }

  /// Remove contact from group
  Future<void> removeContactFromGroup(String groupId, String contactId) async {
    _errorMessage = null;

    try {
      await _groupService.removeContactFromGroup(groupId, contactId);
      // Reload contacts in group
      await loadContactsInGroup(groupId);
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    }
  }

  /// Get groups that contain a specific contact
  Future<List<Group>> getGroupsByContactId(String contactId) async {
    try {
      return await _groupService.getGroupsByContactId(contactId);
    } catch (e) {
      _errorMessage = e.toString();
      return [];
    }
  }

  /// Refresh groups manually
  void refresh() {
    listenToGroups();
  }

  /// Set loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _groupsSubscription?.cancel();
    super.dispose();
  }
}
