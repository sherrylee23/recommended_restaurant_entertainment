import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ReportBusinessPage extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String? businessName;

  const ReportBusinessPage({super.key, required this.userData, this.businessName});

  @override
  State<ReportBusinessPage> createState() => _ReportBusinessPageState();
}

class _ReportBusinessPageState extends State<ReportBusinessPage> {
  final _supabase = Supabase.instance.client;
  final _descriptionController = TextEditingController();
  final _emailController = TextEditingController();

  String? _selectedBusiness;
  final List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;
  bool _isLoadingBusinesses = true;

  List<String> _businessList = [];

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.userData['email'] ?? "";
    _fetchBusinesses();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _fetchBusinesses() async {
    try {
      final data = await _supabase.from('business_profiles').select('business_name');
      if (data != null && mounted) {
        setState(() {
          _businessList = (data as List).map((item) => item['business_name'].toString()).toList();
          // Pre-select if passed from previous page
          if (_businessList.contains(widget.businessName)) {
            _selectedBusiness = widget.businessName;
          }
          _isLoadingBusinesses = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingBusinesses = false);
    }
  }

  Future<void> _pickImages() async {
    final List<XFile> pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        for (var file in pickedFiles) {
          if (_selectedImages.length < 5) { // Safety limit of 5 images
            _selectedImages.add(File(file.path));
          }
        }
      });
    }
  }

  Future<void> _submitReport() async {
    if (_selectedBusiness == null || _descriptionController.text.trim().isEmpty) {
      _showSnackBar("Please select a business and provide details", Colors.orangeAccent);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      List<String> imageUrls = [];

      // Upload multiple images to Supabase Storage
      for (int i = 0; i < _selectedImages.length; i++) {
        final fileName = 'report_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final path = 'public/$fileName';

        await _supabase.storage.from('business_reports').upload(path, _selectedImages[i]);
        final url = _supabase.storage.from('business_reports').getPublicUrl(path);
        imageUrls.add(url);
      }

      // Insert record into Database
      await _supabase.from('business_reports').insert({
        'profile_id': widget.userData['id'],
        'user_email': _emailController.text.trim(),
        'business_name': _selectedBusiness,
        'description': _descriptionController.text.trim(),
        'media_urls': imageUrls, // Ensure your DB column is type JSONB or Text Array
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });

      if (mounted) _showSuccessDialog();
    } catch (e) {
      if (mounted) _showSnackBar("Error: $e", Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnackBar(String m, Color c) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(m), backgroundColor: c, behavior: SnackBarBehavior.floating)
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0C29),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Report Business", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel("Target Business *"),
                _buildGlassCard(
                  _isLoadingBusinesses
                      ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: LinearProgressIndicator(color: Colors.blueAccent, backgroundColor: Colors.white10),
                  )
                      : DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      dropdownColor: const Color(0xFF1A1A35),
                      isExpanded: true,
                      hint: const Text("Select business", style: TextStyle(color: Colors.white38)),
                      value: _selectedBusiness,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      icon: const Icon(LucideIcons.chevronDown, color: Colors.white54, size: 18),
                      items: _businessList.map((value) => DropdownMenuItem(
                          value: value,
                          child: Text(value)
                      )).toList(),
                      onChanged: (val) => setState(() => _selectedBusiness = val),
                    ),
                  ),
                ),

                _buildLabel("Issue Description *"),
                _buildGlassCard(TextField(
                  controller: _descriptionController,
                  maxLines: 4,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Please describe the issue in detail...",
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 14),
                    border: InputBorder.none,
                  ),
                )),

                _buildLabel("Evidence Photos (Max 5)"),
                if (_selectedImages.isNotEmpty) _buildImageStrip(),
                _buildMediaPicker(),

                _buildLabel("Your Contact Email"),
                _buildGlassCard(TextField(
                  controller: _emailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Email for status updates",
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 14),
                    border: InputBorder.none,
                    prefixIcon: const Icon(LucideIcons.mail, color: Colors.blueAccent, size: 18),
                  ),
                )),

                const SizedBox(height: 40),
                _buildSubmitButton(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 10, left: 4, top: 24),
    child: Text(t, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white70)),
  );

  Widget _buildGlassCard(Widget child) => ClipRRect(
    borderRadius: BorderRadius.circular(15),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: child,
      ),
    ),
  );

  Widget _buildImageStrip() => Container(
    height: 90,
    margin: const EdgeInsets.only(bottom: 15),
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: _selectedImages.length,
      itemBuilder: (context, index) => Container(
        margin: const EdgeInsets.only(right: 12),
        width: 90,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(_selectedImages[index], width: 90, height: 90, fit: BoxFit.cover),
            ),
            Positioned(
              top: 5, right: 5,
              child: GestureDetector(
                onTap: () => setState(() => _selectedImages.removeAt(index)),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                  child: const Icon(Icons.close, size: 12, color: Colors.white),
                ),
              ),
            )
          ],
        ),
      ),
    ),
  );

  Widget _buildMediaPicker() => GestureDetector(
    onTap: _pickImages,
    child: Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.camera, color: Colors.blueAccent, size: 20),
          SizedBox(width: 10),
          Text("Add Photos", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
        ],
      ),
    ),
  );

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: _isSubmitting
            ? null
            : const LinearGradient(colors: [Color(0xFF4A90E2), Color(0xFF9B51E0)]),
        color: _isSubmitting ? Colors.white10 : null,
        boxShadow: _isSubmitting
            ? []
            : [BoxShadow(color: Colors.blueAccent.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitReport,
        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
        ),
        child: _isSubmitting
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text("SUBMIT REPORT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AlertDialog(
          backgroundColor: const Color(0xFF1A1A35),
          // FIXED: Changed 'border' to 'side' and used BorderSide
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.white10),
          ),
          title: const Icon(LucideIcons.checkCircle, color: Colors.greenAccent, size: 50),
          content: const Text(
              "Report submitted successfully. Our admin team will review it and notify you via email.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70)
          ),
          actions: [
            Center(
              child: TextButton(
                onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                child: const Text("Done", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}