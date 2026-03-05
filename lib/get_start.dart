import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'loginModule/login_page.dart';

class GetStartedPage extends StatelessWidget {
  const GetStartedPage({super.key});

  @override
  Widget build(BuildContext context) {
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
        child: Column(
          children: [
            // This spacer pushes the Logo/Nomi down slightly from the top
            const Spacer(flex: 3),

            // --- Branding Section (Remains centered/upper) ---
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

            // This spacer pushes the text/button block all the way to the bottom
            const Spacer(flex: 6),

            // --- Bottom Section: Intro Text & Button ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 45),
              child: Column(
                children: [
                  Text(
                    "Find the best restaurants and entertainment near you",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withOpacity(0.6),
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 25), // Space between text and button

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
                      child: const Text(
                        "GET STARTED",
                        style: TextStyle(
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

            // Final small gap to prevent the button from touching the very bottom edge
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}