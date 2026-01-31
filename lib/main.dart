import 'package:flutter/material.dart';
import 'package:recommended_restaurant_entertainment/UserProfileScreen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';

// Import your pages
import 'package:recommended_restaurant_entertainment/loginModule/login_page.dart';
import 'package:recommended_restaurant_entertainment/discoverModule/discoverPage.dart';
import 'package:recommended_restaurant_entertainment/profile.dart';

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
      // The flow starts here
      home: const LoginPage(),
    );
  }
}

// 3. The Main Navigation Wrapper (Teammate's Design)
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  // Navigation starts at DiscoverPage (Index 0)
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DiscoverPage(), // Your Discover Page is the first screen after login
    const Center(child: Text('Location Screen')),
    const Center(child: Text('Add Post Screen')),
    const Center(child: Text('Chat Screen')),
    const UserProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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
                    // Updated to avoid deprecation warning
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