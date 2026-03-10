import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart'; // REQUIRED
import '../language_provider.dart'; // REQUIRED

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

  File? _imageFile;
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    _imageUrl = widget.userData['profile_url']?.toString();
    _idController = TextEditingController(text: widget.userData['id']?.toString() ?? "");
    _usernameController = TextEditingController(text: widget.userData['username']?.toString() ?? "");
    _emailController = TextEditingController(text: widget.userData['email']?.toString() ?? "");

    final rawGender = widget.userData['gender']?.toString();
    if (rawGender == "Male" || rawGender == "Female") {
      _selectedGender = rawGender!;
    } else {
      _selectedGender = "Female";
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _imageFile = File(image.path));
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return _imageUrl;
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'profile_pics/$fileName';
      await Supabase.instance.client.storage.from('avatars').upload(path, _imageFile!);
      return Supabase.instance.client.storage.from('avatars').getPublicUrl(path);
    } catch (e) {
      debugPrint("Upload error: $e");
      return _imageUrl;
    }
  }

  Future<void> _updateProfile(LanguageProvider lp) async {
    setState(() => _isSaving = true);
    try {
      final String? newImageUrl = await _uploadImage();
      final identifier = widget.userData['user_id'] ?? widget.userData['id'];

      await Supabase.instance.client.from('profiles').update({
        'username': _usernameController.text.trim(),
        'gender': _selectedGender,
        'profile_url': newImageUrl,
      }).eq(widget.userData['user_id'] != null ? 'user_id' : 'id', identifier);

      if (mounted) {
        final updatedData = await Supabase.instance.client.from('profiles').select().eq(widget.userData['user_id'] != null ? 'user_id' : 'id', identifier).single();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(lp.getString('profile_updated')),
            backgroundColor: Colors.green
        ));
        Navigator.pop(context, updatedData);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("${lp.getString('update_failed')}: ${e.toString()}"),
          backgroundColor: Colors.red
      ));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lp = Provider.of<LanguageProvider>(context); // Access Provider

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF0F0C29),
      appBar: AppBar(
        title: Text(lp.getString('edit_profile'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
            child: Column(
              children: [
                _buildProfileImagePicker(),
                const SizedBox(height: 40),
                _buildTextField(lp.getString('username'), _usernameController, enabled: true, icon: LucideIcons.user),
                const SizedBox(height: 20),
                _buildGenderDropdown(lp),
                const SizedBox(height: 20),
                _buildTextField(lp.getString('email_address'), _emailController, enabled: false, icon: LucideIcons.mail),
                const SizedBox(height: 20),
                _buildTextField(lp.getString('user_id'), _idController, enabled: false, icon: LucideIcons.contact),
                const SizedBox(height: 50),
                _buildSaveButton(lp),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImagePicker() {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(colors: [Colors.cyanAccent, Colors.purpleAccent]),
            boxShadow: [BoxShadow(color: Colors.cyanAccent.withOpacity(0.2), blurRadius: 20)],
          ),
          child: CircleAvatar(
            radius: 65,
            backgroundColor: const Color(0xFF1A1A35),
            backgroundImage: _imageFile != null
                ? FileImage(_imageFile!)
                : (_imageUrl != null && _imageUrl!.isNotEmpty ? NetworkImage(_imageUrl!) : null) as ImageProvider?,
            child: (_imageFile == null && (_imageUrl == null || _imageUrl!.isEmpty))
                ? const Icon(LucideIcons.user, size: 60, color: Colors.white24)
                : null,
          ),
        ),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.cyanAccent,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10)],
            ),
            child: const Icon(LucideIcons.camera, color: Color(0xFF0F0C29), size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {required bool enabled, required IconData icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.5), fontSize: 13, letterSpacing: 0.5)),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: TextField(
              controller: controller,
              readOnly: !enabled,
              style: TextStyle(color: enabled ? Colors.white : Colors.white.withOpacity(0.3)),
              decoration: InputDecoration(
                prefixIcon: Icon(icon, size: 18, color: enabled ? Colors.cyanAccent : Colors.white24),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: Colors.cyanAccent, width: 1),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderDropdown(LanguageProvider lp) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(lp.getString('gender'), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.5), fontSize: 13)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedGender,
              isExpanded: true,
              dropdownColor: const Color(0xFF1A1A35),
              style: const TextStyle(color: Colors.white, fontSize: 16),
              icon: const Icon(LucideIcons.chevronDown, color: Colors.cyanAccent, size: 18),
              items: [
                DropdownMenuItem(value: "Male", child: Text(lp.getString('male'))),
                DropdownMenuItem(value: "Female", child: Text(lp.getString('female'))),
              ],
              onChanged: (newValue) => setState(() => _selectedGender = newValue!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(LanguageProvider lp) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Colors.cyanAccent, Colors.blueAccent, Colors.purpleAccent]),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.cyanAccent.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: ElevatedButton(
          onPressed: _isSaving ? null : () => _updateProfile(lp),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
          child: _isSaving
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Color(0xFF0F0C29), strokeWidth: 3))
              : Text(lp.getString('save_changes'), style: const TextStyle(color: Color(0xFF0F0C29), fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1)),
        ),
      ),
    );
  }
}