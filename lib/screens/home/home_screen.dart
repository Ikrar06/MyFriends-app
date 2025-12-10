import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/contact_provider.dart';
import '../../providers/sos_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/sos_slide_button.dart';
import '../contact/contact_list_screen.dart';
import '../group/group_list_screen.dart';
import '../auth/profile_screen.dart';

/// Home Screen - Main Screen with Bottom Navigation
///
/// Clean UI with 4 tabs: Home, Contacts, Groups, Profile
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const _HomeTab(),
    const ContactListScreen(),
    const GroupListScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        height: 90,
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(icon: Icons.home_rounded, label: 'Home', index: 0),
              _buildNavItem(icon: Icons.contacts_rounded, label: 'Contacts', index: 1),
              _buildNavItem(icon: Icons.group_rounded, label: 'Groups', index: 2),
              _buildNavItem(icon: Icons.person_rounded, label: 'Profile', index: 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isActive = _currentIndex == index;
    final color = isActive ? const Color(0xFFFE7743) : const Color(0xFF9E9E9E);

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Home Tab - Dashboard
class _HomeTab extends StatelessWidget {
  const _HomeTab();

  Future<void> _handleSOSSend(
    BuildContext context,
    SOSProvider sosProvider,
    ContactProvider contactProvider,
  ) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;

      if (user == null) throw Exception('User not logged in');

      final emergencyContacts = contactProvider.emergencyContacts;
      if (emergencyContacts.isEmpty) throw Exception('No emergency contacts');

      final phoneNumber = await authProvider.getPhoneNumber();
      final emergencyContactIds = await sosProvider.getEmergencyContactUserIds(emergencyContacts);

      if (emergencyContactIds.isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No emergency contacts registered in the app', style: TextStyle(fontFamily: 'Poppins')),
            backgroundColor: Colors.orange[700],
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      await sosProvider.sendSOS(
        emergencyContactIds: emergencyContactIds,
        senderName: user.displayName ?? 'Unknown',
        senderPhone: phoneNumber ?? 'No phone',
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('SOS sent to ${emergencyContactIds.length} emergency contacts!', style: const TextStyle(fontFamily: 'Poppins')),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send SOS: $e', style: const TextStyle(fontFamily: 'Poppins')),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              // Hi, User!
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  final displayName = authProvider.currentUser?.displayName ?? 'User';
                  return Text(
                    'Hi, $displayName!',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 36,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                      height: 1.0,
                    ),
                  );
                },
              ),

              const SizedBox(height: 48),

              // Quick Access Section
              const Text(
                'Quick Access',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 24),

              // Quick Action Buttons - Direct PNG
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pushNamed(context, AppRoutes.addContact),
                      child: Image.asset(
                        'assets/images/addcontact.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pushNamed(context, AppRoutes.addGroup),
                      child: Image.asset(
                        'assets/images/makegroup.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
                      child: Image.asset(
                        'assets/images/editprofile.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 48),

              // Emergency contacts section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Emergency contacts',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                  ),
                  Consumer<ContactProvider>(
                    builder: (context, contactProvider, child) {
                      final count = contactProvider.emergencyCount;
                      return GestureDetector(
                        onTap: () => Navigator.pushNamed(context, AppRoutes.emergencyContacts),
                        child: Text(
                          'View All($count)',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Colors.black,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Emergency Contact List (max 3)
              Consumer<ContactProvider>(
                builder: (context, contactProvider, child) {
                  final emergencyContacts = contactProvider.emergencyContacts.take(3).toList();

                  if (emergencyContacts.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'No emergency contacts yet',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: emergencyContacts.map((contact) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white, width: 8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFD9D9D9),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    contact.nama.isNotEmpty ? contact.nama[0].toUpperCase() : '?',
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      contact.nama,
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      contact.nomor,
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: List.generate(
                                  3,
                                  (index) => Container(
                                    width: 6,
                                    height: 6,
                                    margin: const EdgeInsets.only(bottom: 6),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFD9D9D9),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),

              const SizedBox(height: 48),

              // SOS Slide Button
              Consumer2<SOSProvider, ContactProvider>(
                builder: (context, sosProvider, contactProvider, child) {
                  final hasEmergencyContacts = contactProvider.emergencyContacts.isNotEmpty;

                  return Column(
                    children: [
                      if (hasEmergencyContacts)
                        SOSSlideButton(
                          isLoading: sosProvider.isSending,
                          onSlideComplete: () => _handleSOSSend(context, sosProvider, contactProvider),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(88),
                            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                          ),
                          child: Center(
                            child: Text(
                              'Add emergency contacts to use SOS',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.orange[900],
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Text(
                        'Your emergency contacts will be notified\nimmediately with your live location.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey[700],
                          height: 1.4,
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}