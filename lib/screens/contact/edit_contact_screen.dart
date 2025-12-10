import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../providers/contact_provider.dart';
import '../../models/contact_model.dart';

/// Edit Contact Screen
///
/// Form screen for editing existing contacts.
/// Receives Contact object as navigation argument.
class EditContactScreen extends StatefulWidget {
  final Contact contact;

  const EditContactScreen({
    super.key,
    required this.contact,
  });

  @override
  State<EditContactScreen> createState() => _EditContactScreenState();
}

class _EditContactScreenState extends State<EditContactScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late bool _isEmergency;
  bool _isLoading = false;
  File? _selectedImage;
  String? _currentPhotoUrl;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing contact data
    _nameController = TextEditingController(text: widget.contact.nama);
    _phoneController = TextEditingController(text: widget.contact.nomor);
    _emailController = TextEditingController(text: widget.contact.email);
    _isEmergency = widget.contact.isEmergency;
    _currentPhotoUrl = widget.contact.photoUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      // Show dialog to choose source
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(
            'Choose Photo Source',
            style: TextStyle(fontFamily: 'Poppins'),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFFFE7743)),
                title: const Text('Gallery', style: TextStyle(fontFamily: 'Poppins')),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFFFE7743)),
                title: const Text('Camera', style: TextStyle(fontFamily: 'Poppins')),
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
          content: Text('Failed to pick photo: $e'),
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
      final contactProvider = Provider.of<ContactProvider>(context, listen: false);

      // Upload new image if selected
      String? photoUrl = _currentPhotoUrl;
      if (_selectedImage != null) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('contact_photos')
            .child('contact_$timestamp.jpg');

        final uploadTask = await storageRef.putFile(_selectedImage!);
        photoUrl = await uploadTask.ref.getDownloadURL();
      }

      final updatedContact = widget.contact.copyWith(
        nama: _nameController.text.trim(),
        nomor: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        isEmergency: _isEmergency,
        photoUrl: photoUrl,
        updatedAt: DateTime.now(),
      );

      await contactProvider.updateContact(updatedContact);

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contact updated successfully'),
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
          content: Text('Failed to update contact: $e'),
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
            'Delete Contact',
            style: TextStyle(fontFamily: 'Poppins'),
          ),
          content: Text(
            'Are you sure you want to delete the contact "${widget.contact.nama}"?',
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
                _deleteContact();
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

  Future<void> _deleteContact() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final contactProvider = Provider.of<ContactProvider>(context, listen: false);
      await contactProvider.deleteContact(widget.contact.id!);

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contact deleted successfully'),
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
          content: Text('Failed to delete contact: $e'),
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
                      'Edit Contact',
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
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  children: [
            // Profile Picture Placeholder
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: const Color(0xFFFE7743).withValues(alpha: 0.2),
                    backgroundImage: _selectedImage != null
                        ? FileImage(_selectedImage!)
                        : (_currentPhotoUrl != null && _currentPhotoUrl!.isNotEmpty
                            ? NetworkImage(_currentPhotoUrl!)
                            : null),
                    child: _selectedImage == null && (_currentPhotoUrl == null || _currentPhotoUrl!.isEmpty)
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
                        border: Border.all(color: Colors.white, width: 2),
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

            // Name Field
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name *',
                labelStyle: const TextStyle(fontFamily: 'Poppins'),
                hintText: 'Enter full name',
                prefixIcon: const Icon(Icons.person_outline, color: Color(0xFFFE7743)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFFE7743), width: 2),
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

            // Phone Number Field
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Phone Number *',
                labelStyle: const TextStyle(fontFamily: 'Poppins'),
                hintText: 'Enter phone number',
                prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFFFE7743)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFFE7743), width: 2),
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
                prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFFFE7743)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFFE7743), width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Email cannot be empty';
                }
                final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
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

            // Emergency Contact Toggle
            Card(
              elevation: 0,
              color: Colors.grey[100],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: SwitchListTile(
                title: const Text(
                  'Set as Emergency Contact',
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
                activeTrackColor: const Color(0xFFFE7743).withValues(alpha: 0.5),
                activeThumbColor: const Color(0xFFFE7743),
                secondary: Icon(
                  _isEmergency ? Icons.star : Icons.star_border,
                  color: _isEmergency ? const Color(0xFFFE7743) : Colors.grey,
                ),
              ),
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
}