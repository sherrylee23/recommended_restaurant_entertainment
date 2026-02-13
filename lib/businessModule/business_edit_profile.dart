import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class BusinessEditProfilePage extends StatefulWidget {
  final Map<String, dynamic> businessData;
  const BusinessEditProfilePage({super.key, required this.businessData});

  @override
  State<BusinessEditProfilePage> createState() => _BusinessEditProfilePageState();
}

class _BusinessEditProfilePageState extends State<BusinessEditProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _hoursController;
  late TextEditingController _phoneController;
  late TextEditingController _idController;
  late TextEditingController _typeController;

  bool _isSaving = false;
  File? _imageFile;
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    _imageUrl = widget.businessData['profile_url']?.toString();

    _idController = TextEditingController(text: widget.businessData['id']?.toString() ?? "");
    _nameController = TextEditingController(text: widget.businessData['business_name']?.toString() ?? "");
    _addressController = TextEditingController(text: widget.businessData['address']?.toString() ?? "");
    _hoursController = TextEditingController(text: widget.businessData['hours']?.toString() ?? "");
    _phoneController = TextEditingController(text: widget.businessData['phone']?.toString() ?? "");
    _typeController = TextEditingController(text: widget.businessData['business_type']?.toString() ?? "Entertainment");
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) setState(() => _imageFile = File(pickedFile.path));
  }

  Future<String?> _uploadImage(String businessId) async {
    if (_imageFile == null) return _imageUrl;
    try {
      final fileName = '$businessId-${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'profile_pics/$fileName';
      // Note: Ensure your bucket name matches (using 'business_assets' as previously discussed)
      await Supabase.instance.client.storage.from('business_assets').upload(path, _imageFile!);
      return Supabase.instance.client.storage.from('business_assets').getPublicUrl(path);
    } catch (e) {
      return _imageUrl;
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      final int numericId = int.parse(_idController.text);
      String? finalImageUrl = await _uploadImage(numericId.toString());

      await Supabase.instance.client.from('business_profiles').update({
        'address': _addressController.text.trim(),
        'hours': _hoursController.text.trim(),
        'phone': _phoneController.text.trim(),
        'profile_url': finalImageUrl,
      }).eq('id', numericId);

      final updated = await Supabase.instance.client.from('business_profiles').select().eq('id', numericId).single();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Business Profile updated!"), backgroundColor: Colors.green),
        );
        Navigator.pop(context, updated);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Edit Business Profile", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
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
                _buildImagePicker(),
                const SizedBox(height: 30),
                _buildTextField("Business Name", _nameController, enabled: false),
                const SizedBox(height: 15),
                _buildTextField("Business Type", _typeController, enabled: false),
                const SizedBox(height: 15),
                _buildTextField("Address", _addressController, enabled: true),
                const SizedBox(height: 15),
                _buildTextField("Hours", _hoursController, enabled: true),
                const SizedBox(height: 15),
                _buildTextField("Phone", _phoneController, enabled: true),
                const SizedBox(height: 15),
                _buildTextField("Business ID (Permanent)", _idController, enabled: false),
                const SizedBox(height: 40),
                _buildSaveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: Colors.white,
          backgroundImage: _imageFile != null
              ? FileImage(_imageFile!)
              : (_imageUrl != null && _imageUrl!.isNotEmpty ? NetworkImage(_imageUrl!) : null) as ImageProvider?,
          child: (_imageFile == null && (_imageUrl == null || _imageUrl!.isEmpty))
              ? const Icon(Icons.store, size: 70, color: Colors.brown)
              : null,
        ),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
            child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {required bool enabled}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: !enabled,
          maxLines: label.contains("Address") ? 3 : 1,
          decoration: InputDecoration(
            filled: true,
            fillColor: enabled ? Colors.white : Colors.grey.shade200,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.blue.shade100),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF8ECAFF), Color(0xFF4A90E2), Colors.purpleAccent],
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isSaving ? null : _saveProfile,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: _isSaving
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text("SAVE CHANGES", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ),
    );
  }
}