import 'dart:io';
import 'dart:async';
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
  String? _selectedLocationId;

  @override
  void initState() {
    super.initState();
    _imageUrl = widget.businessData['profile_url']?.toString();

    // Load existing location_id if available
    _selectedLocationId = widget.businessData['location_id']?.toString();

    _idController = TextEditingController(text: widget.businessData['id']?.toString() ?? "");
    _nameController = TextEditingController(text: widget.businessData['business_name']?.toString() ?? "");
    _addressController = TextEditingController(text: widget.businessData['address']?.toString() ?? "");
    _hoursController = TextEditingController(text: widget.businessData['hours']?.toString() ?? "");
    _phoneController = TextEditingController(text: widget.businessData['phone']?.toString() ?? "");
    _typeController = TextEditingController(text: widget.businessData['business_type']?.toString() ?? "Entertainment");
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _hoursController.dispose();
    _phoneController.dispose();
    _idController.dispose();
    _typeController.dispose();
    super.dispose();
  }

  // --- Location Picker Logic ---
  Future<void> _showLocationPicker() async {
    final TextEditingController modalSearchController = TextEditingController();
    Timer? debounce;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.8,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text("Search Location", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 15),
                      TextField(
                        controller: modalSearchController,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: "Enter building name or address...",
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: modalSearchController.text.isNotEmpty
                              ? IconButton(icon: const Icon(Icons.clear), onPressed: () {
                            modalSearchController.clear();
                            setModalState(() {});
                          })
                              : null,
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                        ),
                        onChanged: (val) {
                          if (debounce?.isActive ?? false) debounce!.cancel();
                          debounce = Timer(const Duration(milliseconds: 500), () {
                            setModalState(() {});
                          });
                        },
                      ),
                      const SizedBox(height: 15),
                      Expanded(
                        child: FutureBuilder<List<Map<String, dynamic>>>(
                          future: _searchLocations(modalSearchController.text),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            final locations = snapshot.data ?? [];

                            return ListView.separated(
                              controller: scrollController,
                              itemCount: locations.length,
                              separatorBuilder: (context, index) => const Divider(),
                              itemBuilder: (context, index) {
                                final loc = locations[index];
                                return ListTile(
                                  leading: const Icon(Icons.location_on, color: Colors.blueAccent),
                                  title: Text(loc['name'] ?? "Unknown", style: const TextStyle(fontWeight: FontWeight.w600)),
                                  subtitle: Text("${loc['address'] ?? ''}, ${loc['area'] ?? ''}"),
                                  onTap: () {
                                    setState(() {
                                      _selectedLocationId = loc['id'].toString();
                                      _addressController.text = loc['name'];
                                    });
                                    Navigator.pop(context);
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _searchLocations(String query) async {
    try {
      var request = Supabase.instance.client.from('locations').select();
      if (query.isNotEmpty) {
        request = request.or('name.ilike.%$query%,address.ilike.%$query%');
      }
      final response = await request.limit(15);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  // --- Image & Save Logic ---
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

      // This will now work after you run the ALTER TABLE SQL command
      await Supabase.instance.client.from('business_profiles').update({
        'address': _addressController.text.trim(),
        'hours': _hoursController.text.trim(),
        'phone': _phoneController.text.trim(),
        'profile_url': finalImageUrl,
        'location_id': _selectedLocationId,
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
                _buildLocationField(),
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

  Widget _buildLocationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Address / Location", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
        const SizedBox(height: 8),
        InkWell(
          onTap: _showLocationPicker,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Colors.blueAccent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _addressController.text.isEmpty ? "Select Location" : _addressController.text,
                    style: TextStyle(
                      color: _addressController.text.isEmpty ? Colors.grey : Colors.black,
                      fontSize: 16,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
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
          gradient: const LinearGradient(colors: [Color(0xFF8ECAFF), Color(0xFF4A90E2), Colors.purpleAccent]),
          borderRadius: BorderRadius.circular(10),
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