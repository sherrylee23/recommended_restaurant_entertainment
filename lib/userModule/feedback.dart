import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart'; // REQUIRED
import '../language_provider.dart'; // REQUIRED

class FeedbackPage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const FeedbackPage({super.key, required this.userData});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final TextEditingController _descriptionController = TextEditingController();
  int _rating = 0;
  File? _imageFile;
  bool _isUploading = false;
  final SupabaseClient _supabase = Supabase.instance.client;

  // --- LOGIC PRESERVED ---
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _submitFeedback(LanguageProvider lp) async {
    if (_descriptionController.text.trim().isEmpty || _rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(lp.getString('feedback_error'))), // TRANSLATED
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      String? imageUrl;
      final profileId = widget.userData['id'];

      if (_imageFile != null) {
        final fileName = 'fb_${profileId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await _supabase.storage.from('feedback_images').upload(fileName, _imageFile!);
        imageUrl = _supabase.storage.from('feedback_images').getPublicUrl(fileName);
      }

      await _supabase.from('feedbacks').insert({
        'profile_id': profileId,
        'description': _descriptionController.text.trim(),
        'image_url': imageUrl,
        'rating': _rating,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(lp.getString('feedback_success'))), // TRANSLATED
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lp = Provider.of<LanguageProvider>(context); // Access Provider

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF0F0C29),
      appBar: AppBar(
        title: Text(lp.getString('feedback'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)), // TRANSLATED
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel(lp.getString('rate_experience')), // TRANSLATED
                const SizedBox(height: 10),
                Row(
                  children: List.generate(5, (index) => IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      color: index < _rating ? Colors.amberAccent : Colors.white24,
                      size: 40,
                    ),
                    onPressed: () => setState(() => _rating = index + 1),
                  )),
                ),
                const SizedBox(height: 30),
                _buildLabel(lp.getString('description')), // TRANSLATED (Inherited from l10n)
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: TextField(
                      controller: _descriptionController,
                      maxLines: 4,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: lp.getString('improvement_hint'), // TRANSLATED
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(color: Colors.cyanAccent),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                _buildLabel(lp.getString('attach_image')), // TRANSLATED
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: _imageFile != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.file(_imageFile!, fit: BoxFit.cover),
                    )
                        : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.imagePlus, color: Colors.cyanAccent.withOpacity(0.6), size: 40),
                        const SizedBox(height: 12),
                        Text(lp.getString('click_upload'), style: TextStyle(color: Colors.white.withOpacity(0.4))), // TRANSLATED
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 50),
                _buildSubmitButton(lp), // Pass Provider
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 15,
          decoration: BoxDecoration(
            color: Colors.cyanAccent,
            borderRadius: BorderRadius.circular(5),
            boxShadow: [BoxShadow(color: Colors.cyanAccent.withOpacity(0.5), blurRadius: 6)],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(LanguageProvider lp) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Colors.cyanAccent, Colors.blueAccent, Colors.purpleAccent]),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(color: Colors.cyanAccent.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5)),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isUploading ? null : () => _submitFeedback(lp),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
          child: _isUploading
              ? const SizedBox(height: 25, width: 25, child: CircularProgressIndicator(color: Color(0xFF0F0C29), strokeWidth: 3))
              : Text(lp.getString('submit_feedback'), style: const TextStyle(color: Color(0xFF0F0C29), fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1)), // TRANSLATED
        ),
      ),
    );
  }
}