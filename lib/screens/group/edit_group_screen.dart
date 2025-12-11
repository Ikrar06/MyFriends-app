import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/contact_provider.dart';
import '../../models/group_model.dart';

/// Edit Group Screen
///
/// Form screen for editing existing groups.
/// Receives Group object as navigation argument.
class EditGroupScreen extends StatefulWidget {
  final Group group;

  const EditGroupScreen({super.key, required this.group});

  @override
  State<EditGroupScreen> createState() => _EditGroupScreenState();
}

class _EditGroupScreenState extends State<EditGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late Color _currentColor;
  late String _colorHex;
  bool _isLoading = false;

  List<String> _selectedContactIds = [];
  List<String> _initialContactIds = [];
  bool _isInit = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.group.nama);
    _colorHex = widget.group.colorHex;
    try {
      _currentColor = Color(int.parse(_colorHex.replaceAll('#', '0xFF')));
    } catch (e) {
      _currentColor = const Color(0xFFFE7743);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      final contactProvider = Provider.of<ContactProvider>(context);
      final groupContacts = contactProvider.contacts
          .where((c) => c.groupIds.contains(widget.group.id))
          .map((c) => c.id!)
          .toList();
      _selectedContactIds = List.from(groupContacts);
      _initialContactIds = List.from(groupContacts);
      _isInit = false;
    }
  }

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

      final updatedGroup = widget.group.copyWith(
        nama: _nameController.text.trim(),
        colorHex: _colorHex,
        updatedAt: DateTime.now(),
      );

      await groupProvider.updateGroup(updatedGroup);

      // Handle Contact Updates
      // 1. Find contacts to add (present in selected but not in initial)
      final toAdd = _selectedContactIds
          .where((id) => !_initialContactIds.contains(id))
          .toList();

      // 2. Find contacts to remove (present in initial but not in selected)
      final toRemove = _initialContactIds
          .where((id) => !_selectedContactIds.contains(id))
          .toList();

      // Execute updates
      for (final contactId in toAdd) {
        await groupProvider.addContactToGroup(widget.group.id!, contactId);
      }

      for (final contactId in toRemove) {
        await groupProvider.removeContactFromGroup(widget.group.id!, contactId);
      }

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Group updated successfully'),
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
          content: Text('Failed to update group: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Delete Group',
            style: TextStyle(fontFamily: 'Poppins'),
          ),
          content: Text(
            'Are you sure you want to delete the group "${widget.group.nama}"?',
            style: const TextStyle(fontFamily: 'Poppins'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(fontFamily: 'Poppins', color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                _deleteGroup();
              },
              child: const Text(
                'Delete',
                style: TextStyle(fontFamily: 'Poppins', color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteGroup() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      await groupProvider.deleteGroup(widget.group.id!);

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Group deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back twice (to group list)
      Navigator.pop(context);
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete group: $e'),
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
            // Header with back button, title, and delete button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Edit Group',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: _isLoading ? null : _confirmDelete,
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
                    // Group Icon with Color Picker Trigger
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          // Show color picker dialog
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
                                          '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
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

                    const SizedBox(height: 16),

                    // Members Section
                    const Text(
                      'Manage Members',
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
                              selectedColor: Color(
                                int.parse(_colorHex.replaceAll('#', '0xFF')),
                              ).withValues(alpha: 0.2),
                              checkmarkColor: Color(
                                int.parse(_colorHex.replaceAll('#', '0xFF')),
                              ),
                              labelStyle: TextStyle(
                                fontFamily: 'Poppins',
                                color: isSelected
                                    ? Color(
                                        int.parse(
                                          _colorHex.replaceAll('#', '0xFF'),
                                        ),
                                      )
                                    : Colors.black87,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: isSelected
                                      ? Color(
                                          int.parse(
                                            _colorHex.replaceAll('#', '0xFF'),
                                          ),
                                        )
                                      : Colors.grey[300]!,
                                  width: 1,
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Info Card
                    Card(
                      elevation: 0,
                      color: Colors.grey[100],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  color: Color(0xFFFE7743),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Group Information',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // _buildInfoRow('Members', '${widget.group.contactIds.length} contacts'),
                            _buildInfoRow(
                              'Created',
                              _formatDate(widget.group.createdAt),
                            ),
                          ],
                        ),
                      ),
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
                                'Save Changes',
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
