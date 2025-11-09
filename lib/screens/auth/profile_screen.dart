import 'package:flutter/material.dart';
import 'package:myfriends_app/providers/auth_provider.dart';
import 'package:myfriends_app/routes/app_routes.dart';
import 'package:provider/provider.dart';
// TODO: Import ContactProvider dan ExportService saat sudah siap
// import 'package:myfriends_app/providers/contact_provider.dart';
// import 'package:myfriends_app/services/export_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // Helper untuk menampilkan Snackbar
  void _showSnackbar(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Helper untuk mendapatkan inisial nama
  String _getInitials(String? displayName) {
    if (displayName == null || displayName.isEmpty) return '?';
    List<String> names = displayName.trim().split(' ');
    if (names.length > 1) {
      return '${names.first[0]}${names.last[0]}'.toUpperCase();
    }
    return names.first[0].toUpperCase();
  }

  // Logika _handleLogout
  Future<void> _handleLogout(BuildContext context) async {
    // 1. Tampilkan dialog konfirmasi
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Yakin ingin logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    // 2. Jika dikonfirmasi, panggil provider
    if (confirmed == true) {
      if (!context.mounted) return;
      final authProvider = context.read<AuthProvider>();
      try {
        await authProvider.signOut();
        // Navigasi ke login
        if (context.mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.login,
            (route) => false, // Hapus semua rute sebelumnya
          );
        }
      } catch (e) {
        if (context.mounted) {
          _showSnackbar(context, 'Gagal logout: $e');
        }
      }
    }
  }

  // Logika _handleExport
  Future<void> _handleExport(BuildContext context) async {
    // TODO: Implementasi ini setelah ContactProvider dibuat
    _showSnackbar(context, 'Fitur Export akan segera diimplementasi');
    
    // --- Kode Sebenarnya Sesuai Panduan (jika sudah siap) ---
    // final contacts = context.read<ContactProvider>().contacts;
    // try {
    //   final filePath = await ExportService().exportContactsToCSV(contacts);
    //   await ExportService().shareCSVFile(filePath);
    // } catch (e) {
    //   _showSnackbar(context, 'Gagal mengekspor data: $e');
    // }
  }

  // Logika _showAboutDialog
  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AboutDialog(
        applicationName: 'MyFriends App',
        applicationVersion: '1.0.0',
        applicationIcon: const Icon(Icons.people_alt),
        children: const [
          Text('Aplikasi manajemen kontak untuk Tugas Akhir Pemrograman Mobile.'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Gunakan Consumer untuk mendapatkan data AuthProvider
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Scaffold(
          // AppBar disatukan di HomeScreen oleh Orang 2
          // jadi kita tidak perlu AppBar di sini.
          body: SingleChildScrollView(
            child: Column(
              children: [
                // 1. Header Profil (sesuai panduan)
                Container(
                  width: double.infinity,
                  height: 200,
                  color: Theme.of(context).primaryColor,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white,
                          // TODO: Ganti dengan photoUrl jika sudah ada
                          // child: authProvider.currentUser?.photoURL != null
                          //     ? ClipOval(...)
                          //     : Text(...)
                          child: Text(
                            _getInitials(authProvider.displayName),
                            style: TextStyle(
                              fontSize: 40,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          authProvider.displayName ?? 'Nama Pengguna',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          authProvider.userEmail ?? 'email@example.com',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Opsi Menu (sesuai panduan)
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    leading: const Icon(Icons.file_download),
                    title: const Text('Export Data'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _handleExport(context),
                  ),
                ),
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('About App'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showAboutDialog(context),
                  ),
                ),
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  color: Colors.red[50], // Warna merah untuk logout
                  child: ListTile(
                    leading: Icon(Icons.logout, color: Colors.red[700]),
                    title: Text(
                      'Logout',
                      style: TextStyle(color: Colors.red[700]),
                    ),
                    onTap: () => _handleLogout(context),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}