import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:recommended_restaurant_entertainment/main.dart';
import 'package:recommended_restaurant_entertainment/loginModule/register_page.dart';
import 'package:recommended_restaurant_entertainment/adminModule/admin_dashboard.dart';
import 'package:recommended_restaurant_entertainment/loginModule/forgotPassword_page.dart';
import 'package:recommended_restaurant_entertainment/businessModule/pending_approval.dart';
import 'package:recommended_restaurant_entertainment/businessModule/business_main_nav.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isLoading = false;
  bool isBusiness = false;
  String errorText = "";

  void _showAdminLoginDialog() {
    final TextEditingController adminEmail = TextEditingController();
    final TextEditingController adminPass = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Admin Authentication"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: adminEmail, decoration: const InputDecoration(labelText: "Admin Email")),
            TextField(controller: adminPass, obscureText: true, decoration: const InputDecoration(labelText: "Password")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final adminData = await Supabase.instance.client
                  .from('admin_profiles').select().eq('email', adminEmail.text.trim()).eq('password', adminPass.text.trim()).maybeSingle();
              if (adminData != null && mounted) {
                Navigator.pop(context);
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AdminDashboard(adminData: adminData)));
              }
            },
            child: const Text("Login"),
          ),
        ],
      ),
    );
  }

  Future<void> _login() async {
    final identifier = emailController.text.trim();
    final password = passwordController.text.trim();
    if (identifier.isEmpty || password.isEmpty) {
      setState(() => errorText = "Please enter your credentials");
      return;
    }
    setState(() { _isLoading = true; errorText = ""; });
    try {
      if (isBusiness) {
        final bizData = await Supabase.instance.client
            .from('business_profiles').select().eq('email', identifier).eq('password', password).maybeSingle();
        if (bizData != null) {
          if (bizData['status'] == 'approved') {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => BusinessMainNavigation(businessData: bizData)));
          } else {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const PendingApprovalPage()));
          }
        } else {
          setState(() => errorText = "Invalid Business Credentials");
        }
      } else {
        final userData = await Supabase.instance.client
            .from('profiles').select().eq('password', password).or('email.eq.$identifier,username.eq.$identifier').maybeSingle();
        if (userData != null && mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MainNavigation(userData: userData)));
        } else {
          setState(() => errorText = "Invalid User Credentials");
        }
      }
    } catch (e) {
      setState(() => errorText = "Error: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity, height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft, end: Alignment.centerRight,
            colors: [Colors.blue.shade100, Colors.purple.shade50],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: 10, right: 10,
                child: IconButton(
                  icon: Icon(LucideIcons.shieldCheck, color: Colors.blueAccent.withOpacity(0.3)),
                  onPressed: _showAdminLoginDialog,
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const Text("Nomi", style: TextStyle(fontSize: 50, fontWeight: FontWeight.bold, color: Colors.blueAccent, fontFamily: 'cursive')),
                      const SizedBox(height: 30),
                      _buildRoleSwitch(),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(25),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))]),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(isBusiness ? "Business Portal" : "Welcome Back", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                            const SizedBox(height: 20),
                            _buildTextField(controller: emailController, hint: isBusiness ? "Business Email" : "Username or Email", icon: isBusiness ? LucideIcons.briefcase : LucideIcons.user),
                            const SizedBox(height: 15),
                            _buildTextField(controller: passwordController, hint: "Password", icon: LucideIcons.lock, isPassword: true),
                            Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordPage())), child: const Text("Forgot password?", style: TextStyle(color: Colors.blueAccent, fontSize: 13)))),
                            if (errorText.isNotEmpty) Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(errorText, style: const TextStyle(color: Colors.red, fontSize: 12))),
                            const SizedBox(height: 10),

                            // RESTORED ORIGINAL GRADIENT BUTTON
                            SizedBox(
                              width: double.infinity, height: 50,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [Color(0xFF8ECAFF), Color(0xFF4A90E2), Colors.purpleAccent]),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _login,
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("LOG IN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      const Text("Don't have an account?", style: TextStyle(color: Colors.black54)),
                      TextButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => RegisterPage(initialIsBusiness: isBusiness)));
                        },
                        child: const Text("CREATE NEW ACCOUNT", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent, decoration: TextDecoration.underline)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSwitch() {
    return Container(
      width: 280, height: 45,
      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 250),
            alignment: isBusiness ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(width: 140, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10))),
          ),
          Row(
            children: [
              Expanded(child: GestureDetector(onTap: () => setState(() => isBusiness = false), child: Center(child: Text("User", style: TextStyle(fontWeight: !isBusiness ? FontWeight.bold : FontWeight.normal, color: !isBusiness ? Colors.blueAccent : Colors.grey))))),
              Expanded(child: GestureDetector(onTap: () => setState(() => isBusiness = true), child: Center(child: Text("Businesses", style: TextStyle(fontWeight: isBusiness ? FontWeight.bold : FontWeight.normal, color: isBusiness ? Colors.blueAccent : Colors.grey))))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String hint, required IconData icon, bool isPassword = false}) {
    return TextField(
      controller: controller, obscureText: isPassword,
      decoration: InputDecoration(hintText: hint, prefixIcon: Icon(icon, color: Colors.blueAccent), filled: true, fillColor: Colors.grey.shade50, enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.blue.shade100)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.blueAccent))),
    );
  }
}