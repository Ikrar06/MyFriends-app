import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../providers/contact_provider.dart';
import '../../providers/sos_provider.dart';
import '../../services/export_service.dart';
import '../../routes/app_routes.dart';

/// Profile Screen
///
/// Clean UI following design specifications
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _handleChangePhoto(BuildContext context) async {
    final ImagePicker picker = ImagePicker();

    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Choose Source', style: TextStyle(fontFamily: 'Poppins')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFFFE7743)),
              title: const Text('Camera', style: TextStyle(fontFamily: 'Poppins')),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFFFE7743)),
              title: const Text('Gallery', style: TextStyle(fontFamily: 'Poppins')),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source != null && context.mounted) {
      try {
        final XFile? image = await picker.pickImage(
          source: source,
          maxWidth: 512,
          maxHeight: 512,
          imageQuality: 75,
        );

        if (image != null && context.mounted) {
          final authProvider = context.read<AuthProvider>();
          await authProvider.updateProfilePhoto(File(image.path));

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile photo updated successfully', style: TextStyle(fontFamily: 'Poppins')),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update photo: $e', style: const TextStyle(fontFamily: 'Poppins')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout', style: TextStyle(fontFamily: 'Poppins')),
        content: const Text('Are you sure you want to logout?', style: TextStyle(fontFamily: 'Poppins')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(fontFamily: 'Poppins')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout', style: TextStyle(fontFamily: 'Poppins')),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final authProvider = context.read<AuthProvider>();
      try {
        await authProvider.signOut();
        if (context.mounted) {
          Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to logout: $e', style: const TextStyle(fontFamily: 'Poppins'))),
          );
        }
      }
    }
  }

  Future<void> _handleExport(BuildContext context) async {
    final contactProvider = context.read<ContactProvider>();
    final contacts = contactProvider.contacts;

    if (contacts.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No contacts to export', style: TextStyle(fontFamily: 'Poppins'))),
        );
      }
      return;
    }

    try {
      final exportService = ExportService();
      final filePath = await exportService.exportContactsToCSV(contacts);
      await exportService.shareCSVFile(filePath);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data exported successfully', style: TextStyle(fontFamily: 'Poppins')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export data: $e', style: const TextStyle(fontFamily: 'Poppins'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),

                // Title
                const Text(
                  'Profile',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 36,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                ),

                const SizedBox(height: 40),

                // Profile Header
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    final user = authProvider.currentUser;
                    final displayName = user?.displayName ?? 'User';
                    final email = user?.email ?? '';
                    final photoURL = user?.photoURL;

                    return FutureBuilder<String?>(
                      future: authProvider.getPhoneNumber(),
                      builder: (context, snapshot) {
                        final phoneNumber = snapshot.data ?? '';

                        return Column(
                          children: [
                            // Profile Photo - Centered
                            Center(
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD9D9D9),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.black, width: 2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.1),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ClipOval(
                                      child: photoURL != null && photoURL.isNotEmpty
                                          ? CachedNetworkImage(
                                              imageUrl: photoURL,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) => const Center(
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Color(0xFFFE7743),
                                                ),
                                              ),
                                              errorWidget: (context, url, error) => Center(
                                                child: Text(
                                                  displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                                                  style: const TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontSize: 48,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.black54,
                                                  ),
                                                ),
                                              ),
                                            )
                                          : Center(
                                              child: Text(
                                                displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                                                style: const TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 48,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                            ),
                                    ),
                                  ),
                                  // Edit photo button
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: GestureDetector(
                                      onTap: () => _handleChangePhoto(context),
                                      child: Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFE7743),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 3),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.2),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt,
                                          size: 18,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            // User Info - Centered
                            Center(
                              child: Column(
                                children: [
                                  Text(
                                    displayName,
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 32,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    email,
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.grey[600],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  if (phoneNumber.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      phoneNumber,
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.grey[600],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 40),

                // Menu Items
                _buildMenuItem(
                  icon: Icons.edit_outlined,
                  title: 'Edit Profile',
                  subtitle: 'Change username and phone number',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.editProfile),
                ),

                const SizedBox(height: 12),

                _buildMenuItem(
                  icon: Icons.star_outline,
                  title: 'Emergency Contacts',
                  subtitle: 'Manage your emergency contacts',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.emergencyContacts),
                ),

                const SizedBox(height: 12),

                // SOS Messages with Badge
                Consumer<SOSProvider>(
                  builder: (context, sosProvider, child) {
                    final sosCount = sosProvider.receivedSOSMessages.length;
                    return _buildMenuItem(
                      icon: Icons.sos,
                      title: 'SOS Messages',
                      subtitle: sosCount > 0
                          ? '$sosCount received SOS message${sosCount > 1 ? 's' : ''}'
                          : 'View received SOS messages',
                      onTap: () => Navigator.pushNamed(context, AppRoutes.sosList),
                      trailing: sosCount > 0
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF3B30),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$sosCount',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : null,
                    );
                  },
                ),

                const SizedBox(height: 12),

                _buildMenuItem(
                  icon: Icons.file_download_outlined,
                  title: 'Export Data',
                  subtitle: 'Export contacts to CSV',
                  onTap: () => _handleExport(context),
                ),

                const SizedBox(height: 12),

                _buildMenuItem(
                  icon: Icons.info_outline,
                  title: 'About App',
                  subtitle: 'Version information',
                  onTap: () => _showAboutDialog(context),
                ),

                const SizedBox(height: 40),

                // Logout Button
                GestureDetector(
                  onTap: () => _handleLogout(context),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEA4335),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEA4335).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'Logout',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFFE7743).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFFFE7743), size: 24),
              ),
              const SizedBox(width: 16),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              // Trailing (Badge or Arrow)
              trailing ??
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey[400],
                    size: 24,
                  ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'MyFriends',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFE7743).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.contacts, size: 40, color: Color(0xFFFE7743)),
      ),
      children: const [
        Text(
          'Aplikasi manajemen kontak dan grup dengan fitur SOS darurat untuk keamanan Anda.',
          style: TextStyle(fontFamily: 'Poppins'),
        ),
        SizedBox(height: 16),
        Text(
          '📱 Dibuat dengan Flutter + Firebase\n🔥 Realtime updates & Push notifications\n🆘 Emergency SOS system',
          style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}
