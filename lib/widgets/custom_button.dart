import 'package:flutter/material.dart';
import 'loading_widget.dart';

/// Custom Button
///
/// Reusable button widget with loading state support.
/// Automatically shows loading indicator when isLoading is true.
///
/// Example:
/// ```dart
/// CustomButton(
///   text: 'Login',
///   onPressed: _handleLogin,
///   isLoading: _isLoading,
/// )
///
/// CustomButton(
///   text: 'Delete',
///   onPressed: _handleDelete,
///   backgroundColor: Colors.red,
///   icon: Icons.delete,
/// )
/// ```
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;
  final bool isFullWidth;
  final IconData? icon;
  final double? height;
  final double? borderRadius;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
    this.isFullWidth = true,
    this.icon,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: height ?? 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: backgroundColor != null
            ? ElevatedButton.styleFrom(
                backgroundColor: backgroundColor,
                foregroundColor: textColor ?? Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(borderRadius ?? 12),
                ),
                disabledBackgroundColor: backgroundColor?.withValues(alpha: 0.6),
              )
            : ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(borderRadius ?? 12),
                ),
              ),
        child: isLoading
            ? SmallLoadingIndicator(
                color: textColor ?? Colors.white,
              )
            : icon != null
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon),
                      const SizedBox(width: 8),
                      Text(text),
                    ],
                  )
                : Text(text),
      ),
    );
  }
}

/// Outline Button
///
/// Outlined variant of custom button.
class CustomOutlineButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? borderColor;
  final Color? textColor;
  final bool isFullWidth;
  final IconData? icon;
  final double? height;

  const CustomOutlineButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.borderColor,
    this.textColor,
    this.isFullWidth = true,
    this.icon,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final color = borderColor ?? Theme.of(context).primaryColor;

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: height ?? 56,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: textColor ?? color,
          side: BorderSide(color: color),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? SmallLoadingIndicator(
                color: textColor ?? color,
              )
            : icon != null
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon),
                      const SizedBox(width: 8),
                      Text(text),
                    ],
                  )
                : Text(text),
      ),
    );
  }
}

/// Icon Button with Loading
///
/// Icon button that shows loading indicator when busy.
class CustomIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? color;
  final double? size;
  final String? tooltip;

  const CustomIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.isLoading = false,
    this.color,
    this.size,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final button = IconButton(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? SmallLoadingIndicator(
              color: color ?? Theme.of(context).primaryColor,
              size: size ?? 24,
            )
          : Icon(
              icon,
              color: color,
              size: size,
            ),
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip!,
        child: button,
      );
    }

    return button;
  }
}
