import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
// Ganti 'myfriends_app' dengan nama paket Anda jika berbeda
import 'package:myfriends_app/firebase_options.dart'; 

class FirebaseService {
  // Membuat private constructor
  FirebaseService._internal();

  // Instance static untuk Singleton pattern
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;

  // Getters untuk akses instance Firebase
  static FirebaseAuth get auth => FirebaseAuth.instance;
  static FirebaseFirestore get firestore => FirebaseFirestore.instance;
  static FirebaseStorage get storage => FirebaseStorage.instance;

  // Method inisialisasi
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Konfigurasi tambahan (opsional, sesuai panduan)
      firestore.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      
      if (kDebugMode) {
        print("berhasil inisialisasi firebase service");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error inisialisasi firebase service $e");
      }
    }
  }
}