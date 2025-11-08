import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myfriends_app/models/user_model.dart';
import 'package:myfriends_app/services/firebase_service.dart';
import 'package:myfriends_app/core/constants/firebase_constants.dart';

class AuthService {
  // Mendapatkan instance dari FirebaseService
  final FirebaseAuth _auth = FirebaseService.auth;
  final FirebaseFirestore _firestore = FirebaseService.firestore;

  /// Mendapatkan stream perubahan status autentikasi
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Mendapatkan pengguna yang saat ini login
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// Mendaftarkan pengguna baru dengan email, password, dan nama
  Future<UserCredential> signUpWithEmail(
      String name, String email, String password) async {
    try {
      // 1. Buat pengguna di Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null) {
        // 2. Update profil display name di Firebase Auth
        await user.updateDisplayName(name); //
        await user.reload(); // Muat ulang data user
        user = _auth.currentUser; // Ambil data terbaru

        // 3. Buat dokumen pengguna di Firestore
        UserModel newUser = UserModel(
          uid: user!.uid,
          email: email,
          displayName: name,
          photoUrl: null,
          createdAt: DateTime.now(),
        );

        // Simpan ke koleksi 'users' dengan ID yang sama dengan UID auth
        await _firestore
            .collection(FirebaseConstants.usersCollection)
            .doc(user.uid)
            .set(newUser.toMap());
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      // Handle error spesifik dari Firebase Auth
      if (e.code == 'email-already-in-use') {
        throw Exception('Email sudah terdaftar');
      } else if (e.code == 'weak-password') {
        throw Exception('Password terlalu lemah (min 6 karakter)');
      } else if (e.code == 'invalid-email') {
        throw Exception('Format email tidak valid');
      } else {
        throw Exception('Terjadi kesalahan: ${e.message}');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan. Coba lagi nanti.');
    }
  }

  /// Login pengguna dengan email dan password
  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      // Handle error spesifik
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        throw Exception('Email atau password salah');
      } else if (e.code == 'invalid-email') {
        throw Exception('Format email tidak valid');
      } else if (e.code == 'user-disabled') {
        throw Exception('Akun ini telah dinonaktifkan');
      } else {
        throw Exception('Terjadi kesalahan: ${e.message}');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan. Coba lagi nanti.');
    }
  }

  /// Logout pengguna
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Gagal logout: $e');
    }
  }

  /// Mengirim email reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('Email tidak terdaftar');
      } else {
        throw Exception('Gagal mengirim email: ${e.message}');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan. Coba lagi nanti.');
    }
  }

  /// Update profil pengguna (di Auth dan Firestore)
  Future<void> updateUserProfile(String? displayName, String? photoUrl) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) throw Exception('Pengguna tidak login');

      // 1. Update Firebase Auth
      if (displayName != null) {
        await user.updateDisplayName(displayName);
      }
      if (photoUrl != null) {
        await user.updatePhotoURL(photoUrl);
      }

      await user.reload();
      user = _auth.currentUser;

      // 2. Update Firestore
      // Hanya update field yang berubah
      Map<String, dynamic> dataToUpdate = {};
      if (displayName != null) dataToUpdate['displayName'] = displayName;
      if (photoUrl != null) dataToUpdate['photoUrl'] = photoUrl;

      if (dataToUpdate.isNotEmpty) {
        await _firestore
            .collection(FirebaseConstants.usersCollection)
            .doc(user!.uid)
            .update(dataToUpdate);
      }
    } catch (e) {
      throw Exception('Gagal update profil: $e');
    }
  }
}