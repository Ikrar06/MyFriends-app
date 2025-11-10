import 'dart:io';
import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart' as share_plus;
import 'package:myfriends_app/models/contact_model.dart';

class ExportService {
  /// Export contact list to CSV file.
  /// Returns the path of the created file.
  Future<String> exportContactsToCSV(List<Contact> contacts) async {
    try {
      // 1. Create CSV data
      // Add header
      List<List<dynamic>> rows = [
        ["Name", "Phone", "Email", "Favorite"] // Header
      ];

      // Add contact data
      for (var contact in contacts) {
        rows.add([
          contact.nama,
          contact.nomor,
          contact.email,
          contact.isEmergency ? "Yes" : "No" // Format boolean
        ]);
      }

      // 2. Convert data list to CSV string
      String csvString = const ListToCsvConverter().convert(rows);

      // 3. Get directory to save file
      final directory = await getApplicationDocumentsDirectory();
      final path = directory.path;

      // 4. Create unique filename
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final fileName = 'contacts_export_$timestamp.csv';
      final filePath = '$path/$fileName';

      // 5. Write CSV string to file
      final file = File(filePath);
      await file.writeAsString(csvString);

      if (kDebugMode) {
        print('✅ CSV file created at: $filePath');
      }

      // 6. Return file path
      return filePath;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error exporting to CSV: $e');
      }
      throw Exception('Failed to export data: $e');
    }
  }

  /// Share CSV file using system share dialog
  Future<void> shareCSVFile(String filePath) async {
    try {
      // 1. Check if file exists
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File not found');
      }

      // 2. Share file using SharePlus.instance.share()
      final result = await share_plus.SharePlus.instance.share(
        share_plus.ShareParams(
          files: [share_plus.XFile(filePath)],
          text: 'This is your MyFriends contact data',
        ),
      );

      if (kDebugMode) {
        print('✅ Share result: ${result.status}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error sharing file: $e');
      }
      throw Exception('Failed to share file: $e');
    }
  }
}