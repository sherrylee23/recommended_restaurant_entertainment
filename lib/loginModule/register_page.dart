import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart'; // REQUIRED
import '../language_provider.dart'; // REQUIRED

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
  bool _obscurePassword = true;

  final List<String> businessTypes = ['Restaurant', 'Entertainment'];

  @override
  void initState() {
    super.initState();
    isBusiness = widget.initialIsBusiness;
  }

  Future<void> _pickImage() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _ssmFile = File(image.path));
  }

  Future<void> _register(LanguageProvider lp) async {
    setState(() { _isLoading = true; errorText = ""; });
    try {
      if (passwordController.text != confirmPasswordController.text) {
        throw lp.getString('pass_mismatch');
      }

      final supabase = Supabase.instance.client;
      final email = emailController.text.trim();

      if (isBusiness) {
        final existingBiz = await supabase
            .from('business_profiles')
            .select('email')
            .eq('email', email)
            .maybeSingle();

        if (existingBiz != null) throw lp.getString('email_address') + " " + lp.getString('already_exists');

        String ssmValue = regNoController.text.trim();
        if (ssmValue.length != 12 || int.tryParse(ssmValue) == null) {
          throw lp.getString('ssm_digit_error');
        }

        if (_ssmFile == null) throw lp.getString('ssm_photo_error');

        final fileName = 'ssm_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await supabase.storage.from('business_assets').upload(fileName, _ssmFile!);
        final publicUrl = supabase.storage.from('business_assets').getPublicUrl(fileName);

        await supabase.from('business_profiles').insert({
          'business_name': businessNameController.text.trim(),
          'email': email,
          'password': passwordController.text.trim(),
          'register_no': ssmValue,
          'ssm_url': publicUrl,
          'business_type': _selectedType,
          'status': 'pending',
          'role': 'business',
        });
      } else {
        final username = usernameController.text.trim();
        final existingUser = await supabase
            .from('profiles')
            .select('email, username')
            .or('email.eq.$email,username.eq.$username')
            .maybeSingle();

        if (existingUser != null) {
          if (existingUser['email'] == email) throw lp.getString('email_address') + " " + lp.getString('already_exists');
          if (existingUser['username'] == username) throw lp.getString('username') + " " + lp.getString('already_exists');
        }

        await supabase.from('profiles').insert({
          'username': username,
          'name': fullNameController.text.trim(),
          'email': email,
          'password': passwordController.text.trim(),
          'role': 'user',
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(lp.getString('reg_success')), backgroundColor: Colors.green)
        );
        Navigator.pop(context);
      }
    } catch (e) {
      String displayError = e.toString();
      if (displayError.contains("unique_violation")) {
        displayError = lp.getString('already_exists');
      }
      setState(() => errorText = displayError);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lp = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0C29),
      body: Stack(
        children: [
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
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  Text(lp.getString('create_account'),
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2)),
                  const SizedBox(height: 10),
                  Text(lp.getString('join_community'),
                      style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.5))),
                  const SizedBox(height: 40),

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
                        _buildTab(lp.getString('user_tab'), !isBusiness),
                        _buildTab(lp.getString('business_tab'), isBusiness),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

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
                              _input(lp, usernameController, lp.getString('username'), LucideIcons.user),
                              const SizedBox(height: 16),
                              _input(lp, fullNameController, lp.getString('full_name'), LucideIcons.contact),
                              const SizedBox(height: 16),
                            ],
                            _input(lp, emailController, lp.getString('email_address'), LucideIcons.mail),
                            const SizedBox(height: 16),
                            _input(lp, passwordController, lp.getString('new_password'), LucideIcons.lock, pass: true),
                            const SizedBox(height: 16),
                            _input(lp, confirmPasswordController, lp.getString('confirm_password'), LucideIcons.checkCircle, pass: true),
                            const SizedBox(height: 16),

                            if (isBusiness) ...[
                              _input(lp, businessNameController, lp.getString('business_name'), LucideIcons.store),
                              const SizedBox(height: 16),
                              _input(lp, regNoController, lp.getString('ssm_no'), LucideIcons.fileText),
                              const SizedBox(height: 16),

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
                                      ? Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(LucideIcons.imagePlus, color: Colors.cyanAccent),
                                        const SizedBox(height: 8),
                                        Text(lp.getString('upload_ssm'), style: const TextStyle(color: Colors.cyanAccent, fontSize: 12))
                                      ])
                                      : ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_ssmFile!, fit: BoxFit.cover)),
                                ),
                              ),
                            ],

                            if (errorText.isNotEmpty)
                              Padding(padding: const EdgeInsets.only(top: 15),
                                  child: Text(errorText, style: const TextStyle(color: Colors.redAccent, fontSize: 12))),

                            const SizedBox(height: 30),

                            SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: Container(
                                decoration: BoxDecoration(
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
                                  onPressed: _isLoading ? null : () => _register(lp),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                  )
                                      : Text(
                                    lp.getString('register_btn'),
                                    style: const TextStyle(
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
                              text: lp.getString('already_have_acc'),
                              style: TextStyle(color: Colors.white.withOpacity(0.6)),
                              children: [
                                TextSpan(text: lp.getString('login_link'), style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold))
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
        onTap: () => setState(() => isBusiness = (label == "Businesses" || label == "Perniagaan" || label == "商家用户")),
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

  Widget _input(LanguageProvider lp, TextEditingController controller, String hint, IconData icon, {bool pass = false}) {
    return TextField(
      controller: controller,
      obscureText: pass ? _obscurePassword : false,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
        prefixIcon: Icon(icon, color: Colors.cyanAccent, size: 20),
        suffixIcon: pass
            ? IconButton(
          icon: Icon(
            _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
            color: Colors.white54,
            size: 20,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        )
            : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}