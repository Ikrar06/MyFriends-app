import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/contact_provider.dart';
import '../../models/contact_model.dart';
import '../../models/group_model.dart';

/// Add Group Screen
///
/// Form screen for creating new groups.
/// Validates input and saves to Firestore via GroupProvider.
class AddGroupScreen extends StatefulWidget {
  const AddGroupScreen({super.key});

  @override
  State<AddGroupScreen> createState() => _AddGroupScreenState();
}

class _AddGroupScreenState extends State<AddGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final List<String> _selectedContactIds = [];
  Color _currentColor = const Color(0xFFFE7743);
  String _colorHex = '#FE7743';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveGroup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);

      final newGroupId = await groupProvider.addGroup(
        _nameController.text.trim(),
        _colorHex,
      );

      if (newGroupId != null && _selectedContactIds.isNotEmpty) {
        if (!mounted) return;
        // Add selected contacts to the new group
        // We do this by updating each contact's groupIds list
        for (final contactId in _selectedContactIds) {
          await groupProvider.addContactToGroup(newGroupId, contactId);
        }
      }

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Group created successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create group: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button and title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Create New Group',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            // Form content
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  children: [
                    // Group Icon Placeholder
                    // Group Icon with Color Picker Trigger
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Select Group Color'),
                              content: SingleChildScrollView(
                                child: BlockPicker(
                                  pickerColor: _currentColor,
                                  onColorChanged: (color) {
                                    setState(() {
                                      _currentColor = color;
                                      _colorHex =
                                          '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
                                    });
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: _currentColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                            border: Border.all(color: _currentColor, width: 2),
                          ),
                          child: Icon(
                            Icons.group,
                            size: 60,
                            color: _currentColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        'Tap icon to change color',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Group Name Field
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Group Name *',
                        labelStyle: const TextStyle(fontFamily: 'Poppins'),
                        hintText: 'Enter group name',
                        prefixIcon: const Icon(
                          Icons.label_outline,
                          color: Color(0xFFFE7743),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFFE7743),
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Group name cannot be empty';
                        }
                        if (value.trim().length > 50) {
                          return 'Group name maximum 50 characters';
                        }
                        return null;
                      },
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 16),

                    // Info Card
                    // Members Section
                    const Text(
                      'Add Members',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Consumer<ContactProvider>(
                      builder: (context, contactProvider, child) {
                        final contacts = contactProvider.contacts;
                        if (contacts.isEmpty) {
                          return const Text(
                            'No contacts available.',
                            style: TextStyle(color: Colors.grey),
                          );
                        }
                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: contacts.map((contact) {
                            final isSelected = _selectedContactIds.contains(
                              contact.id,
                            );
                            return FilterChip(
                              label: Text(contact.nama),
                              selected: isSelected,
                              onSelected: (bool selected) {
                                setState(() {
                                  if (selected) {
                                    if (contact.id != null) {
                                      _selectedContactIds.add(contact.id!);
                                    }
                                  } else {
                                    _selectedContactIds.remove(contact.id);
                                  }
                                });
                              },
                              backgroundColor: Colors.white,
                              selectedColor: const Color(
                                0xFFFE7743,
                              ).withOpacity(0.2),
                              checkmarkColor: const Color(0xFFFE7743),
                              labelStyle: TextStyle(
                                fontFamily: 'Poppins',
                                color: isSelected
                                    ? const Color(0xFFFE7743)
                                    : Colors.black87,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: isSelected
                                      ? const Color(0xFFFE7743)
                                      : Colors.grey[300]!,
                                  width: 1,
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 32),

                    // Save Button
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveGroup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFE7743),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Create Group',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
