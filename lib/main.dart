import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';

// Import your pages
import 'package:recommended_restaurant_entertainment/loginModule/login_page.dart';
import 'package:recommended_restaurant_entertainment/discoverModule/discoverPage.dart';
import 'package:recommended_restaurant_entertainment/profile.dart';
import 'package:recommended_restaurant_entertainment/loginModule/updatePassword_page.dart';
import 'package:recommended_restaurant_entertainment/postModule/createPost.dart';

// 1. Your Supabase Credentials
const String url = 'https://bljokgoarqfpkcthkmvq.supabase.co';
const String key = 'sb_secret_99fIQ1nuXy1Hz1f2yYnrqQ_HsatXb3B';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Supabase
  await Supabase.initialize(
    url: url,
    anonKey: key,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FYP App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}

// 3. The Main Navigation Wrapper
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;

      // Check if the event is password recovery
      if (event == AuthChangeEvent.passwordRecovery) {
        if (mounted) {
          // Navigate to your specific page instead of showing a dialog
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const UpdatePasswordPage()),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel(); // Clean up the listener
    super.dispose();
  }

  // Popup Dialog to set the new password
  void _showResetPasswordDialog() {
    final TextEditingController newPassController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Create New Password"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Your email is verified. Please set a new password below."),
            const SizedBox(height: 15),
            TextField(
              controller: newPassController,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: "New Password (min 8 chars)",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              final newPassword = newPassController.text.trim();
              if (newPassword.length >= 8) {
                await _updateUserPassword(newPassword);
                if (mounted) Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Password too short!")),
                );
              }
            },
            child: const Text("Update Password"),
          ),
        ],
      ),
    );
  }

  // Update logic for both Auth and Profiles table
  Future<void> _updateUserPassword(String newPassword) async {
    try {
      // 1. Update the official Supabase Auth Password
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      // 2. Update your manual 'profiles' table to keep it in sync
      final String? userEmail = Supabase.instance.client.auth.currentUser?.email;
      if (userEmail != null) {
        await Supabase.instance.client
            .from('profiles')
            .update({'password': newPassword})
            .eq('email', userEmail);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password updated successfully!"), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Update failed: ${e.toString()}"), backgroundColor: Colors.red),
      );
    }
  }

// 1. Updated Pages List (Remove CreatePostPage from here to avoid index conflicts)
  final List<Widget> _pages = [
    const DiscoverPage(),
    const Center(child: Text('Location Screen')),
    const SizedBox.shrink(),
    const Center(child: Text('Chat Screen')),
    const ProfilePage(),
  ];

  void _onItemTapped(int index) {
    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const CreatePostPage(),
          fullscreenDialog: true,
        ),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        items: [
          const BottomNavigationBarItem(icon: Icon(LucideIcons.home), label: 'Home'),
          const BottomNavigationBarItem(icon: Icon(LucideIcons.mapPin), label: 'Map'),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF8ECAFF),
                    Color(0xFF4A90E2),
                    Colors.purpleAccent,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueAccent.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(LucideIcons.plus, color: Colors.white, size: 24),
            ),
            label: 'Add',
          ),
          const BottomNavigationBarItem(icon: Icon(LucideIcons.messageSquare), label: 'Chat'),
          const BottomNavigationBarItem(icon: Icon(LucideIcons.user), label: 'Profile'),
        ],
      ),
    );
  }
}