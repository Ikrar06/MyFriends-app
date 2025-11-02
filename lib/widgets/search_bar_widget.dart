import 'package:flutter/material.dart';

/// Search Bar Widget
///
/// Reusable search bar with clear button and customizable appearance.
/// Automatically shows/hides clear button based on input.
///
/// Example:
/// ```dart
/// SearchBarWidget(
///   onChanged: (query) {
///     context.read<ContactProvider>().searchContacts(query);
///   },
/// )
///
/// SearchBarWidget(
///   hintText: 'Search groups...',
///   controller: _searchController,
///   onChanged: _handleSearch,
/// )
/// ```
class SearchBarWidget extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final String hintText;
  final TextEditingController? controller;
  final VoidCallback? onClear;
  final bool autofocus;
  final TextInputAction? textInputAction;
  final VoidCallback? onSubmitted;

  const SearchBarWidget({
    super.key,
    required this.onChanged,
    this.hintText = 'Search...',
    this.controller,
    this.onClear,
    this.autofocus = false,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  late TextEditingController _controller;
  bool _showClearButton = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onTextChanged);
    _showClearButton = _controller.text.isNotEmpty;
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    } else {
      _controller.removeListener(_onTextChanged);
    }
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _showClearButton = _controller.text.isNotEmpty;
    });
  }

  void _handleClear() {
    _controller.clear();
    widget.onChanged('');
    if (widget.onClear != null) {
      widget.onClear!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      autofocus: widget.autofocus,
      textInputAction: widget.textInputAction ?? TextInputAction.search,
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _showClearButton
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: _handleClear,
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 2,
          ),
        ),
      ),
      onChanged: widget.onChanged,
      onSubmitted: (_) {
        if (widget.onSubmitted != null) {
          widget.onSubmitted!();
        }
      },
    );
  }
}

/// Compact Search Bar
///
/// Smaller variant for app bar or toolbar usage.
class CompactSearchBar extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final String hintText;
  final TextEditingController? controller;

  const CompactSearchBar({
    super.key,
    required this.onChanged,
    this.hintText = 'Search...',
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
          prefixIcon: const Icon(Icons.search, color: Colors.white, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
