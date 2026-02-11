import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final usernameController = TextEditingController();
  final businessNameController = TextEditingController();
  final regNoController = TextEditingController();

  File? _ssmFile;
  String _selectedType = 'Restaurant'; // RESTORED: Business Type
  bool _isLoading = false;
  bool isBusiness = false;
  String errorText = "";

  // List for the dropdown
  final List<String> businessTypes = ['Restaurant', 'Entertainment', 'Cafe', 'Other'];

  Future<void> _pickImage() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _ssmFile = File(image.path));
  }

  Future<void> _register() async {
    setState(() { _isLoading = true; errorText = ""; });

    try {
      if (isBusiness) {
        if (_ssmFile == null) throw "Please upload SSM photo";

        final fileName = 'ssm_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await Supabase.instance.client.storage.from('business_assets').upload(fileName, _ssmFile!);
        final publicUrl = Supabase.instance.client.storage.from('business_assets').getPublicUrl(fileName);

        // ID is omitted here so the database handles it automatically
        await Supabase.instance.client.from('business_profiles').insert({
          'business_name': businessNameController.text.trim(),
          'email': emailController.text.trim(),
          'password': passwordController.text.trim(),
          'register_no': regNoController.text.trim(),
          'ssm_url': publicUrl,
          'business_type': _selectedType, // Using the dropdown value
          'status': 'pending',
          'role': 'business',
        });
      } else {
        await Supabase.instance.client.from('profiles').insert({
          'username': usernameController.text.trim(),
          'email': emailController.text.trim(),
          'password': passwordController.text.trim(),
          'role': 'user',
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Registration Successful!"), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => errorText = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade100, Colors.purple.shade50],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Text(
                  "Create Account",
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                ),
                const SizedBox(height: 30),

                // THE TOGGLE SWITCH
                Container(
                  width: 300, height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blueAccent, width: 2),
                  ),
                  child: Row(
                    children: [
                      _buildTab("User", !isBusiness),
                      _buildTab("Businesses", isBusiness),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // FORM CARD
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                  ),
                  child: Column(
                    children: [
                      _input(emailController, "Email", LucideIcons.mail),
                      const SizedBox(height: 15),
                      _input(passwordController, "Password", LucideIcons.lock, pass: true),
                      const SizedBox(height: 15),

                      if (!isBusiness)
                        _input(usernameController, "Username", LucideIcons.user),

                      if (isBusiness) ...[
                        _input(businessNameController, "Business Name", LucideIcons.store),
                        const SizedBox(height: 15),
                        _input(regNoController, "SSM No", LucideIcons.fileText),
                        const SizedBox(height: 15),

                        // RESTORED: Business Type Dropdown
                        DropdownButtonFormField<String>(
                          value: _selectedType,
                          decoration: InputDecoration(
                            hintText: "Business Type",
                            prefixIcon: const Icon(LucideIcons.list, color: Colors.blueAccent),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                          items: businessTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                          onChanged: (val) => setState(() => _selectedType = val!),
                        ),
                        const SizedBox(height: 15),

                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            height: 120, width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.blue.shade100),
                            ),
                            child: _ssmFile == null
                                ? const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(LucideIcons.imagePlus, color: Colors.blueAccent),
                                Text("Upload SSM Photo", style: TextStyle(color: Colors.blueAccent, fontSize: 12)),
                              ],
                            )
                                : ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(_ssmFile!, fit: BoxFit.cover)),
                          ),
                        ),
                      ],

                      if (errorText.isNotEmpty)
                        Padding(padding: const EdgeInsets.only(top: 15), child: Text(errorText, style: const TextStyle(color: Colors.red, fontSize: 12))),

                      const SizedBox(height: 25),

                      SizedBox(
                        width: double.infinity, height: 55,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text("REGISTER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),

                // RESTORED: Back to Login button
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Already have an account? Login", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTab(String label, bool active) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => isBusiness = (label == "Businesses")),
        child: Container(
          decoration: BoxDecoration(
            color: active ? Colors.white.withOpacity(0.7) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        ),
      ),
    );
  }

  Widget _input(TextEditingController controller, String hint, IconData icon, {bool pass = false}) {
    return TextField(
      controller: controller, obscureText: pass,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.blueAccent),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
    );
  }
}