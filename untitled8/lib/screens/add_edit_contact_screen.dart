import 'package:flutter/material.dart';
import '../models/emergency_contact_model.dart';
import '../services/contact_service.dart';

class AddEditContactScreen extends StatefulWidget {
  final EmergencyContactModel? contact;

  const AddEditContactScreen({Key? key, this.contact}) : super(key: key);

  @override
  State<AddEditContactScreen> createState() => _AddEditContactScreenState();
}

class _AddEditContactScreenState extends State<AddEditContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contactService = ContactService();
  
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late String _selectedRelation;
  late bool _isPrimary;
  bool _isLoading = false;

  final List<String> _relations = [
    'Parent', 'Spouse', 'Sibling', 'Friend', 'Relative', 'Doctor', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.contact?.name ?? '');
    _phoneController = TextEditingController(text: widget.contact?.phone ?? '');
    _selectedRelation = widget.contact?.relation ?? 'Friend';
    _isPrimary = widget.contact?.isPrimary ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveContact() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (widget.contact == null) {
        await _contactService.addContact(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          relation: _selectedRelation,
          isPrimary: _isPrimary,
        );
      } else {
        await _contactService.updateContact(
          contactId: widget.contact!.id,
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          relation: _selectedRelation,
          isPrimary: _isPrimary,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contact saved successfully'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: Text(widget.contact == null ? 'Add Contact' : 'Edit Contact'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.redAccent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTextField(_nameController, 'Full Name', Icons.person),
                    const SizedBox(height: 20),
                    _buildTextField(_phoneController, 'Phone Number', Icons.phone, keyboardType: TextInputType.phone),
                    const SizedBox(height: 20),
                    _buildDropdown(),
                    const SizedBox(height: 20),
                    _buildPrimaryToggle(),
                    const SizedBox(height: 40),
                    _buildSaveButton(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60),
        prefixIcon: Icon(icon, color: Colors.redAccent),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white10)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent)),
      ),
      validator: (val) => val == null || val.isEmpty ? 'Please enter $label' : null,
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedRelation,
      dropdownColor: const Color(0xFF1E1E1E),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Relation',
        labelStyle: const TextStyle(color: Colors.white60),
        prefixIcon: const Icon(Icons.people, color: Colors.redAccent),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white10)),
      ),
      items: _relations.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
      onChanged: (val) => setState(() => _selectedRelation = val!),
    );
  }

  Widget _buildPrimaryToggle() {
    return SwitchListTile(
      title: const Text('Primary Contact', style: TextStyle(color: Colors.white)),
      subtitle: const Text('Calls will go to this contact first', style: TextStyle(color: Colors.white54, fontSize: 12)),
      value: _isPrimary,
      activeColor: Colors.redAccent,
      onChanged: (val) => setState(() => _isPrimary = val),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _saveContact,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.redAccent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          widget.contact == null ? 'ADD CONTACT' : 'UPDATE CONTACT',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}
