class FirebaseConstants {
  // Collections
  static const String usersCollection = 'users';
  static const String contactsCollection = 'contacts';
  static const String groupsCollection = 'groups';

  // Storage Paths
  static const String contactPhotosStoragePath = 'contact_photos';

  // --- User Model Fields ---
  // (Digunakan di user_model.dart)
  static const String uid = 'uid';
  static const String email = 'email';
  static const String displayName = 'displayName';
  // 'photoUrl' dan 'createdAt' sudah ada di Contact fields

  // --- Contact Model Fields ---
  // (Digunakan di contact_model.dart)
  static const String nama = 'nama';
  static const String nomor = 'nomor';
  // 'email'
  static const String photoUrl = 'photoUrl';
  static const String isEmergency = 'isEmergency'; // Renamed from isFavorite
  static const String userId = 'userId';
  static const String createdAt = 'createdAt';
  static const String updatedAt = 'updatedAt';
  static const String groupIds = 'groupIds';
  static const String note = 'note';

  // --- Group Model Fields ---
  // (Digunakan di group_model.dart)
  // 'nama'
  static const String colorHex = 'colorHex';
  static const String contactIds = 'contactIds';
  // 'userId'
  // 'createdAt'
  // 'updatedAt'
}
