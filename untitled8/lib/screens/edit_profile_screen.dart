import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import '../services/profile_service.dart';
import '../widgets/profile_avatar.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;

  const EditProfileScreen({Key? key, required this.user}) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProfileService _profileService = ProfileService();
  
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _noteController;
  
  File? _imageFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _phoneController = TextEditingController(text: widget.user.phone);
    _noteController = TextEditingController(text: widget.user.emergencyNote);
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? imageUrl = widget.user.profileImageUrl;
      
      if (_imageFile != null) {
        imageUrl = await _profileService.uploadProfileImage(_imageFile!);
      }

      final updatedUser = UserModel(
        uid: widget.user.uid,
        email: widget.user.email,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        emergencyNote: _noteController.text.trim(),
        profileImageUrl: imageUrl,
        createdAt: widget.user.createdAt,
      );

      await _profileService.updateProfile(updatedUser);
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(title: const Text('Edit Profile'), backgroundColor: Colors.transparent),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Colors.redAccent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _imageFile != null 
                        ? CircleAvatar(radius: 60, backgroundImage: FileImage(_imageFile!))
                        : ProfileAvatar(imageUrl: widget.user.profileImageUrl, radius: 60, onTap: _pickImage),
                    const SizedBox(height: 30),
                    _buildTextField(_nameController, 'Full Name', Icons.person),
                    const SizedBox(height: 20),
                    _buildTextField(_phoneController, 'Phone Number', Icons.phone, keyboardType: TextInputType.phone),
                    const SizedBox(height: 20),
                    _buildTextField(_noteController, 'Emergency Note', Icons.note_add, maxLines: 3),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        child: const Text('Save Changes'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.redAccent),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white24)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent)),
      ),
      validator: (v) => v!.isEmpty ? 'Field cannot be empty' : null,
    );
  }
}
