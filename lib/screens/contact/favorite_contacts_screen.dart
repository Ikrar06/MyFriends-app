import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/contact_provider.dart';
import '../../models/contact_model.dart';
import '../../widgets/contact_card.dart';
import '../../routes/app_routes.dart';

/// Favorite Contacts Screen
///
/// Displays all contacts marked as favorites.
/// Uses Consumer for real-time updates from Firestore.
class FavoriteContactsScreen extends StatelessWidget {
  const FavoriteContactsScreen({super.key});

  Future<void> _onRefresh(BuildContext context) async {
    final contactProvider = Provider.of<ContactProvider>(context, listen: false);
    contactProvider.refresh();
  }

  void _navigateToContactDetail(BuildContext context, Contact contact) {
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
        title: const Text(
          'Kontak Favorit',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Consumer<ContactProvider>(
        builder: (context, contactProvider, child) {
          // Loading state
          if (contactProvider.isLoading && contactProvider.favoriteContacts.isEmpty) {
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
                    onPressed: () => _onRefresh(context),
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
          if (contactProvider.favoriteContacts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.star_outline,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Belum ada kontak favorit',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: Text(
                      'Tandai kontak sebagai favorit untuk melihatnya di sini',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFE7743),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    label: const Text(
                      'Kembali ke Kontak',
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

          // Favorite contacts list
          return RefreshIndicator(
            color: const Color(0xFFFE7743),
            onRefresh: () => _onRefresh(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: Color(0xFFFE7743),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${contactProvider.favoriteCount} Kontak Favorit',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFFE7743),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: contactProvider.favoriteContacts.length,
                    itemBuilder: (context, index) {
                      final contact = contactProvider.favoriteContacts[index];
                      return ContactCard(
                        contact: contact,
                        onTap: () => _navigateToContactDetail(context, contact),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
