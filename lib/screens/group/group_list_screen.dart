import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/group_provider.dart';
import '../../models/group_model.dart';
import '../../routes/app_routes.dart';

/// Group List Screen
///
/// Displays all groups with real-time updates.
/// Uses Consumer for listening to GroupProvider changes.
class GroupListScreen extends StatelessWidget {
  const GroupListScreen({super.key});

  Future<void> _onRefresh(BuildContext context) async {
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    groupProvider.refresh();
  }

  void _navigateToAddGroup(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.addGroup);
  }

  void _navigateToGroupDetail(BuildContext context, Group group) {
    Navigator.pushNamed(
      context,
      AppRoutes.groupDetail,
      arguments: group,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFE7743),
        title: const Text(
          'Grup',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: Consumer<GroupProvider>(
        builder: (context, groupProvider, child) {
          // Loading state
          if (groupProvider.isLoading && groupProvider.groups.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFE7743),
              ),
            );
          }

          // Error state
          if (groupProvider.errorMessage != null) {
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
                    groupProvider.errorMessage!,
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
          if (groupProvider.groups.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.group_outlined,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Belum ada grup',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tekan tombol + untuk membuat grup',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          // Group list
          return RefreshIndicator(
            color: const Color(0xFFFE7743),
            onRefresh: () => _onRefresh(context),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: groupProvider.groups.length,
              itemBuilder: (context, index) {
                final group = groupProvider.groups[index];
                return _buildGroupCard(context, group);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddGroup(context),
        backgroundColor: const Color(0xFFFE7743),
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildGroupCard(BuildContext context, Group group) {
    final memberCount = group.contactIds.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _navigateToGroupDetail(context, group),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Group Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFFE7743).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.group,
                  color: Color(0xFFFE7743),
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),

              // Group Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.nama,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$memberCount ${memberCount == 1 ? 'anggota' : 'anggota'}',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow Icon
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
