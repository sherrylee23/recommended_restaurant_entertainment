import 'package:image_picker/image_picker.dart';
import 'dart:io'; // FIXED: Added this to resolve the 'File' error
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const EditProfilePage({super.key, required this.userData});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _idController;
  String _selectedGender = "Female";
  bool _isSaving = false;

  // Image variables
  File? _imageFile;
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    _imageUrl = widget.userData['profile_url'];

    // Displays the numeric 'id' (int8) as requested
    _idController = TextEditingController(
      text: widget.userData['id']?.toString() ?? "",
    );

    _usernameController = TextEditingController(
      text: widget.userData['username'] ?? "",
    );
    _emailController = TextEditingController(
      text: widget.userData['email'] ?? "",
    );

    // Safe initialization for gender
    _selectedGender = widget.userData['gender'] ?? "Female";
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return _imageUrl;

    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'profile_pics/$fileName';

      // Upload to your Supabase Storage Bucket
      await Supabase.instance.client.storage
          .from('avatars')
          .upload(path, _imageFile!);

      // Get Public URL to save in database
      final String publicUrl = Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl(path);

      return publicUrl;
    } catch (e) {
      debugPrint("Upload error: $e");
      return null;
    }
  }

  Future<void> _updateProfile() async {
    setState(() => _isSaving = true);
    try {
      final String? newImageUrl = await _uploadImage();

      // Update your manual 'profiles' table
      await Supabase.instance.client
          .from('profiles')
          .update({
            'username': _usernameController.text.trim(),
            'gender': _selectedGender,
            'profile_url': newImageUrl,
          })
          .eq('user_id', widget.userData['user_id']); // Match by UUID

      if (mounted) {
        // Refresh the local data to return it to the profile page
        final updatedData = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('user_id', widget.userData['user_id'])
            .single();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile updated!"),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context, updatedData);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildProfileImagePicker() {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: Colors.white,
          // Correctly handles priority: New File > Existing URL > Default Icon
          backgroundImage: _imageFile != null
              ? FileImage(_imageFile!)
              : (_imageUrl != null ? NetworkImage(_imageUrl!) : null)
                    as ImageProvider?,
          child: (_imageFile == null && _imageUrl == null)
              ? const Icon(Icons.face, size: 90, color: Colors.brown)
              : null,
        ),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.blueAccent,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    required bool enabled,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: !enabled,
          decoration: InputDecoration(
            filled: true,
            fillColor: enabled ? Colors.white : Colors.grey.shade200,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.blue.shade100),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Gender",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.blue.shade100),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedGender,
              isExpanded: true,
              items: ["Male", "Female"].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) =>
                  setState(() => _selectedGender = newValue!),
            ),
          ),
        ),
      ],
    );
  }

  // ... (keep all your imports and existing logic the same)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Added extendBodyBehindAppBar and background gradient to match other pages
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Edit Profile",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        // Make transparent for seamless look
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Colors.blue.shade100, Colors.purple.shade50],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildProfileImagePicker(),
                const SizedBox(height: 30),
                _buildTextField("Username", _usernameController, enabled: true),
                const SizedBox(height: 15),
                _buildGenderDropdown(),
                const SizedBox(height: 15),
                _buildTextField(
                  "Email Address",
                  _emailController,
                  enabled: false,
                ),
                const SizedBox(height: 15),
                _buildTextField(
                  "User ID (Permanent)",
                  _idController,
                  enabled: false,
                ),
                const SizedBox(height: 40),
                _buildSaveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: Container(
        // --- MATCHING THE FEEDBACK SUBMIT BUTTON GRADIENT ---
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF8ECAFF), Color(0xFF4A90E2), Colors.purpleAccent],
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isSaving ? null : _updateProfile,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: _isSaving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  "SAVE CHANGES",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
        ),
      ),
    );
  }
}
