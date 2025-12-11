import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../providers/contact_provider.dart';
import '../../providers/group_provider.dart';
import '../../models/contact_model.dart';
import '../group/group_management_page.dart';

/// Add Contact Screen
///
/// Form screen for adding new contacts.
/// Validates input and saves to Firestore via ContactProvider.
class AddContactScreen extends StatefulWidget {
  const AddContactScreen({super.key});

  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _nomorController = TextEditingController();
  final _emailController = TextEditingController();
  final _noteController = TextEditingController();
  bool _isEmergency = false;
  bool _isLoading = false;
  File? _selectedImage;
  final List<String> _selectedGroupIds = [];

  @override
  void dispose() {
    _namaController.dispose();
    _nomorController.dispose();
    _emailController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      // Show dialog to choose source
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(
            'Select Photo Source',
            style: TextStyle(fontFamily: 'Poppins'),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: Color(0xFFFE7743),
                ),
                title: const Text(
                  'Gallery',
                  style: TextStyle(fontFamily: 'Poppins'),
                ),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFFFE7743)),
                title: const Text(
                  'Camera',
                  style: TextStyle(fontFamily: 'Poppins'),
                ),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        ),
      );

      if (source == null) return;

      // Pick image
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to select photo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveContact() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final contactProvider = Provider.of<ContactProvider>(
        context,
        listen: false,
      );

      // Upload image to Firebase Storage if selected
      String? photoUrl;
      if (_selectedImage != null) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('contact_photos')
            .child('contact_$timestamp.jpg');

        final uploadTask = await storageRef.putFile(_selectedImage!);
        photoUrl = await uploadTask.ref.getDownloadURL();
      }

      final contact = Contact(
        nama: _namaController.text.trim(),
        nomor: _nomorController.text.trim(),
        email: _emailController.text.trim(),
        isEmergency: _isEmergency,
        photoUrl: photoUrl,
        groupIds: _selectedGroupIds,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        userId: '', // Will be set by service
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await contactProvider.addContact(contact);

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contact added successfully'),
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
          content: Text('Failed to add contact: $e'),
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
                    'Add Contact',
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
                    // Profile Picture Placeholder
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: const Color(
                              0xFFFE7743,
                            ).withValues(alpha: 0.2),
                            backgroundImage: _selectedImage != null
                                ? FileImage(_selectedImage!)
                                : null,
                            child: _selectedImage == null
                                ? const Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Color(0xFFFE7743),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFFE7743),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                onPressed: _pickImage,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Nama Field
                    TextFormField(
                      controller: _namaController,
                      decoration: InputDecoration(
                        labelText: 'Name *',
                        labelStyle: const TextStyle(fontFamily: 'Poppins'),
                        hintText: 'Enter full name',
                        prefixIcon: const Icon(
                          Icons.person_outline,
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
                          return 'Name cannot be empty';
                        }
                        if (value.trim().length > 100) {
                          return 'Name maximum 100 characters';
                        }
                        return null;
                      },
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 16),

                    // Nomor Field
                    TextFormField(
                      controller: _nomorController,
                      decoration: InputDecoration(
                        labelText: 'Phone Number *',
                        labelStyle: const TextStyle(fontFamily: 'Poppins'),
                        hintText: 'Enter phone number',
                        prefixIcon: const Icon(
                          Icons.phone_outlined,
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
                          return 'Phone number cannot be empty';
                        }
                        if (value.trim().length > 20) {
                          return 'Phone number maximum 20 characters';
                        }
                        return null;
                      },
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),

                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email *',
                        labelStyle: const TextStyle(fontFamily: 'Poppins'),
                        hintText: 'Enter email',
                        prefixIcon: const Icon(
                          Icons.email_outlined,
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
                          return 'Email cannot be empty';
                        }
                        final emailRegex = RegExp(
                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                        );
                        if (!emailRegex.hasMatch(value.trim())) {
                          return 'Invalid email format';
                        }
                        if (value.trim().length > 100) {
                          return 'Email maximum 100 characters';
                        }
                        return null;
                      },
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),

                    const SizedBox(height: 16),

                    // Note Field
                    TextFormField(
                      controller: _noteController,
                      decoration: InputDecoration(
                        labelText: 'Private Note',
                        labelStyle: const TextStyle(fontFamily: 'Poppins'),
                        hintText: 'Enter note about this contact (private)',
                        prefixIcon: const Icon(
                          Icons.note_alt_outlined,
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
                        alignLabelWithHint: true,
                      ),
                      maxLength: 500,
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 16),

                    // Favorite Toggle
                    Card(
                      elevation: 0,
                      color: Colors.grey[100],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SwitchListTile(
                        title: const Text(
                          'Mark as Emergency Contact',
                          style: TextStyle(fontFamily: 'Poppins'),
                        ),
                        subtitle: const Text(
                          'Emergency contacts will receive SOS messages',
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 12),
                        ),
                        value: _isEmergency,
                        onChanged: (value) {
                          setState(() {
                            _isEmergency = value;
                          });
                        },
                        activeTrackColor: const Color(
                          0xFFFE7743,
                        ).withValues(alpha: 0.5),
                        activeThumbColor: const Color(0xFFFE7743),
                        secondary: Icon(
                          _isEmergency ? Icons.star : Icons.star_border,
                          color: _isEmergency
                              ? const Color(0xFFFE7743)
                              : Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- Groups Section ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Groups',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const GroupManagementPage(),
                              ),
                            );
                          },
                          child: const Text('Manage Groups'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Consumer<GroupProvider>(
                      builder: (context, groupProvider, child) {
                        final groups = groupProvider.groups;
                        if (groups.isEmpty) {
                          return const Text(
                            'No groups available. Create one!',
                            style: TextStyle(
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          );
                        }
                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: groups.map((group) {
                            final isSelected = _selectedGroupIds.contains(
                              group.id,
                            );
                            return FilterChip(
                              label: Text(group.nama),
                              selected: isSelected,
                              onSelected: (bool selected) {
                                setState(() {
                                  if (selected) {
                                    if (group.id != null)
                                      _selectedGroupIds.add(group.id!);
                                  } else {
                                    _selectedGroupIds.remove(group.id);
                                  }
                                });
                              },
                              backgroundColor: Color(
                                int.parse(
                                  group.colorHex.replaceAll('#', '0xFF'),
                                ),
                              ).withOpacity(0.1),
                              selectedColor: Color(
                                int.parse(
                                  group.colorHex.replaceAll('#', '0xFF'),
                                ),
                              ).withOpacity(0.3),
                              checkmarkColor: Colors.black,
                              labelStyle: TextStyle(
                                color: Colors.black87,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: Color(
                                    int.parse(
                                      group.colorHex.replaceAll('#', '0xFF'),
                                    ),
                                  ),
                                  width: isSelected ? 2 : 1,
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
                        onPressed: _isLoading ? null : _saveContact,
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
                                'Save Contact',
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
