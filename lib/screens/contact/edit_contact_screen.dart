import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  late TextEditingController _namaController;
  late TextEditingController _nomorController;
  late TextEditingController _emailController;
  late bool _isFavorite;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing contact data
    _namaController = TextEditingController(text: widget.contact.nama);
    _nomorController = TextEditingController(text: widget.contact.nomor);
    _emailController = TextEditingController(text: widget.contact.email);
    _isFavorite = widget.contact.isFavorite;
  }

  @override
  void dispose() {
    _namaController.dispose();
    _nomorController.dispose();
    _emailController.dispose();
    super.dispose();
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

      final updatedContact = widget.contact.copyWith(
        nama: _namaController.text.trim(),
        nomor: _nomorController.text.trim(),
        email: _emailController.text.trim(),
        isFavorite: _isFavorite,
        updatedAt: DateTime.now(),
      );

      await contactProvider.updateContact(updatedContact);

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kontak berhasil diperbarui'),
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
          content: Text('Gagal memperbarui kontak: $e'),
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
            'Hapus Kontak',
            style: TextStyle(fontFamily: 'Poppins'),
          ),
          content: Text(
            'Apakah Anda yakin ingin menghapus kontak "${widget.contact.nama}"?',
            style: const TextStyle(fontFamily: 'Poppins'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Batal',
                style: TextStyle(fontFamily: 'Poppins', color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                _deleteContact();
              },
              child: const Text(
                'Hapus',
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
          content: Text('Kontak berhasil dihapus'),
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
          content: Text('Gagal menghapus kontak: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFE7743),
        title: const Text(
          'Edit Kontak',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _isLoading ? null : _confirmDelete,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Profile Picture Placeholder
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: const Color(0xFFFE7743).withValues(alpha: 0.2),
                    backgroundImage: widget.contact.photoUrl != null && widget.contact.photoUrl!.isNotEmpty
                        ? NetworkImage(widget.contact.photoUrl!)
                        : null,
                    child: widget.contact.photoUrl == null || widget.contact.photoUrl!.isEmpty
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
                        onPressed: () {
                          // TODO: Implement image picker
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Fitur foto akan ditambahkan'),
                            ),
                          );
                        },
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
                labelText: 'Nama *',
                labelStyle: const TextStyle(fontFamily: 'Poppins'),
                hintText: 'Masukkan nama lengkap',
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
                  return 'Nama tidak boleh kosong';
                }
                if (value.trim().length > 100) {
                  return 'Nama maksimal 100 karakter';
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
                labelText: 'Nomor Telepon *',
                labelStyle: const TextStyle(fontFamily: 'Poppins'),
                hintText: 'Masukkan nomor telepon',
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
                  return 'Nomor telepon tidak boleh kosong';
                }
                if (value.trim().length > 20) {
                  return 'Nomor telepon maksimal 20 karakter';
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
                hintText: 'Masukkan email',
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
                  return 'Email tidak boleh kosong';
                }
                final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                if (!emailRegex.hasMatch(value.trim())) {
                  return 'Format email tidak valid';
                }
                if (value.trim().length > 100) {
                  return 'Email maksimal 100 karakter';
                }
                return null;
              },
              keyboardType: TextInputType.emailAddress,
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
                  'Tambahkan ke Favorit',
                  style: TextStyle(fontFamily: 'Poppins'),
                ),
                subtitle: const Text(
                  'Kontak favorit akan muncul di bagian atas',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 12),
                ),
                value: _isFavorite,
                onChanged: (value) {
                  setState(() {
                    _isFavorite = value;
                  });
                },
                activeTrackColor: const Color(0xFFFE7743).withValues(alpha: 0.5),
                activeThumbColor: const Color(0xFFFE7743),
                secondary: Icon(
                  _isFavorite ? Icons.star : Icons.star_border,
                  color: _isFavorite ? const Color(0xFFFE7743) : Colors.grey,
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
                        'Simpan Perubahan',
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
    );
  }
}
