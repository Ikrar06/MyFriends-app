import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/contact_model.dart';
import '../services/contact_service.dart';

/// Contact Provider
///
/// Manages contact state with Provider pattern.
/// Provides real-time updates from Firestore via streams.
///
/// Usage in main.dart:
/// ```dart
/// ChangeNotifierProxyProvider<AuthProvider, ContactProvider>(
///   create: (_) => ContactProvider(),
///   update: (_, auth, previous) {
///     final provider = previous ?? ContactProvider();
///     provider.updateUserId(auth.userId);
///     return provider;
///   },
/// ),
/// ```
class ContactProvider extends ChangeNotifier {
  final ContactService _contactService = ContactService();

  // State
  List<Contact> _contacts = [];
  List<Contact> _favoriteContacts = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _currentUserId;

  // Stream subscriptions
  StreamSubscription<List<Contact>>? _contactsSubscription;
  StreamSubscription<List<Contact>>? _favoritesSubscription;

  // Getters
  List<Contact> get contacts => _contacts;
  List<Contact> get favoriteContacts => _favoriteContacts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get contactCount => _contacts.length;
  int get favoriteCount => _favoriteContacts.length;

  /// Update user ID and refresh contact streams
  ///
  /// Called automatically by ChangeNotifierProxyProvider when auth state changes.
  void updateUserId(String? userId) {
    if (_currentUserId == userId) return;

    _currentUserId = userId;

    if (userId != null) {
      _contactService.setUserId(userId);
      listenToContacts();
      listenToFavorites();
    } else {
      // User logged out, clear data
      _contacts = [];
      _favoriteContacts = [];
      _contactsSubscription?.cancel();
      _favoritesSubscription?.cancel();
      notifyListeners();
    }
  }

  /// Listen to all contacts stream
  void listenToContacts() {
    _contactsSubscription?.cancel();
    _setLoading(true);

    _contactsSubscription = _contactService.getContactsStream().listen(
      (contacts) {
        _contacts = contacts;
        _errorMessage = null;
        _setLoading(false);
      },
      onError: (error) {
        _errorMessage = error.toString();
        _setLoading(false);
      },
    );
  }

  /// Listen to favorite contacts stream
  void listenToFavorites() {
    _favoritesSubscription?.cancel();

    _favoritesSubscription = _contactService.getFavoriteContactsStream().listen(
      (favorites) {
        _favoriteContacts = favorites;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = error.toString();
        notifyListeners();
      },
    );
  }

  /// Search contacts by name
  ///
  /// Switches to search stream. Call with empty string to return to normal stream.
  void searchContacts(String query) {
    _contactsSubscription?.cancel();

    if (query.isEmpty) {
      // Return to normal contacts stream
      listenToContacts();
      return;
    }

    _setLoading(true);

    _contactsSubscription = _contactService.searchContactsStream(query).listen(
      (contacts) {
        _contacts = contacts;
        _errorMessage = null;
        _setLoading(false);
      },
      onError: (error) {
        _errorMessage = error.toString();
        _setLoading(false);
      },
    );
  }

  /// Add new contact
  Future<String> addContact(Contact contact) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final id = await _contactService.addContact(contact);
      // Stream will automatically update the list
      return id;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Update existing contact
  Future<void> updateContact(Contact contact) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _contactService.updateContact(contact);
      // Stream will automatically update the list
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete contact by ID
  Future<void> deleteContact(String id) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _contactService.deleteContact(id);
      // Stream will automatically update the list
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Toggle favorite status
  Future<void> toggleFavorite(String id, bool value) async {
    try {
      await _contactService.toggleFavorite(id, value);
      // Stream will automatically update the list
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    }
  }

  /// Refresh contacts manually
  void refresh() {
    listenToContacts();
    listenToFavorites();
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
    _contactsSubscription?.cancel();
    _favoritesSubscription?.cancel();
    super.dispose();
  }
}
