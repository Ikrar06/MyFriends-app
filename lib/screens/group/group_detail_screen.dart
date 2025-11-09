import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/group_model.dart';
import '../../models/contact_model.dart';
import '../../providers/group_provider.dart';
import '../../providers/contact_provider.dart';
import '../../widgets/contact_card.dart';
import '../../routes/app_routes.dart';

/// Group Detail Screen
///
/// Displays group information and member list.
/// Allows adding/removing contacts and editing group.
class GroupDetailScreen extends StatefulWidget {
  final Group group;

  const GroupDetailScreen({
    super.key,
    required this.group,
  });

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Load contacts in this group
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      groupProvider.loadContactsInGroup(widget.group.id!);
    });
  }

  void _navigateToEdit() {
    Navigator.pushNamed(
      context,
      AppRoutes.editGroup,
      arguments: widget.group,
    );
  }

  void _navigateToContactDetail(Contact contact) {
    Navigator.pushNamed(
      context,
      AppRoutes.contactDetail,
      arguments: contact,
    );
  }

  void _showAddContactDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddContactBottomSheet(group: widget.group),
    );
  }

  Future<void> _removeContact(Contact contact) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Hapus Anggota',
          style: TextStyle(fontFamily: 'Poppins'),
        ),
        content: Text(
          'Hapus ${contact.nama} dari grup ini?',
          style: const TextStyle(fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Batal',
              style: TextStyle(fontFamily: 'Poppins', color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Hapus',
              style: TextStyle(fontFamily: 'Poppins', color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final groupProvider = Provider.of<GroupProvider>(context, listen: false);
        await groupProvider.removeContactFromGroup(widget.group.id!, contact.id!);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Anggota berhasil dihapus'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus anggota: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFFFE7743),
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: _navigateToEdit,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFFE7743),
                      Color(0xFFFF9068),
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.group,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.group.nama,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Members Section
          SliverToBoxAdapter(
            child: Consumer<GroupProvider>(
              builder: (context, groupProvider, child) {
                if (groupProvider.isLoading) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFE7743),
                      ),
                    ),
                  );
                }

                final contacts = groupProvider.contactsInGroup;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.people,
                                color: Color(0xFFFE7743),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Anggota (${contacts.length})',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          TextButton.icon(
                            onPressed: _showAddContactDialog,
                            icon: const Icon(
                              Icons.person_add,
                              size: 20,
                              color: Color(0xFFFE7743),
                            ),
                            label: const Text(
                              'Tambah',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: Color(0xFFFE7743),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (contacts.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 64,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Belum ada anggota',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: contacts.length,
                        itemBuilder: (context, index) {
                          final contact = contacts[index];
                          return Dismissible(
                            key: Key(contact.id!),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              color: Colors.red,
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ),
                            confirmDismiss: (direction) async {
                              await _removeContact(contact);
                              return false; // Don't auto-dismiss
                            },
                            child: ContactCard(
                              contact: contact,
                              onTap: () => _navigateToContactDetail(contact),
                            ),
                          );
                        },
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom Sheet for Adding Contacts to Group
class _AddContactBottomSheet extends StatefulWidget {
  final Group group;

  const _AddContactBottomSheet({required this.group});

  @override
  State<_AddContactBottomSheet> createState() => _AddContactBottomSheetState();
}

class _AddContactBottomSheetState extends State<_AddContactBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _addContact(Contact contact) async {
    try {
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      await groupProvider.addContactToGroup(widget.group.id!, contact.id!);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${contact.nama} ditambahkan ke grup'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menambahkan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tambah Anggota',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari kontak...',
                hintStyle: const TextStyle(fontFamily: 'Poppins'),
                prefixIcon: const Icon(Icons.search, color: Color(0xFFFE7743)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFFE7743)),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          const SizedBox(height: 16),

          // Contact List
          Expanded(
            child: Consumer<ContactProvider>(
              builder: (context, contactProvider, child) {
                final allContacts = contactProvider.contacts;
                final existingIds = widget.group.contactIds;

                // Filter out contacts already in group
                final availableContacts = allContacts
                    .where((contact) => !existingIds.contains(contact.id))
                    .where((contact) =>
                        _searchQuery.isEmpty ||
                        contact.nama.toLowerCase().contains(_searchQuery))
                    .toList();

                if (availableContacts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_off_outlined,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'Semua kontak sudah ada di grup'
                              : 'Kontak tidak ditemukan',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: availableContacts.length,
                  itemBuilder: (context, index) {
                    final contact = availableContacts[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFFE7743).withValues(alpha: 0.2),
                        child: Text(
                          contact.nama.isNotEmpty ? contact.nama[0].toUpperCase() : '?',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            color: Color(0xFFFE7743),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        contact.nama,
                        style: const TextStyle(fontFamily: 'Poppins'),
                      ),
                      subtitle: Text(
                        contact.nomor,
                        style: const TextStyle(fontFamily: 'Poppins'),
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.add_circle,
                          color: Color(0xFFFE7743),
                        ),
                        onPressed: () => _addContact(contact),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
