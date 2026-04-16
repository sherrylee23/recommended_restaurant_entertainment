import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'loginModule/login_page.dart';
import 'language_provider.dart';

class GetStartedPage extends StatelessWidget {
  const GetStartedPage({super.key});

  // LANGUAGE SELECTION DIALOG
  void _showLanguageDialog(BuildContext context) {
    final lp = Provider.of<LanguageProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: const Color(0xFF1A1A35).withOpacity(0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
            side: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          title: Text(
            lp.getString('select_language'),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLanguageOption(context, "English", "en", lp),
              _buildLanguageOption(context, "中文 (Chinese)", "zh", lp),
              _buildLanguageOption(context, "Bahasa Melayu", "ms", lp),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOption(BuildContext context, String label, String code, LanguageProvider lp) {
    bool isSelected = lp.currentLocale.languageCode == code;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.cyanAccent : Colors.white70,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.cyanAccent, size: 20) : null,
      onTap: () {
        lp.changeLanguage(code);
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Access language provider
    final lp = Provider.of<LanguageProvider>(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
          ),
        ),
        child: Stack( // Use stack to place the language button at the top
          children: [
            Column(
              children: [
                const Spacer(flex: 3),

                // --- Branding Section ---
                Image.asset(
                  'assets/nomi_logo.jpeg',
                  width: 100,
                  height: 100,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 15),
                const Text(
                  "Nomi",
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2.0,
                    shadows: [
                      Shadow(
                        color: Color.fromRGBO(0, 255, 255, 0.5),
                        blurRadius: 15,
                        offset: Offset(0, 3),
                      )
                    ],
                  ),
                ),

                const Spacer(flex: 6),

                // Translated Intro Text & Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 45),
                  child: Column(
                    children: [
                      Text(
                        lp.getString('get_started_desc'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withOpacity(0.6),
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 25),

                      Container(
                        width: double.infinity,
                        height: 55,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          gradient: const LinearGradient(
                            colors: [Colors.cyanAccent, Colors.blueAccent, Colors.purpleAccent],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blueAccent.withValues(alpha: 0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginPage()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                          child: Text(
                            lp.getString('get_started_btn'),
                            style: const TextStyle(
                              color: Color(0xFF0F0C29),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 50),
              ],
            ),

            // TOP RIGHT LANGUAGE BUTTON
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              right: 20,
              child: IconButton(
                icon: const Icon(LucideIcons.languages, color: Colors.white70, size: 28),
                onPressed: () => _showLanguageDialog(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}