import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';

class RegisterPage extends StatefulWidget {
  final bool initialIsBusiness;
  const RegisterPage({super.key, this.initialIsBusiness = false});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final usernameController = TextEditingController();
  final fullNameController = TextEditingController();
  final businessNameController = TextEditingController();
  final regNoController = TextEditingController();

  File? _ssmFile;
  String _selectedType = 'Restaurant';
  bool _isLoading = false;
  late bool isBusiness;
  String errorText = "";

  final List<String> businessTypes = ['Restaurant', 'Entertainment'];

  @override
  void initState() {
    super.initState();
    isBusiness = widget.initialIsBusiness;
  }

  // --- Logic Preserved ---
  Future<void> _pickImage() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _ssmFile = File(image.path));
  }

  // --- Logic Preserved ---
  Future<void> _register() async {
    setState(() { _isLoading = true; errorText = ""; });
    try {
      if (passwordController.text != confirmPasswordController.text) {
        throw "Passwords do not match";
      }

      if (isBusiness) {
        // --- SSM Validation Start ---
        String ssmValue = regNoController.text.trim();
        if (ssmValue.length != 12 || int.tryParse(ssmValue) == null) {
          throw "SSM Number must be exactly 12 digits";
        }
        // --- SSM Validation End ---

        if (_ssmFile == null) throw "Please upload SSM photo";

        final fileName = 'ssm_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await Supabase.instance.client.storage.from('business_assets').upload(fileName, _ssmFile!);
        final publicUrl = Supabase.instance.client.storage.from('business_assets').getPublicUrl(fileName);

        await Supabase.instance.client.from('business_profiles').insert({
          'business_name': businessNameController.text.trim(),
          'email': emailController.text.trim(),
          'password': passwordController.text.trim(),
          'register_no': ssmValue, // Using the validated string
          'ssm_url': publicUrl,
          'business_type': _selectedType,
          'status': 'pending',
          'role': 'business',
        });
      } else {
        await Supabase.instance.client.from('profiles').insert({
          'username': usernameController.text.trim(),
          'name': fullNameController.text.trim(),
          'email': emailController.text.trim(),
          'password': passwordController.text.trim(),
          'role': 'user',
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Registration Successful!"), backgroundColor: Colors.green)
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
      backgroundColor: const Color(0xFF0F0C29),
      body: Stack(
        children: [
          // 1. CONTINUOUS BACKGROUND
          Container(
            width: double.infinity, height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
              ),
            ),
          ),

          // 2. CONTENT
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  const Text("Create Account",
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2)),
                  const SizedBox(height: 10),
                  Text("Join our exclusive community",
                      style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.5))),
                  const SizedBox(height: 40),

                  // User / Business Toggle Tab (Glassmorphism Style)
                  Container(
                    width: 300, height: 50,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Row(
                      children: [
                        _buildTab("User", !isBusiness),
                        _buildTab("Businesses", isBusiness),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Glass Form Container
                  ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Column(
                          children: [
                            if (!isBusiness) ...[
                              _input(usernameController, "Username", LucideIcons.user),
                              const SizedBox(height: 16),
                              _input(fullNameController, "Full Name", LucideIcons.contact),
                              const SizedBox(height: 16),
                            ],
                            _input(emailController, "Email", LucideIcons.mail),
                            const SizedBox(height: 16),
                            _input(passwordController, "Password", LucideIcons.lock, pass: true),
                            const SizedBox(height: 16),
                            _input(confirmPasswordController, "Confirm Password", LucideIcons.checkCircle, pass: true),
                            const SizedBox(height: 16),

                            if (isBusiness) ...[
                              _input(businessNameController, "Business Name", LucideIcons.store),
                              const SizedBox(height: 16),
                              _input(regNoController, "SSM No", LucideIcons.fileText),
                              const SizedBox(height: 16),

                              // Business Type Selection
                              DropdownButtonFormField<String>(
                                value: _selectedType,
                                dropdownColor: const Color(0xFF1A1A35),
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                    prefixIcon: const Icon(LucideIcons.list, color: Colors.cyanAccent),
                                    filled: true, fillColor: Colors.white.withOpacity(0.05),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
                                ),
                                items: businessTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                                onChanged: (val) => setState(() => _selectedType = val!),
                              ),
                              const SizedBox(height: 16),

                              GestureDetector(
                                onTap: _pickImage,
                                child: Container(
                                  height: 120, width: double.infinity,
                                  decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.03),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.white.withOpacity(0.1), style: BorderStyle.solid)
                                  ),
                                  child: _ssmFile == null
                                      ? const Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(LucideIcons.imagePlus, color: Colors.cyanAccent),
                                        SizedBox(height: 8),
                                        Text("Upload SSM Photo", style: TextStyle(color: Colors.cyanAccent, fontSize: 12))
                                      ])
                                      : ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_ssmFile!, fit: BoxFit.cover)),
                                ),
                              ),
                            ],

                            if (errorText.isNotEmpty)
                              Padding(padding: const EdgeInsets.only(top: 15),
                                  child: Text(errorText, style: const TextStyle(color: Colors.redAccent, fontSize: 12))),

                            const SizedBox(height: 30),

                            // Register Button
                            // Consistent Gradient Button (Matches Login)
                            SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: Container(
                                decoration: BoxDecoration(
                                  // EXACT same gradient colors as your login button
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF8ECAFF), Color(0xFF4A90E2), Colors.purpleAccent],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF4A90E2).withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _register,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent, // Required to show the gradient
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                  )
                                      : const Text(
                                    "REGISTER",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: RichText(
                          text: TextSpan(
                              text: "Already have an account? ",
                              style: TextStyle(color: Colors.white.withOpacity(0.6)),
                              children: const [
                                TextSpan(text: "Login", style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold))
                              ]
                          )
                      )
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, bool active) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => isBusiness = (label == "Businesses")),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
              color: active ? Colors.cyanAccent : Colors.transparent,
              borderRadius: BorderRadius.circular(12)
          ),
          alignment: Alignment.center,
          child: Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: active ? const Color(0xFF0F0C29) : Colors.white70
              )
          ),
        ),
      ),
    );
  }

  Widget _input(TextEditingController controller, String hint, IconData icon, {bool pass = false}) {
    return TextField(
      controller: controller,
      obscureText: pass,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
        prefixIcon: Icon(icon, color: Colors.cyanAccent, size: 20),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}