import 'dart:io';
import 'package:flutter/foundation.dart'; // Untuk kDebugMode
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart' as share_plus;
import 'package:myfriends_app/models/contact_model.dart';

class ExportService {
  /// Mengekspor daftar kontak ke file CSV.
  /// Mengembalikan path file yang dibuat.
  Future<String> exportContactsToCSV(List<Contact> contacts) async {
    try {
      // 1. Membuat data CSV
      // Menambahkan header
      List<List<dynamic>> rows = [
        ["Nama", "Nomor", "Email", "Favorit"] // Header
      ];

      // Menambahkan data kontak
      for (var contact in contacts) {
        rows.add([
          contact.nama,
          contact.nomor,
          contact.email,
          contact.isEmergency ? "Ya" : "Tidak" // Format boolean
        ]);
      }

      // 2. Mengonversi data list menjadi string CSV
      String csvString = const ListToCsvConverter().convert(rows);

      // 3. Mendapatkan direktori untuk menyimpan file
      final directory = await getApplicationDocumentsDirectory();
      final path = directory.path;

      // 4. Membuat nama file unik
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final fileName = 'contacts_export_$timestamp.csv';
      final filePath = '$path/$fileName';

      // 5. Menulis string CSV ke file
      final file = File(filePath);
      await file.writeAsString(csvString);

      if (kDebugMode) {
        print('✅ CSV file created at: $filePath');
      }

      // 6. Mengembalikan path file
      return filePath;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error exporting to CSV: $e');
      }
      throw Exception('Gagal mengekspor data: $e');
    }
  }

  /// Membagikan file CSV menggunakan share dialog sistem
  Future<void> shareCSVFile(String filePath) async {
    try {
      // 1. Cek apakah file ada
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File tidak ditemukan');
      }

      // 2. Membagikan file menggunakan SharePlus.instance.share()
      final result = await share_plus.SharePlus.instance.share(
        share_plus.ShareParams(
          files: [share_plus.XFile(filePath)],
          text: 'Ini adalah data kontak MyFriends Anda',
        ),
      );

      if (kDebugMode) {
        print('✅ Share result: ${result.status}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error sharing file: $e');
      }
      throw Exception('Gagal membagikan file: $e');
    }
  }
}