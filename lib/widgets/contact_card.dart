import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Contact Card Widget
///
/// Reusable contact list item with photo, name, phone, and favorite icon.
/// Displays contact information in a Material Card with tap handling.
///
/// REQUIRES: Contact model from Orang 1 (Backend team)
/// TODO: Import Contact model when available
/// TODO: Replace dynamic with Contact type
///
/// Expected Contact model structure:
/// ```dart
/// class Contact {
///   String? id;
///   String nama;
///   String nomor;
///   String email;
///   String? photoUrl;
///   bool isFavorite;
///   String userId;
///   DateTime createdAt;
///   DateTime updatedAt;
/// }
/// ```
///
/// Example usage (once Contact model is available):
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
  final dynamic contact; // TODO: Change to Contact type when available
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
    // Extract contact properties (works with Map or Contact object)
    final String nama = contact is Map ? contact['nama'] : contact.nama;
    final String nomor = contact is Map ? contact['nomor'] : contact.nomor;
    final String? photoUrl =
        contact is Map ? contact['photoUrl'] : contact.photoUrl;
    final bool isFavorite =
        contact is Map ? contact['isFavorite'] ?? false : contact.isFavorite;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
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
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          nomor,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        trailing: showFavorite && isFavorite
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
  final dynamic contact; // TODO: Change to Contact type
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
    final String nama = contact is Map ? contact['nama'] : contact.nama;
    final String nomor = contact is Map ? contact['nomor'] : contact.nomor;
    final String? photoUrl =
        contact is Map ? contact['photoUrl'] : contact.photoUrl;

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
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        nomor,
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
