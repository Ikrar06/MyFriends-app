import 'package:flutter/material.dart';
import '../models/group_model.dart';

/// Group Card Widget
///
/// Reusable group card with color indicator and contact count.
/// Displays group information in a Material Card with tap handling.
///
/// Example usage:
/// ```dart
/// GroupCard(
///   group: group,
///   onTap: () {
///     Navigator.pushNamed(
///       context,
///       AppRoutes.groupDetail,
///       arguments: group,
///     );
///   },
/// )
/// ```
class GroupCard extends StatelessWidget {
  final Group group;
  final VoidCallback onTap;

  const GroupCard({super.key, required this.group, required this.onTap});

  /// Convert hex color string to Color object
  Color _hexToColor(String hexString) {
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return Colors.blue; // Default color if parsing fails
    }
  }

  @override
  Widget build(BuildContext context) {
    // Extract group properties
    final String nama = group.nama;
    final String colorHex = group.colorHex;
    // final int contactCount = group.getContactCount(); // Deprecated
    final Color groupColor = _hexToColor(colorHex);

    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border(left: BorderSide(color: groupColor, width: 4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: groupColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      nama,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.people, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  /*
                  Text(
                    '$contactCount contact${contactCount == 1 ? '' : 's'}',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  */
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact Group Card
///
/// Smaller variant for selection dialogs or horizontal lists.
class CompactGroupCard extends StatelessWidget {
  final Group group;
  final VoidCallback? onTap;
  final bool isSelected;

  const CompactGroupCard({
    super.key,
    required this.group,
    this.onTap,
    this.isSelected = false,
  });

  Color _hexToColor(String hexString) {
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String nama = group.nama;
    final String colorHex = group.colorHex;
    final Color groupColor = _hexToColor(colorHex);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? groupColor.withValues(alpha: 0.2) : null,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? groupColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: groupColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              nama,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Group Chip
///
/// Very small chip for displaying group tags in contact details.
class GroupChip extends StatelessWidget {
  final Group group;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const GroupChip({super.key, required this.group, this.onTap, this.onDelete});

  Color _hexToColor(String hexString) {
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String nama = group.nama;
    final String colorHex = group.colorHex;
    final Color groupColor = _hexToColor(colorHex);

    return Chip(
      label: Text(
        nama,
        style: const TextStyle(fontFamily: 'Poppins', fontSize: 12),
      ),
      backgroundColor: groupColor.withValues(alpha: 0.2),
      side: BorderSide(color: groupColor),
      avatar: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: groupColor, shape: BoxShape.circle),
      ),
      onDeleted: onDelete,
      deleteIcon: onDelete != null ? const Icon(Icons.close, size: 16) : null,
    );
  }
}
