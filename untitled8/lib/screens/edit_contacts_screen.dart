import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../repositories/contact_repository.dart';
import '../services/auth_service.dart';
import '../widgets/emergency_contact_card.dart';
import '../widgets/custom_dialogs.dart';

class EditContactsScreen extends StatefulWidget {
  const EditContactsScreen({Key? key}) : super(key: key);

  @override
  State<EditContactsScreen> createState() => _EditContactsScreenState();
}

class _EditContactsScreenState extends State<EditContactsScreen> {
  late ContactRepository _contactRepository;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _isPrimary = false;

  @override
  void initState() {
    super.initState();

    final authService =
    Provider.of<AuthService>(context, listen: false);

    _contactRepository =
        ContactRepository(userId: authService.currentUser!.uid);
  }

  void _showAddContactSheet({Map<String, dynamic>? contact}) {
    final TextEditingController nameController =
    TextEditingController(text: contact?['name'] ?? '');

    final TextEditingController phoneController =
    TextEditingController(text: contact?['phone'] ?? '');

    bool isPrimary = contact?['is_primary'] ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 20,
                left: 20,
                right: 20,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFF1C1C1E),
                borderRadius:
                BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    contact == null ? 'Add Contact' : 'Edit Contact',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      labelStyle:
                      const TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  TextField(
                    controller: phoneController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      labelStyle:
                      const TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  CheckboxListTile(
                    title: const Text(
                      'Set as Primary Contact',
                      style: TextStyle(color: Colors.white70),
                    ),
                    value: isPrimary,
                    activeColor: Colors.redAccent,
                    onChanged: (val) {
                      setModalState(() {
                        isPrimary = val!;
                      });
                    },
                  ),

                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                      ),
                      onPressed: () async {
                        final data = {
                          'name': nameController.text.trim(),
                          'phone': phoneController.text.trim(),
                          'is_primary': isPrimary,
                        };

                        if (contact == null) {
                          await _contactRepository.addContact(data);
                          CustomDialogs.showSuccess(
                              context, 'Contact added successfully');
                        } else {
                          await _contactRepository.updateContact(
                              contact['id'], data);
                          CustomDialogs.showSuccess(
                              context, 'Contact updated successfully');
                        }

                        Navigator.pop(context);
                      },
                      child: Text(
                        contact == null ? 'Add' : 'Update',
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
        backgroundColor: Colors.black,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _contactRepository.getContacts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                  color: Colors.redAccent),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No contacts added yet',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          final contacts = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              final contact = contacts[index];

              return EmergencyContactCard(
                name: contact['name'],
                phone: contact['phone'],
                isPrimary: contact['is_primary'] ?? false,
                onEdit: () =>
                    _showAddContactSheet(contact: contact),
                onDelete: () =>
                    CustomDialogs.showConfirmationDialog(
                      context: context,
                      title: 'Delete Contact',
                      content:
                      'Are you sure you want to remove this contact?',
                      onConfirm: () => _contactRepository
                          .deleteContact(contact['id']),
                    ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.redAccent,
        onPressed: () => _showAddContactSheet(),
        child: const Icon(Icons.person_add),
      ),
    );
  }
}