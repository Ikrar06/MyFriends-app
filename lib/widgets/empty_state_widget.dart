import 'package:flutter/material.dart';

/// Empty State Widget
///
/// Displays an empty state with icon, message, and optional action button.
/// Used when lists are empty, no search results, or error states.
///
/// Example:
/// ```dart
/// EmptyStateWidget(
///   icon: Icons.contacts,
///   message: 'No contacts yet.\nTap + to add your first contact!',
/// )
///
/// EmptyStateWidget(
///   icon: Icons.error_outline,
///   message: 'Something went wrong',
///   actionLabel: 'Retry',
///   onActionTap: () => provider.reload(),
/// )
/// ```
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onActionTap;
  final Color? iconColor;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onActionTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 100,
              color: iconColor ?? Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            if (actionLabel != null && onActionTap != null) ...[
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: onActionTap,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Error State Widget
///
/// Specialized empty state for error messages.
class ErrorStateWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorStateWidget({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.error_outline,
      iconColor: Theme.of(context).colorScheme.error,
      message: message,
      actionLabel: onRetry != null ? 'Retry' : null,
      onActionTap: onRetry,
    );
  }
}

/// No Results Widget
///
/// Specialized empty state for search/filter with no results.
class NoResultsWidget extends StatelessWidget {
  final String? query;
  final VoidCallback? onClear;

  const NoResultsWidget({
    super.key,
    this.query,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    String message = 'No results found';
    if (query != null && query!.isNotEmpty) {
      message = 'No results found for "$query"';
    }

    return EmptyStateWidget(
      icon: Icons.search_off,
      message: message,
      actionLabel: onClear != null ? 'Clear Search' : null,
      onActionTap: onClear,
    );
  }
}
