import 'dart:async';
import 'package:flutter/material.dart';
import 'package:recommended_restaurant_entertainment/Location/location_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:async/async.dart'; // REQUIRED: Add this import

// Import your pages
import 'package:recommended_restaurant_entertainment/loginModule/login_page.dart';
import 'package:recommended_restaurant_entertainment/discoverModule/discoverPage.dart';
import 'package:recommended_restaurant_entertainment/loginModule/updatePassword_page.dart';
import 'package:recommended_restaurant_entertainment/postModule/createPost.dart';
import 'package:recommended_restaurant_entertainment/userModule/user_profile.dart';
import 'package:recommended_restaurant_entertainment/chat/chat_page.dart';

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

class MainNavigation extends StatefulWidget {
  final Map<String, dynamic> userData;

  const MainNavigation({super.key, required this.userData});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  late final StreamSubscription<AuthState> _authSubscription;
  final GlobalKey<UserProfilePageState> _profileKey = GlobalKey<UserProfilePageState>();
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      DiscoverPage(currentUserData: widget.userData),
      MapDiscoveryPage(userData: widget.userData),
      const SizedBox.shrink(),
      UserInboxPage(userData: widget.userData),
      UserProfilePage(key: _profileKey, userData: widget.userData),
    ];

    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const UpdatePasswordPage()),
        );
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  /// This Stream listens to multiple tables and returns true if any red dot condition is met
  Stream<bool> _globalNotificationStream() async* {
    final supabase = Supabase.instance.client;
    final userId = widget.userData['id'];

    final systemStream = supabase.from('system_messages').stream(primaryKey: ['id']).eq('user_id', userId);
    final messagesStream = supabase.from('messages').stream(primaryKey: ['id']).eq('receiver_id', userId);
    final bookingStream = supabase.from('bookings').stream(primaryKey: ['id']).eq('user_id', userId.toString());

    // Combine multiple table streams so this re-runs whenever any table changes
    final combinedStream = StreamGroup.merge([
      systemStream,
      messagesStream,
      bookingStream,
    ]);

    // Initial check when the stream first starts
    yield await _checkRedDotConditions(supabase, userId);

    // Re-check every time a stream emits a new value
    await for (final _ in combinedStream) {
      yield await _checkRedDotConditions(supabase, userId);
    }
  }

  /// Helper to perform the specific unread/booking checks
  Future<bool> _checkRedDotConditions(SupabaseClient supabase, dynamic userId) async {
    try {
      final systemMessages = await supabase
          .from('system_messages')
          .select()
          .eq('user_id', userId)
          .eq('is_read', false);

      final chatMessages = await supabase
          .from('messages')
          .select()
          .eq('receiver_id', userId)
          .eq('is_read', false);

      final bookings = await supabase
          .from('bookings')
          .select()
          .eq('user_id', userId.toString());

      final now = DateTime.now();
      final String today = DateFormat('yyyy-MM-dd').format(now);
      final String currentTime = DateFormat('HH:mm:ss').format(now);

      bool hasTodayBooking = bookings.any((b) {
        final isToday = b['booking_date'] == today;
        String bTime = b['booking_time'] ?? "00:00:00";
        if (bTime.length == 5) bTime += ":00";

        String status = (b['status'] ?? "").toLowerCase();
        bool isActive = status != "rejected" && status != "cancelled";

        return isToday && bTime.compareTo(currentTime) >= 0 && isActive;
      });

      return systemMessages.isNotEmpty || chatMessages.isNotEmpty || hasTodayBooking;
    } catch (e) {
      debugPrint("Red dot error: $e");
      return false;
    }
  }

  void _onItemTapped(int index) async {
    if (index == 2) {
      final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CreatePostPage(
              profileUserId: widget.userData['id'].toString(),
            ),
            fullscreenDialog: true,
          ),
         );
      if (result == true) {
        _profileKey.currentState?.refreshPosts();
      }
    } else {
      setState(() => _selectedIndex = index);
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
        BottomNavigationBarItem(icon: _buildAddButton(), label: 'Add'),
        BottomNavigationBarItem(
          icon: StreamBuilder<bool>(
            stream: _globalNotificationStream(),
            builder: (context, snapshot) {
              final bool showRedDot = snapshot.data ?? false;
              return Stack(
                children: [
                  const Icon(LucideIcons.messageSquare),
                  if (showRedDot)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          label: 'Chat',
        ),
        const BottomNavigationBarItem(icon: Icon(LucideIcons.user), label: 'Profile'),
      ],
    ),
    );
  }

  Widget _buildAddButton() {
    return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF8ECAFF), Color(0xFF4A90E2), Colors.purpleAccent],
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
        );
  }
}