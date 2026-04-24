import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/emergency_contact_model.dart';

class ContactCard extends StatelessWidget {
  final EmergencyContactModel contact;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSetPrimary;

  const ContactCard({
    Key? key,
    required this.contact,
    required this.onEdit,
    required this.onDelete,
    required this.onSetPrimary,
  }) : super(key: key);

  Future<void> _makeCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: const Color(0xFF1E1E1E),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: contact.isPrimary ? Colors.redAccent : Colors.blueGrey,
                radius: 25,
                child: Text(
                  contact.name[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      contact.name,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                  if (contact.isPrimary)
                    const Chip(
                      label: Text('PRIMARY', style: TextStyle(fontSize: 10, color: Colors.white)),
                      backgroundColor: Colors.redAccent,
                      padding: EdgeInsets.zero,
                    ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(contact.phone, style: const TextStyle(color: Colors.white70)),
                  Text(contact.relation, style: const TextStyle(color: Colors.blueAccent, fontSize: 12)),
                ],
              ),
            ),
            const Divider(color: Colors.white24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.call,
                  color: Colors.green,
                  onTap: () => _makeCall(contact.phone),
                  label: 'Call',
                ),
                _buildActionButton(
                  icon: Icons.edit,
                  color: Colors.blue,
                  onTap: onEdit,
                  label: 'Edit',
                ),
                _buildActionButton(
                  icon: Icons.delete,
                  color: Colors.red,
                  onTap: onDelete,
                  label: 'Delete',
                ),
                if (!contact.isPrimary)
                  _buildActionButton(
                    icon: Icons.star,
                    color: Colors.amber,
                    onTap: onSetPrimary,
                    label: 'Set Primary',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String label,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }
}
