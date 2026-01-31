/*import 'package:flutter/material.dart';
// Make sure this path correctly points to your login_page.dart file
import 'package:recommended_restaurant_entertainment/loginModule/login_page.dart';
import 'package:flutter/material.dart';
import 'package:recommended_restaurant_entertainment/loginModule/login_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        centerTitle: true,
        // Optional: Remove the back button so user must use Logout
        automaticallyImplyLeading: false,
      ),
      body: const SizedBox.expand(), // Keeps the body area empty as requested

      // Placing the button at the bottom of the screen
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              // Clears navigation history to ensure secure access [cite: 346, 657]
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
                    (route) => false,
              );
            },
            child: const Text(
              "LOGOUT",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}*/