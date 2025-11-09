import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myfriends_app/services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  // Stream subscription untuk mendengarkan perubahan auth
  StreamSubscription<User?>? _authSubscription;

  // --- Getters ---
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  String? get userId => _currentUser?.uid;
  String? get userEmail => _currentUser?.email;
  String? get displayName => _currentUser?.displayName;

  // Constructor: Langsung mulai mendengarkan status auth
  AuthProvider() {
    listenToAuthState();
  }

  /// Helper untuk mengatur loading state dan memberi tahu UI
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Mendengarkan perubahan status auth (login/logout)
  void listenToAuthState() {
    // Batalkan subscription lama jika ada
    _authSubscription?.cancel();
    
    _authSubscription = _authService.authStateChanges.listen((user) {
      _currentUser = user;
      _errorMessage = null; // Hapus error saat status berubah
      
      if (kDebugMode) {
        print('Auth State Changed: ${user?.email}');
      }
      
      // Beri tahu semua widget yang mendengarkan bahwa status auth berubah
      notifyListeners();
    });
  }

  /// Sign In
  Future<void> signIn(String email, String password) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _authService.signInWithEmail(email, password);
      _errorMessage = null; // Sukses
    } catch (e) {
      _errorMessage = e.toString();
      rethrow; // Lempar error agar UI bisa menangkapnya
    } finally {
      _setLoading(false);
    }
  }

  /// Sign Up
  Future<void> signUp(String name, String email, String password) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _authService.signUpWithEmail(name, email, password);
      _errorMessage = null; // Sukses
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign Out
  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _authService.signOut();
      _currentUser = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  /// Membersihkan stream saat provider tidak lagi digunakan
  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}