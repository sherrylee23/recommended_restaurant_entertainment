import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import 'package:recommended_restaurant_entertainment/main.dart';
import 'package:recommended_restaurant_entertainment/loginModule/register_page.dart';
import 'package:recommended_restaurant_entertainment/adminModule/admin_dashboard.dart';
import 'package:recommended_restaurant_entertainment/loginModule/forgotPassword_page.dart';
import 'package:recommended_restaurant_entertainment/businessModule/pending_approval.dart';
import 'package:recommended_restaurant_entertainment/businessModule/business_main_nav.dart';
import '../language_provider.dart'; // REQUIRED

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
  bool _obscurePassword = true;
  String errorText = "";

  void _showAdminLoginDialog(LanguageProvider lp) {
    final TextEditingController adminEmail = TextEditingController();
    final TextEditingController adminPass = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: const Color(0xFF1A1A35).withOpacity(0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
            side: BorderSide(color: Colors.cyanAccent.withOpacity(0.2)),
          ),
          title: Row(
            children: [
              const Icon(LucideIcons.shieldCheck, color: Colors.cyanAccent),
              const SizedBox(width: 10),
              Text(
                lp.getString('admin_portal'),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                lp.getString('restricted_access'),
                style: const TextStyle(color: Colors.white60, fontSize: 13),
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: adminEmail,
                hint: lp.getString('admin_email'),
                icon: LucideIcons.mail,
              ),
              const SizedBox(height: 15),
              _buildTextField(
                controller: adminPass,
                hint: lp.getString('password'),
                icon: LucideIcons.lock,
                isPassword: true,
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                lp.getString('cancel'),
                style: TextStyle(color: Colors.white.withOpacity(0.5)),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Colors.cyanAccent, Colors.blueAccent]),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.cyanAccent.withOpacity(0.2), blurRadius: 10)],
              ),
              child: ElevatedButton(
                onPressed: () async {
                  final adminData = await Supabase.instance.client
                      .from('admin_profiles')
                      .select()
                      .eq('email', adminEmail.text.trim())
                      .eq('password', adminPass.text.trim())
                      .maybeSingle();

                  if (adminData != null && mounted) {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => AdminDashboard(adminData: adminData)),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(lp.getString('invalid_admin')), backgroundColor: Colors.redAccent),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  lp.getString('access_btn'),
                  style: const TextStyle(color: Color(0xFF0F0C29), fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _login(LanguageProvider lp) async {
    final identifier = emailController.text.trim();
    final password = passwordController.text.trim();
    if (identifier.isEmpty || password.isEmpty) {
      setState(() => errorText = lp.getString('enter_credentials'));
      return;
    }
    setState(() { _isLoading = true; errorText = ""; });
    try {
      if (isBusiness) {
        final bizData = await Supabase.instance.client
            .from('business_profiles')
            .select()
            .eq('email', identifier)
            .eq('password', password)
            .maybeSingle();

        if (bizData != null) {
          final String status = bizData['status'] ?? 'pending';
          final String? reason = bizData['reject_reason'];

          if (status == 'inactive') {
            if (mounted) _showAccountDisabledDialog(lp);
          } else if (status == 'approved') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => BusinessMainNavigation(businessData: bizData)),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PendingApprovalPage(status: status, rejectReason: reason)),
            );
          }
        } else {
          setState(() => errorText = lp.getString('invalid_biz_cred'));
        }
      } else {
        final userData = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('password', password)
            .or('email.eq.$identifier,username.eq.$identifier')
            .maybeSingle();
        if (userData != null && mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => MainNavigation(userData: userData)),
          );
        } else {
          setState(() => errorText = lp.getString('invalid_user_cred'));
        }
      }
    } catch (e) {
      setState(() => errorText = "Error: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAccountDisabledDialog(LanguageProvider lp) {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: const Color(0xFF1A1A35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.redAccent, width: 0.5),
          ),
          title: Row(
            children: [
              const Icon(LucideIcons.alertTriangle, color: Colors.redAccent),
              const SizedBox(width: 10),
              Text(lp.getString('access_denied'), style: const TextStyle(color: Colors.white)),
            ],
          ),
          content: Text(
            lp.getString('deactivated_msg'),
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                lp.getString('close'),
                style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lp = Provider.of<LanguageProvider>(context);
    Color glassColor = Colors.white.withOpacity(0.12);
    Color borderColor = Colors.white.withOpacity(0.2);

    return Scaffold(
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
          child: Stack(
            children: [
              Positioned(
                top: 10,
                right: 10,
                child: IconButton(
                  icon: Icon(LucideIcons.shieldCheck, color: Colors.white.withOpacity(0.3)),
                  onPressed: () => _showAdminLoginDialog(lp),
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.1), blurRadius: 30)],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: Image.asset('assets/nomi_logo.jpeg', height: 110, width: 110, fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(height: 30),
                      _buildRoleSwitch(lp),
                      const SizedBox(height: 25),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: Container(
                            padding: const EdgeInsets.all(30),
                            decoration: BoxDecoration(
                              color: glassColor,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: borderColor, width: 1.5),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isBusiness ? lp.getString('biz_portal') : lp.getString('welcome_back'),
                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                const SizedBox(height: 25),
                                _buildTextField(
                                  controller: emailController,
                                  hint: isBusiness ? lp.getString('biz_email') : lp.getString('username_email'),
                                  icon: isBusiness ? LucideIcons.briefcase : LucideIcons.user,
                                ),
                                const SizedBox(height: 20),
                                _buildTextField(
                                  controller: passwordController,
                                  hint: lp.getString('password'),
                                  icon: LucideIcons.lock,
                                  isPassword: true,
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordPage())),
                                    child: Text(lp.getString('forgot_password'), style: const TextStyle(color: Colors.white60, fontSize: 13)),
                                  ),
                                ),
                                if (errorText.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Text(errorText, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                                  ),
                                const SizedBox(height: 15),
                                InkWell(
                                  onTap: _isLoading ? null : () => _login(lp),
                                  child: Container(
                                    width: double.infinity,
                                    height: 55,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(15),
                                      gradient: const LinearGradient(colors: [Colors.cyanAccent, Colors.blueAccent, Colors.purpleAccent]),
                                      boxShadow: [BoxShadow(color: Colors.cyanAccent.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))],
                                    ),
                                    child: Center(
                                      child: _isLoading
                                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Color(0xFF0F0C29), strokeWidth: 2))
                                          : Text(lp.getString('login_btn'), style: const TextStyle(color: Color(0xFF0F0C29), fontWeight: FontWeight.bold, letterSpacing: 1.2)),
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
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => RegisterPage(initialIsBusiness: isBusiness))),
                        child: Text(lp.getString('create_new_acc'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
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

  Widget _buildRoleSwitch(LanguageProvider lp) {
    return Container(
      width: 280,
      height: 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 250),
            alignment: isBusiness ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 135,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Colors.cyanAccent, Colors.blueAccent]),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.cyanAccent.withOpacity(0.2), blurRadius: 8)],
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => isBusiness = false),
                  child: Center(
                    child: Text(lp.getString('user_tab'), style: TextStyle(color: !isBusiness ? const Color(0xFF0F0C29) : Colors.white70, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => isBusiness = true),
                  child: Center(
                    child: Text(lp.getString('business_tab'), style: TextStyle(color: isBusiness ? const Color(0xFF0F0C29) : Colors.white70, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String hint, required IconData icon, bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : false,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
        prefixIcon: Icon(icon, color: Colors.blueAccent, size: 20),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(_obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye, color: Colors.white54, size: 18),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        )
            : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.blueAccent)),
      ),
    );
  }
}