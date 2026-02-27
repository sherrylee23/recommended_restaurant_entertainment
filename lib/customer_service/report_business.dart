import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

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
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;
  bool _isLoadingBusinesses = true;

  List<String> _businessList = [];

  // inside _ReportBusinessPageState
  @override
  void initState() {
    super.initState();
    _emailController.text = widget.userData['email'] ?? "";
    // Don't set _selectedBusiness here yet, wait for the list to load
    _fetchBusinesses();
  }

  Future<void> _fetchBusinesses() async {
    try {
      final data = await _supabase
          .from('business_profiles')
          .select('business_name');

      if (data != null && mounted) {
        setState(() {
          _businessList = (data as List)
              .map((item) => item['business_name'].toString())
              .toList();

          // Validation: Only set the selected business if it exists in the fetched list
          if (_businessList.contains(widget.businessName)) {
            _selectedBusiness = widget.businessName;
          } else {
            _selectedBusiness = null; // Default to null if "Plaza Restaurant" isn't found
          }

          _isLoadingBusinesses = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingBusinesses = false);
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _submitReport() async {
    if (_selectedBusiness == null || _descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a business and provide a description")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      String? imageUrl;

      if (_imageFile != null) {
        final fileName = 'report_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final path = 'public/$fileName';

        await _supabase.storage.from('business_reports').upload(path, _imageFile!);
        imageUrl = _supabase.storage.from('business_reports').getPublicUrl(path);
      }

      // 2. 插入举报记录到数据库 [cite: 37]
      await _supabase.from('business_reports').insert({
        'profile_id': widget.userData['id'],
        'user_email': _emailController.text.trim(),
        'business_name': _selectedBusiness,
        'description': _descriptionController.text.trim(),
        'media_url': imageUrl,
        'status': 'pending',
      });

      if (mounted) _showSuccessDialog();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
          title: const Text("Report Business", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
              onPressed: () => Navigator.pop(context),
    ),
    ),
    body: Container(
    width: double.infinity,
    height: double.infinity,
    decoration: BoxDecoration(
    gradient: LinearGradient(
    colors: [Colors.blue.shade100, Colors.purple.shade50],
    ),
    ),
    child: SafeArea(
    child: SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
    children: [
    // 动态加载的商家选择卡片
    _buildFormCard(
    "Target Business",
    _isLoadingBusinesses
    ? const LinearProgressIndicator() // 加载时显示进度条
        : DropdownButtonHideUnderline(
    child: DropdownButton<String>(
    isExpanded: true,
    hint: const Text("Select a business from system"),
    value: _selectedBusiness,
    items: _businessList.map((String value) {
    return DropdownMenuItem<String>(
    value: value,
    child: Text(value, style: const TextStyle(fontSize: 16)),
    );
    }).toList(),
    onChanged: (newValue) => setState(() => _selectedBusiness = newValue),
    ),
    ),
    ),

    _buildFormCard("Issue Description", TextField(
    controller: _descriptionController,
    maxLines: 5,
    decoration: const InputDecoration(hintText: "Enter details here...", border: InputBorder.none),
    )),

    _buildFormCard("Evidence Photo", GestureDetector(
    onTap: _pickImage,
    child: Container(
    width: double.infinity,
    height: 150,
    decoration: BoxDecoration(
    color: Colors.white.withOpacity(0.5),
    borderRadius: BorderRadius.circular(10),
    border: Border.all(color: Colors.grey.shade300),
    ),
    child: _imageFile != null
    ? ClipRRect(
    borderRadius: BorderRadius.circular(10),
    child: Image.file(_imageFile!, fit: BoxFit.cover),
    )
        : Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: const [
    Icon(Icons.add_a_photo_outlined, size: 40, color: Colors.grey),
    SizedBox(height: 8),
    Text("Click to upload photo", style: TextStyle(color: Colors.grey)),
    ],
    ),
    ),
    )),

    _buildFormCard("Contact Email", TextField(
    controller: _emailController,
    decoration: const InputDecoration(hintText: "abc@gmail.com", border: InputBorder.none),
    )),

    const SizedBox(height: 30),
    _buildSubmitButton(),
    ],
    ),
    ),
    ),
    ),
    );
  }

  Widget _buildFormCard(String label, Widget child) {
    return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
    color: Colors.white.withOpacity(0.85),
    borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black54)),
    const SizedBox(height: 10),
    child,
    ],
    ),
    );
  }

  Widget _buildSubmitButton() {
    return InkWell(
        onTap: _isSubmitting ? null : _submitReport,
        child: Container(
        height: 55,
        alignment: Alignment.center,
        decoration: BoxDecoration(
    gradient: const LinearGradient(
    colors: [Color(0xFF8ECAFF), Color(0xFF4A90E2), Colors.purpleAccent],
    ),
    borderRadius: BorderRadius.circular(15),
    boxShadow: [BoxShadow(color: Colors.purple.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))],
    ),
    child: _isSubmitting
    ? const CircularProgressIndicator(color: Colors.white)
        : const Text("Submit Report", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
    ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Success"),
        content: const Text("Your report has been submitted."),
        actions: [
          TextButton(
              onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
              child: const Text("OK")
          ),
        ],
      ),
    );
  }
}