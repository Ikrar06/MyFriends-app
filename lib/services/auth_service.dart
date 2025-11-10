import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myfriends_app/models/user_model.dart';
import 'package:myfriends_app/services/firebase_service.dart';
import 'package:myfriends_app/core/constants/firebase_constants.dart';

class AuthService {
  // Get instance from FirebaseService
  final FirebaseAuth _auth = FirebaseService.auth;
  final FirebaseFirestore _firestore = FirebaseService.firestore;

  /// Get authentication status change stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Get currently logged in user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// Register new user with email, password, and name
  Future<UserCredential> signUpWithEmail(
      String name, String email, String password) async {
    try {
      // 1. Create user in Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null) {
        // 2. Update display name profile in Firebase Auth
        await user.updateDisplayName(name);
        await user.reload(); // Reload user data
        user = _auth.currentUser; // Get latest data

        // 3. Create user document in Firestore
        UserModel newUser = UserModel(
          uid: user!.uid,
          email: email,
          displayName: name,
          photoUrl: null,
          createdAt: DateTime.now(),
        );

        // Save to 'users' collection with ID same as auth UID
        await _firestore
            .collection(FirebaseConstants.usersCollection)
            .doc(user.uid)
            .set(newUser.toMap());
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase Auth errors
      if (e.code == 'email-already-in-use') {
        throw Exception('Email already registered');
      } else if (e.code == 'weak-password') {
        throw Exception('Password too weak (min 6 characters)');
      } else if (e.code == 'invalid-email') {
        throw Exception('Invalid email format');
      } else {
        throw Exception('An error occurred: ${e.message}');
      }
    } catch (e) {
      throw Exception('An error occurred. Please try again later.');
    }
  }

  /// Login user with email and password
  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      // Handle specific errors
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        throw Exception('Incorrect email or password');
      } else if (e.code == 'invalid-email') {
        throw Exception('Invalid email format');
      } else if (e.code == 'user-disabled') {
        throw Exception('This account has been disabled');
      } else {
        throw Exception('An error occurred: ${e.message}');
      }
    } catch (e) {
      throw Exception('An error occurred. Please try again later.');
    }
  }

  /// Logout user
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Failed to logout: $e');
    }
  }

  /// Send password reset email
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('Email not registered');
      } else {
        throw Exception('Failed to send email: ${e.message}');
      }
    } catch (e) {
      throw Exception('An error occurred. Please try again later.');
    }
  }

  /// Update user profile (in Auth and Firestore)
  Future<void> updateUserProfile(String? displayName, String? photoUrl) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

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
      // Only update changed fields
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
      throw Exception('Failed to update profile: $e');
    }
  }
}