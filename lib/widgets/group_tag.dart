import 'package:flutter/material.dart';

class GroupTag extends StatelessWidget {
  final String label;
  final String colorHex;
  final VoidCallback? onDeleted;

  const GroupTag({
    Key? key,
    required this.label,
    required this.colorHex,
    this.onDeleted,
  }) : super(key: key);

  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF' + hex;
    }
    return Color(int.parse(hex, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final Color bgColor = _hexToColor(colorHex);
    // Determine if text should be white or black based on bg luminance
    final Color textColor = bgColor.computeLuminance() > 0.5
        ? Colors.black
        : Colors.white;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (onDeleted != null) ...[
            SizedBox(width: 4),
            InkWell(
              onTap: onDeleted,
              child: Icon(Icons.close, size: 14, color: textColor),
            ),
          ],
        ],
      ),
    );
  }
}
