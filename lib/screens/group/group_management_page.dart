import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../providers/group_provider.dart';
import '../../models/group_model.dart';

class GroupManagementPage extends StatelessWidget {
  const GroupManagementPage({super.key});

  void _showGroupDialog(BuildContext context, {Group? group}) {
    final isEditing = group != null;
    final nameController = TextEditingController(text: group?.nama ?? '');
    Color currentColor = group != null
        ? Color(int.parse(group.colorHex.replaceAll('#', '0xFF')))
        : Colors.blue;
    String colorHex = group?.colorHex ?? '#2196F3';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit Group' : 'Add Group'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Group Name',
                  hintText: 'e.g. Work, Family',
                ),
              ),
              SizedBox(height: 20),
              Text('Select Color'),
              SizedBox(height: 10),
              // Simplified color picker
              BlockPicker(
                pickerColor: currentColor,
                availableColors: [
                  Colors.red,
                  Colors.pink,
                  Colors.purple,
                  Colors.deepPurple,
                  Colors.indigo,
                  Colors.blue,
                  Colors.lightBlue,
                  Colors.cyan,
                  Colors.teal,
                  Colors.green,
                  Colors.lightGreen,
                  Colors.lime,
                  Colors.yellow,
                  Colors.amber,
                  Colors.orange,
                  Colors.deepOrange,
                  Colors.brown,
                  Colors.grey,
                  Colors.blueGrey,
                  Colors.black,
                ],
                onColorChanged: (color) {
                  currentColor = color;
                  // Convert Color to Hex string #RRGGBB
                  colorHex =
                      '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;

              final provider = Provider.of<GroupProvider>(
                context,
                listen: false,
              );
              try {
                if (isEditing) {
                  await provider.updateGroup(
                    group.copyWith(nama: name, colorHex: colorHex),
                  );
                } else {
                  await provider.addGroup(name, colorHex);
                }
                if (context.mounted) {
                  Navigator.pop(context);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Manage Groups'), centerTitle: true),
      body: Consumer<GroupProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.groups.isEmpty) {
            return Center(child: CircularProgressIndicator());
          }

          if (provider.groups.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.group_outlined, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No groups yet', style: TextStyle(color: Colors.grey)),
                  SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _showGroupDialog(context),
                    child: Text('Create Group'),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: EdgeInsets.all(16),
            itemCount: provider.groups.length,
            separatorBuilder: (ctx, i) => Divider(),
            itemBuilder: (context, index) {
              final group = provider.groups[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Color(
                    int.parse(group.colorHex.replaceAll('#', '0xFF')),
                  ),
                  radius: 12,
                ),
                title: Text(
                  group.nama,
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _showGroupDialog(context, group: group),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Delete Group?'),
                            content: Text(
                              'Are you sure you want to delete "${group.nama}"? Contacts will loose this tag.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          await provider.deleteGroup(group.id!);
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showGroupDialog(context),
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }
}
