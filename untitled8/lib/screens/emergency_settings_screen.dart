import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/sos_service.dart';

class EmergencySettingsScreen extends StatefulWidget {
  const EmergencySettingsScreen({super.key});

  @override
  State<EmergencySettingsScreen> createState() => _EmergencySettingsScreenState();
}

class _EmergencySettingsScreenState extends State<EmergencySettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _primaryController;
  late TextEditingController _secondary1Controller;
  late TextEditingController _secondary2Controller;

  bool _isLoading = true;
  bool _isSaving = false;
  EmergencyContacts? _cachedContacts;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    // Step 1: Check if we have cached contacts for INSTANT display
    final cached = SOSService.getCachedContacts();

    if (cached != null && mounted) {
      // Show cached contacts immediately (0ms delay)
      setState(() {
        _cachedContacts = cached;
        _primaryController = TextEditingController(text: cached.primary);
        _secondary1Controller = TextEditingController(text: cached.secondary1);
        _secondary2Controller = TextEditingController(text: cached.secondary2);
        _isLoading = false;
      });
    }

    // Step 2: Load fresh data in background (takes ~50ms)
    final freshContacts = await SOSService.getContacts();

    if (mounted && freshContacts != _cachedContacts) {
      setState(() {
        _cachedContacts = freshContacts;
        _primaryController.text = freshContacts.primary;
        _secondary1Controller.text = freshContacts.secondary1;
        _secondary2Controller.text = freshContacts.secondary2;
      });
    }
  }

  Future<void> _saveContacts() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

      final contacts = EmergencyContacts(
        primary: _primaryController.text.trim(),
        secondary1: _secondary1Controller.text.trim(),
        secondary2: _secondary2Controller.text.trim(),
      );

      await SOSService.saveContacts(contacts);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Emergency contacts saved!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
      }

      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Colors.redAccent,
              strokeWidth: 3,
            ),
            SizedBox(height: 16),
            Text(
              'Loading contacts...',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ],
        ),
      )
          : Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Header Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.emergency_share,
                size: 50,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(height: 16),

            // Title
            const Text(
              'Emergency Contacts',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Subtitle
            const Text(
              'SOS will send location to these numbers and dial the primary number',
              style: TextStyle(color: Colors.white54, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Primary Number Field
            _buildNumberField(
              controller: _primaryController,
              label: 'Primary Number (Auto-Dial)',
              hint: 'Enter primary emergency number',
              icon: Icons.phone_forwarded,
              color: Colors.redAccent,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Primary number is required';
                }
                if (value.length < 5) {
                  return 'Enter a valid phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Secondary Number 1 Field
            _buildNumberField(
              controller: _secondary1Controller,
              label: 'Secondary Number 1',
              hint: 'Enter secondary emergency number',
              icon: Icons.people_outline,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),

            // Secondary Number 2 Field
            _buildNumberField(
              controller: _secondary2Controller,
              label: 'Secondary Number 2',
              hint: 'Enter secondary emergency number',
              icon: Icons.people_outline,
              color: Colors.green,
            ),

            const SizedBox(height: 24),

            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[300], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Add country code for international numbers (e.g., +92 for Pakistan)',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveContacts,
                icon: _isSaving
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(Icons.save),
                label: Text(
                  _isSaving ? 'SAVING...' : 'SAVE CONTACTS',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 2,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // How it works section
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📱 How SOS Works',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.touch_app, 'Press SOS button or shake phone'),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.location_on, 'Sends your live location to all contacts'),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.message, 'SMS pre-filled with Google Maps link'),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.phone, 'Auto-dials primary emergency number'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.redAccent),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color color,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        keyboardType: TextInputType.phone,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')), // Allows numbers and plus sign
          LengthLimitingTextInputFormatter(15),
        ],
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white30),
          labelStyle: const TextStyle(color: Colors.white60),
          prefixIcon: Icon(icon, color: color),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: color),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red),
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _primaryController.dispose();
    _secondary1Controller.dispose();
    _secondary2Controller.dispose();
    super.dispose();
  }
}