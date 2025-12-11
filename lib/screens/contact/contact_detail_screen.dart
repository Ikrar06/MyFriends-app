import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/contact_model.dart';
import '../../providers/contact_provider.dart';
import '../../providers/group_provider.dart';
import '../../widgets/group_tag.dart';
import '../../routes/app_routes.dart';

/// Contact Detail Screen
///
/// Clean UI following design specifications
class ContactDetailScreen extends StatelessWidget {
  final Contact contact;

  const ContactDetailScreen({super.key, required this.contact});

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
        content: Text(
          '$label copied to clipboard',
          style: const TextStyle(fontFamily: 'Poppins'),
        ),
        backgroundColor: const Color(0xFFFE7743),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _toggleEmergency(BuildContext context) {
    final contactProvider = Provider.of<ContactProvider>(
      context,
      listen: false,
    );
    contactProvider.toggleEmergency(contact.id!, !contact.isEmergency);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          contact.isEmergency ? 'Removed from emergency' : 'Added to emergency',
          style: const TextStyle(fontFamily: 'Poppins'),
        ),
        backgroundColor: contact.isEmergency
            ? Colors.grey[700]
            : const Color(0xFFFFC107),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Contact',
          style: TextStyle(fontFamily: 'Poppins'),
        ),
        content: Text(
          'Are you sure you want to delete ${contact.nama}?',
          style: const TextStyle(fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text(
              'Delete',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final contactProvider = context.read<ContactProvider>();
      await contactProvider.deleteContact(contact.id!);
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Contact deleted',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Header with Photo
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              decoration: const BoxDecoration(
                color: Color(0xFFFE7743),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  // Back and Actions Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              contact.isEmergency
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.white,
                            ),
                            onPressed: () => _toggleEmergency(context),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.white),
                            onPressed: () => Navigator.pushNamed(
                              context,
                              AppRoutes.editContact,
                              arguments: contact,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Photo
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: ClipOval(
                      child:
                          contact.photoUrl != null &&
                              contact.photoUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: contact.photoUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                              errorWidget: (context, url, error) => Center(
                                child: Text(
                                  contact.nama.isNotEmpty
                                      ? contact.nama[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            )
                          : Center(
                              child: Text(
                                contact.nama.isNotEmpty
                                    ? contact.nama[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Name
                  Text(
                    contact.nama,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  if (contact.isEmergency) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFC107),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Emergency Contact',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Groups display
                  if (contact.groupIds.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Consumer<GroupProvider>(
                      builder: (context, groupProvider, child) {
                        final groups = groupProvider.getGroupsByIds(
                          contact.groupIds,
                        );
                        if (groups.isEmpty) return const SizedBox.shrink();
                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: groups
                              .map(
                                (group) => GroupTag(
                                  label: group.nama,
                                  colorHex: group.colorHex,
                                ),
                              )
                              .toList(),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Contact Info Cards
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // Phone Number Card
                    _buildInfoCard(
                      context,
                      icon: Icons.phone,
                      label: 'Phone Number',
                      value: contact.nomor,
                      actions: [
                        _buildActionButton(
                          icon: Icons.phone,
                          label: 'Call',
                          color: const Color(0xFF4CAF50),
                          onTap: () => _makePhoneCall(contact.nomor),
                        ),
                        _buildActionButton(
                          icon: Icons.message,
                          label: 'SMS',
                          color: const Color(0xFF2196F3),
                          onTap: () => _sendSMS(contact.nomor),
                        ),
                        _buildActionButton(
                          icon: Icons.content_copy,
                          label: 'Copy',
                          color: const Color(0xFF9E9E9E),
                          onTap: () => _copyToClipboard(
                            context,
                            contact.nomor,
                            'Phone number',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Email Card
                    if (contact.email.isNotEmpty)
                      _buildInfoCard(
                        context,
                        icon: Icons.email,
                        label: 'Email',
                        value: contact.email,
                        actions: [
                          _buildActionButton(
                            icon: Icons.email,
                            label: 'Email',
                            color: const Color(0xFFFE7743),
                            onTap: () => _sendEmail(contact.email),
                          ),
                          _buildActionButton(
                            icon: Icons.content_copy,
                            label: 'Copy',
                            color: const Color(0xFF9E9E9E),
                            onTap: () => _copyToClipboard(
                              context,
                              contact.email,
                              'Email',
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 16),

                    // Note Card
                    if (contact.note != null && contact.note!.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFFE7743,
                                    ).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.note_alt_outlined,
                                    color: Color(0xFFFE7743),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Private Note',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              contact.note!,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize:
                                    16, // Slightly smaller than phone/email
                                fontWeight: FontWeight.normal,
                                color: Colors.black87,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 32),

                    // Delete Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _confirmDelete(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text(
                          'Delete Contact',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required List<Widget> actions,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFE7743).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: const Color(0xFFFE7743), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Row(children: actions),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ElevatedButton.icon(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: Icon(icon, size: 18),
          label: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
