import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:lucide_icons/lucide_icons.dart';
import 'database.dart'; // Ensure this matches your filename

class UserEditProfile extends StatefulWidget {
  const UserEditProfile({super.key});

  @override
  State<UserEditProfile> createState() => _UserEditProfileState();
}

class _UserEditProfileState extends State<UserEditProfile> {
  File? _image;
  final _picker = ImagePicker();

  // Controllers to handle text input
  final TextEditingController _usernameController = TextEditingController(text: "windy0303");
  String _selectedGender = "Female";

  // Fixed values that are restricted
  final String _id = "12345678";
  final String _fullName = "Windy Tan";
  final String _email = "windy0303@example.com";

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  // --- SAVE TO SQLITE LOGIC ---
  Future<void> _handleLocalSave() async {
    Map<String, dynamic> profileData = {
      'id': _id,
      'username': _usernameController.text,
      'gender': _selectedGender,
      'fullname': _fullName,
      'email': _email,
    };

    // Calls the save function in your database.dart file
    await DBHelper.instance.saveProfile(profileData);

    if (mounted) {
      // Returns 'true' so the previous screen knows it needs to refresh
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Edit Profile", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: _handleLocalSave, // FIXED: Now it calls the save logic
            child: const Text("Save", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 16)),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // --- Profile Photo Edit ---
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: _image != null
                        ? FileImage(_image!)
                        : const NetworkImage('https://api.dicebear.com/7.x/avataaars/png?seed=windy') as ImageProvider,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                        child: const Icon(LucideIcons.camera, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            _buildReadOnlyField("ID", _id),
            const SizedBox(height: 25),

            _buildLabel("Username"),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                hintText: "Enter username",
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black)),
              ),
            ),
            const SizedBox(height: 25),

            _buildLabel("Gender"),
            DropdownButton<String>(
              isExpanded: true,
              value: _selectedGender,
              items: <String>['Male', 'Female'].map((String value) {
                return DropdownMenuItem<String>(value: value, child: Text(value));
              }).toList(),
              onChanged: (newValue) => setState(() => _selectedGender = newValue!),
            ),
            const SizedBox(height: 25),

            _buildReadOnlyField("Full Name", _fullName),
            const SizedBox(height: 25),

            _buildReadOnlyField("Email Address", _email),
          ],
        ),
      ),
    );
  }

  // UI Helpers to keep code clean
  Widget _buildLabel(String text) => Align(
    alignment: Alignment.centerLeft,
    child: Text(text, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
  );

  Widget _buildReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 16, color: Colors.black54)),
        const Divider(color: Colors.grey),
      ],
    );
  }
}