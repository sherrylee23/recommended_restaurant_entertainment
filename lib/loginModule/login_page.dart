import 'dart:ui'; // Required for BackdropFilter (Glass effect)
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';

// Your existing imports
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
  bool _obscurePassword = true;
  String errorText = "";

  void _showAdminLoginDialog() {
    final TextEditingController adminEmail = TextEditingController();
    final TextEditingController adminPass = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: const Color(0xFF1A1A35).withOpacity(0.9), // Deep midnight glass
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
            side: BorderSide(color: Colors.cyanAccent.withOpacity(0.2)),
          ),
          title: const Row(
            children: [
              Icon(LucideIcons.shieldCheck, color: Colors.cyanAccent),
              SizedBox(width: 10),
              Text(
                  "Admin Portal",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Restricted access. Please authenticate.",
                style: TextStyle(color: Colors.white60, fontSize: 13),
              ),
              const SizedBox(height: 20),
              // Admin Email Field
              _buildTextField(
                  controller: adminEmail,
                  hint: "Admin Email",
                  icon: LucideIcons.mail
              ),
              const SizedBox(height: 15),
              // Admin Password Field
              _buildTextField(
                  controller: adminPass,
                  hint: "Password",
                  icon: LucideIcons.lock,
                  isPassword: true
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Cancel", style: TextStyle(color: Colors.white.withOpacity(0.5)))
            ),
            const SizedBox(width: 10),
            // Glowing Action Button
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Colors.cyanAccent, Colors.blueAccent]),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.cyanAccent.withOpacity(0.2), blurRadius: 10)
                ],
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
                        MaterialPageRoute(builder: (_) => AdminDashboard(adminData: adminData))
                    );
                  } else {
                    // Quick error feedback inside dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Invalid Admin Credentials"), backgroundColor: Colors.redAccent)
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("ACCESS", style: TextStyle(color: Color(0xFF0F0C29), fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
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
          final String status = bizData['status'] ?? 'pending';

          // --- CHECK FOR INACTIVE STATUS ---
          if (status == 'inactive') {
            if (mounted) _showAccountDisabledDialog();
          } else if (status == 'approved') {
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

  // --- NEW: ACCOUNT DISABLED DIALOG ---
  void _showAccountDisabledDialog() {
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
          title: const Row(
            children: [
              Icon(LucideIcons.alertTriangle, color: Colors.redAccent),
              SizedBox(width: 10),
              Text("Access Denied", style: TextStyle(color: Colors.white)),
            ],
          ),
          content: const Text(
            "Your business account has been deactivated by the administrator due to reported violations or policy issues. Please contact our support team for more information 03-123456789.",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CLOSE", style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color glassColor = Colors.white.withOpacity(0.12);
    Color borderColor = Colors.white.withOpacity(0.2);

    return Scaffold(
      body: Container(
        width: double.infinity, height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F0C29), // Dark Space
              Color(0xFF302B63), // Purple
              Color(0xFF24243E), // Midnight
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // FIXED: Background Glow using BoxShadow
              Positioned(
                top: -30, left: -30,
                child: Container(
                    width: 150, height: 150,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: Colors.blueAccent.withOpacity(0.2),
                              blurRadius: 100,
                              spreadRadius: 50
                          )
                        ]
                    )
                ),
              ),

              Positioned(
                top: 10, right: 10,
                child: IconButton(
                  icon: Icon(LucideIcons.shieldCheck, color: Colors.white.withOpacity(0.3)),
                  onPressed: _showAdminLoginDialog,
                ),
              ),

              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      // --- LOGO ---
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
                      _buildRoleSwitch(),
                      const SizedBox(height: 25),

                      // --- GLASS CARD ---
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
                                    isBusiness ? "Business Portal" : "Welcome Back",
                                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)
                                ),
                                const SizedBox(height: 25),
                                _buildTextField(
                                    controller: emailController,
                                    hint: isBusiness ? "Business Email" : "Username or Email",
                                    icon: isBusiness ? LucideIcons.briefcase : LucideIcons.user
                                ),
                                const SizedBox(height: 20),
                                _buildTextField(
                                    controller: passwordController,
                                    hint: "Password",
                                    icon: LucideIcons.lock,
                                    isPassword: true
                                ),
                                Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordPage())),
                                        child: const Text("Forgot password?", style: TextStyle(color: Colors.white60, fontSize: 13))
                                    )
                                ),
                                if (errorText.isNotEmpty)
                                  Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(errorText, style: const TextStyle(color: Colors.redAccent, fontSize: 12))),
                                const SizedBox(height: 15),

                                // --- GLASS BUTTON ---
                                // --- UPDATED LOGIN BUTTON ---
                                InkWell(
                                  onTap: _isLoading ? null : _login,
                                  child: Container(
                                    width: double.infinity,
                                    height: 55,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(15),
                                      // Updated to match your Feedback/Navigation style
                                      gradient: const LinearGradient(
                                        colors: [Colors.cyanAccent, Colors.blueAccent, Colors.purpleAccent],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.cyanAccent.withOpacity(0.3),
                                          blurRadius: 15,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: _isLoading
                                          ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(color: Color(0xFF0F0C29), strokeWidth: 2)
                                      )
                                          : const Text(
                                        "LOG IN",
                                        style: TextStyle(
                                          color: Color(0xFF0F0C29), // Dark text for high contrast on neon
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.2,
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
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => RegisterPage(initialIsBusiness: isBusiness))),
                        child: const Text("CREATE NEW ACCOUNT", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
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
      width: 280, height: 50,
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
                // Neon Gradient for the active toggle
                gradient: const LinearGradient(
                  colors: [Colors.cyanAccent, Colors.blueAccent],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.cyanAccent.withOpacity(0.2), blurRadius: 8)
                ],
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                  child: GestureDetector(
                      onTap: () => setState(() => isBusiness = false),
                      child: Center(
                          child: Text(
                              "User",
                              style: TextStyle(
                                  color: !isBusiness ? const Color(0xFF0F0C29) : Colors.white70,
                                  fontWeight: FontWeight.bold
                              )
                          )
                      )
                  )
              ),
              Expanded(
                  child: GestureDetector(
                      onTap: () => setState(() => isBusiness = true),
                      child: Center(
                          child: Text(
                              "Business",
                              style: TextStyle(
                                  color: isBusiness ? const Color(0xFF0F0C29) : Colors.white70,
                                  fontWeight: FontWeight.bold
                              )
                          )
                      )
                  )
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
        suffixIcon: isPassword ? IconButton(icon: Icon(_obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye, color: Colors.white54, size: 18), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)) : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.blueAccent)),
      ),
    );
  }
}