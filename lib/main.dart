import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';

// Import your pages
import 'package:recommended_restaurant_entertainment/loginModule/login_page.dart';
import 'package:recommended_restaurant_entertainment/discoverModule/discoverPage.dart';
import 'package:recommended_restaurant_entertainment/loginModule/updatePassword_page.dart';
import 'package:recommended_restaurant_entertainment/postModule/createPost.dart';
import 'package:recommended_restaurant_entertainment/userModule/user_profile.dart';

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
  // Added userData to receive info from LoginPage
  final Map<String, dynamic> userData;

  const MainNavigation({super.key, required this.userData});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  late final StreamSubscription<AuthState> _authSubscription;

  // Use late to initialize pages once widget data is available [cite: 7]
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    // Initialize the pages and pass the user data to the profile page
    _pages = [
      const DiscoverPage(),
      const Center(child: Text('Location Screen')),
      const SizedBox.shrink(),
      const Center(child: Text('Chat Screen')),
      UserProfilePage(userData: widget.userData),
    ];

    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.passwordRecovery) {
        if (mounted) {
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
    _authSubscription.cancel();
    super.dispose();
  }

  Future<void> _updateUserPassword(String newPassword) async {
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

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
                    color: Colors.blueAccent.withOpacity(0.3),
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