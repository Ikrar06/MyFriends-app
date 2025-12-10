import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/contact_model.dart';

/// Contact Card Widget
///
/// Reusable contact list item with photo, name, phone, and favorite icon.
/// Displays contact information in a Material Card with tap handling.
///
/// Example usage:
/// ```dart
/// ContactCard(
///   contact: contact,
///   onTap: () {
///     Navigator.pushNamed(
///       context,
///       AppRoutes.contactDetail,
///       arguments: contact,
///     );
///   },
/// )
/// ```
class ContactCard extends StatelessWidget {
  final Contact contact;
  final VoidCallback onTap;
  final bool showFavorite;

  const ContactCard({
    super.key,
    required this.contact,
    required this.onTap,
    this.showFavorite = true,
  });

  /// Get initials from name (first 2 letters)
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
    // Extract contact properties
    final String nama = contact.nama;
    final String nomor = contact.nomor;
    final String? photoUrl = contact.photoUrl;
    final bool isEmergency = contact.isEmergency;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: _buildAvatar(nama, photoUrl),
        title: Text(
          nama,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          nomor,
          style: TextStyle(
            fontFamily: 'Poppins',
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        trailing: showFavorite && isEmergency
            ? const Icon(
                Icons.star,
                color: Colors.amber,
                size: 24,
              )
            : null,
        onTap: onTap,
      ),
    );
  }

  /// Build avatar with photo or initials
  Widget _buildAvatar(String nama, String? photoUrl) {
    return CircleAvatar(
      radius: 28,
      backgroundColor: Colors.blue[100],
      child: photoUrl != null && photoUrl.isNotEmpty
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: photoUrl,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, url, error) => _buildInitialsAvatar(nama),
              ),
            )
          : _buildInitialsAvatar(nama),
    );
  }

  /// Build avatar with initials
  Widget _buildInitialsAvatar(String nama) {
    return Text(
      _getInitials(nama),
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 18,
      ),
    );
  }
}

/// Compact Contact Card
///
/// Smaller variant for selection dialogs or bottom sheets.
class CompactContactCard extends StatelessWidget {
  final Contact contact;
  final VoidCallback? onTap;
  final Widget? trailing;

  const CompactContactCard({
    super.key,
    required this.contact,
    this.onTap,
    this.trailing,
  });

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
    final String nama = contact.nama;
    final String nomor = contact.nomor;
    final String? photoUrl = contact.photoUrl;

    return ListTile(
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: Colors.blue[100],
        child: photoUrl != null && photoUrl.isNotEmpty
            ? ClipOval(
                child: CachedNetworkImage(
                  imageUrl: photoUrl,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => Text(
                    _getInitials(nama),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              )
            : Text(
                _getInitials(nama),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
      ),
      title: Text(
        nama,
        style: const TextStyle(fontFamily: 'Poppins'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        nomor,
        style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.grey[600]),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
