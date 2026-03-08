import 'dart:io';
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

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

  // --- LOGIC PRESERVED: Location Picker ---
  Future<void> _showLocationPicker() async {
    final TextEditingController modalSearchController = TextEditingController();
    Timer? debounce;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A35).withOpacity(0.9),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: DraggableScrollableSheet(
                  initialChildSize: 0.8,
                  minChildSize: 0.5,
                  maxChildSize: 0.95,
                  expand: false,
                  builder: (context, scrollController) {
                    return Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          const Text("Search Location", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 20),
                          TextField(
                            controller: modalSearchController,
                            autofocus: true,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: "Enter building name...",
                              hintStyle: const TextStyle(color: Colors.white24),
                              prefixIcon: const Icon(LucideIcons.search, color: Colors.cyanAccent),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.05),
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
                                  return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
                                }
                                final locations = snapshot.data ?? [];
                                return ListView.separated(
                                  controller: scrollController,
                                  itemCount: locations.length,
                                  separatorBuilder: (context, index) => Divider(color: Colors.white.withOpacity(0.05)),
                                  itemBuilder: (context, index) {
                                    final loc = locations[index];
                                    return ListTile(
                                      leading: const Icon(LucideIcons.mapPin, color: Colors.cyanAccent),
                                      title: Text(loc['name'] ?? "Unknown", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                      subtitle: Text("${loc['address'] ?? ''}, ${loc['area'] ?? ''}", style: const TextStyle(color: Colors.white38, fontSize: 12)),
                                      onTap: () {
                                        setState(() {
                                          _selectedLocationId = loc['id'].toString();

                                          // Option A: Show only the detailed address
                                          // _addressController.text = loc['address'] ?? '';

                                          // Option B: Show Name + Address (Recommended for clarity)
                                          _addressController.text = "${loc['name']} - ${loc['address']}";
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
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _searchLocations(String query) async {
    try {
      var request = Supabase.instance.client.from('locations2').select();
      if (query.isNotEmpty) request = request.or('name.ilike.%$query%,address.ilike.%$query%');
      final response = await request.limit(15);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  // --- LOGIC PRESERVED: Image & Save ---
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

      await Supabase.instance.client.from('business_profiles').update({
        'address': _addressController.text.trim(),
        'hours': _hoursController.text.trim(),
        'phone': _phoneController.text.trim(),
        'profile_url': finalImageUrl,
        'location_id': _selectedLocationId,
      }).eq('id', numericId);

      final updated = await Supabase.instance.client.from('business_profiles').select().eq('id', numericId).single();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile updated!"), backgroundColor: Colors.green));
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
      backgroundColor: const Color(0xFF0F0C29),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Edit Business Info", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF0F0C29), Color(0xFF302B63)]),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(25),
            child: Column(
              children: [
                _buildModernImagePicker(),
                const SizedBox(height: 40),
                _buildGlassTextField("Business Name", _nameController, enabled: false, icon: LucideIcons.store),
                const SizedBox(height: 15),
                _buildGlassTextField("Business Type", _typeController, enabled: false, icon: LucideIcons.tag),
                const SizedBox(height: 15),
                _buildLocationField(),
                const SizedBox(height: 15),
                _buildGlassTextField("Operational Hours", _hoursController, enabled: true, icon: LucideIcons.clock),
                const SizedBox(height: 15),
                _buildGlassTextField("Contact Number", _phoneController, enabled: true, icon: LucideIcons.phone),
                const SizedBox(height: 15),
                _buildGlassTextField("Internal ID (Read-only)", _idController, enabled: false, icon: LucideIcons.contact),
                const SizedBox(height: 40),
                _buildNeonSaveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernImagePicker() {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [Colors.cyanAccent, Colors.purpleAccent]), boxShadow: [BoxShadow(color: Colors.cyanAccent.withOpacity(0.2), blurRadius: 20)]),
          child: CircleAvatar(
            radius: 60,
            backgroundColor: const Color(0xFF1A1A35),
            backgroundImage: _imageFile != null
                ? FileImage(_imageFile!)
                : (_imageUrl != null && _imageUrl!.isNotEmpty ? NetworkImage(_imageUrl!) : null) as ImageProvider?,
            child: (_imageFile == null && (_imageUrl == null || _imageUrl!.isEmpty))
                ? const Icon(LucideIcons.store, size: 50, color: Colors.white24)
                : null,
          ),
        ),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(color: Colors.cyanAccent, shape: BoxShape.circle),
            child: const Icon(LucideIcons.camera, color: Color(0xFF0F0C29), size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassTextField(String label, TextEditingController controller, {required bool enabled, required IconData icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.only(left: 4, bottom: 8), child: Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13, fontWeight: FontWeight.bold))),
        TextField(
          controller: controller,
          readOnly: !enabled,
          style: TextStyle(color: enabled ? Colors.white : Colors.white38),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: enabled ? Colors.cyanAccent : Colors.white10, size: 18),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.cyanAccent)),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.only(left: 4, bottom: 8), child: Text("Location", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13, fontWeight: FontWeight.bold))),
        InkWell(
          onTap: _showLocationPicker,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.mapPin, color: Colors.cyanAccent, size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _addressController.text.isEmpty ? "Find your location..." : _addressController.text,
                    style: TextStyle(color: _addressController.text.isEmpty ? Colors.white24 : Colors.white, fontSize: 16),
                  ),
                ),
                const Icon(LucideIcons.chevronRight, color: Colors.white24, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNeonSaveButton() {
    return InkWell(
      onTap: _isSaving ? null : _saveProfile,
      child: Container(
        width: double.infinity,
        height: 55,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(colors: [Colors.cyanAccent, Colors.blueAccent, Colors.purpleAccent]),
          boxShadow: [BoxShadow(color: Colors.cyanAccent.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: Center(
          child: _isSaving
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Color(0xFF0F0C29), strokeWidth: 2))
              : const Text("UPDATE PROFILE", style: TextStyle(color: Color(0xFF0F0C29), fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        ),
      ),
    );
  }
}