import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/contact_provider.dart';
import '../../models/contact_model.dart';
import '../../widgets/contact_card.dart';
import '../../routes/app_routes.dart';

/// Contact List Screen
///
/// Displays all contacts with search functionality.
/// Uses Consumer for real-time updates from Firestore.
class ContactListScreen extends StatefulWidget {
  const ContactListScreen({Key? key}) : super(key: key);

  @override
  State<ContactListScreen> createState() => _ContactListScreenState();
}

class _ContactListScreenState extends State<ContactListScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    final contactProvider = Provider.of<ContactProvider>(context, listen: false);
    contactProvider.searchContacts(query);
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _onSearchChanged('');
      }
    });
  }

  Future<void> _onRefresh() async {
    final contactProvider = Provider.of<ContactProvider>(context, listen: false);
    contactProvider.refresh();
  }

  void _navigateToAddContact() {
    Navigator.pushNamed(context, AppRoutes.addContact);
  }

  void _navigateToContactDetail(Contact contact) {
    Navigator.pushNamed(
      context,
      AppRoutes.contactDetail,
      arguments: contact,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFE7743),
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Cari kontak...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: _onSearchChanged,
              )
            : const Text(
                'Kontak',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            color: Colors.white,
            onPressed: _toggleSearch,
          ),
        ],
      ),
      body: Consumer<ContactProvider>(
        builder: (context, contactProvider, child) {
          // Loading state
          if (contactProvider.isLoading && contactProvider.contacts.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFE7743),
              ),
            );
          }

          // Error state
          if (contactProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    contactProvider.errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _onRefresh,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFE7743),
                    ),
                    child: const Text(
                      'Coba Lagi',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          // Empty state
          if (contactProvider.contacts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isSearching ? Icons.search_off : Icons.contacts,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isSearching
                        ? 'Kontak tidak ditemukan'
                        : 'Belum ada kontak',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  if (!_isSearching) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Tekan tombol + untuk menambah kontak',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }

          // Contact list
          return RefreshIndicator(
            color: const Color(0xFFFE7743),
            onRefresh: _onRefresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: contactProvider.contacts.length,
              itemBuilder: (context, index) {
                final contact = contactProvider.contacts[index];
                return ContactCard(
                  contact: contact,
                  onTap: () => _navigateToContactDetail(contact),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddContact,
        backgroundColor: const Color(0xFFFE7743),
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }
}
