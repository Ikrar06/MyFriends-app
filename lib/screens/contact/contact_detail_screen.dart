import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/contact_model.dart';
import '../../providers/contact_provider.dart';
import '../../routes/app_routes.dart';

/// Contact Detail Screen
///
/// Displays detailed contact information with action buttons.
/// Allows calling, messaging, emailing, and editing contact.
class ContactDetailScreen extends StatelessWidget {
  final Contact contact;

  const ContactDetailScreen({
    super.key,
    required this.contact,
  });

  Future<void> _makePhoneCall(String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _sendSMS(String phoneNumber) async {
    final uri = Uri(scheme: 'sms', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _sendEmail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label disalin ke clipboard'),
        backgroundColor: const Color(0xFFFE7743),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _toggleFavorite(BuildContext context) {
    final contactProvider = Provider.of<ContactProvider>(context, listen: false);
    contactProvider.toggleFavorite(contact.id!, !contact.isFavorite);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          contact.isFavorite
              ? 'Dihapus dari favorit'
              : 'Ditambahkan ke favorit',
        ),
        backgroundColor: const Color(0xFFFE7743),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _navigateToEdit(BuildContext context) {
    Navigator.pushNamed(
      context,
      AppRoutes.editContact,
      arguments: contact,
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length > 1 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: const Color(0xFFFE7743),
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                icon: Icon(
                  contact.isFavorite ? Icons.star : Icons.star_border,
                  color: Colors.white,
                ),
                onPressed: () => _toggleFavorite(context),
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () => _navigateToEdit(context),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFFE7743),
                      Color(0xFFFF9068),
                    ],
                  ),
                ),
                child: Center(
                  child: Hero(
                    tag: 'contact_${contact.id}',
                    child: CircleAvatar(
                      radius: 70,
                      backgroundColor: Colors.white.withValues(alpha: 0.3),
                      backgroundImage: contact.photoUrl != null &&
                              contact.photoUrl!.isNotEmpty
                          ? NetworkImage(contact.photoUrl!)
                          : null,
                      child: contact.photoUrl == null ||
                              contact.photoUrl!.isEmpty
                          ? Text(
                              _getInitials(contact.nama),
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Contact Details
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 24),

                // Name
                Text(
                  contact.nama,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Action Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        icon: Icons.phone,
                        label: 'Telepon',
                        onPressed: () => _makePhoneCall(contact.nomor),
                      ),
                      _buildActionButton(
                        icon: Icons.message,
                        label: 'SMS',
                        onPressed: () => _sendSMS(contact.nomor),
                      ),
                      _buildActionButton(
                        icon: Icons.email,
                        label: 'Email',
                        onPressed: () => _sendEmail(contact.email),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Contact Information
                _buildInfoSection(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFE7743),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white),
            iconSize: 28,
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoTile(
            context: context,
            icon: Icons.phone,
            title: 'Nomor Telepon',
            value: contact.nomor,
            onTap: () => _makePhoneCall(contact.nomor),
            onLongPress: () => _copyToClipboard(context, contact.nomor, 'Nomor telepon'),
          ),
          const Divider(height: 1),
          _buildInfoTile(
            context: context,
            icon: Icons.email,
            title: 'Email',
            value: contact.email,
            onTap: () => _sendEmail(contact.email),
            onLongPress: () => _copyToClipboard(context, contact.email, 'Email'),
          ),
          const Divider(height: 1),
          _buildInfoTile(
            context: context,
            icon: Icons.calendar_today,
            title: 'Dibuat',
            value: _formatDate(contact.createdAt),
            onTap: null,
            onLongPress: null,
          ),
          const Divider(height: 1),
          _buildInfoTile(
            context: context,
            icon: Icons.update,
            title: 'Terakhir Diubah',
            value: _formatDate(contact.updatedAt),
            onTap: null,
            onLongPress: null,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback? onTap,
    required VoidCallback? onLongPress,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFFE7743).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: const Color(0xFFFE7743),
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          color: Colors.grey,
        ),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
