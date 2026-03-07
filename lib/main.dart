import 'dart:async';
import 'dart:ui'; // Required for Glassmorphism
import 'package:flutter/material.dart';
import 'package:recommended_restaurant_entertainment/Location/location_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:async/async.dart';

// Import your pages
import 'package:recommended_restaurant_entertainment/loginModule/login_page.dart';
import 'package:recommended_restaurant_entertainment/discoverModule/discoverPage.dart';
import 'package:recommended_restaurant_entertainment/loginModule/updatePassword_page.dart';
import 'package:recommended_restaurant_entertainment/postModule/createPost.dart';
import 'package:recommended_restaurant_entertainment/userModule/user_profile.dart';
import 'package:recommended_restaurant_entertainment/chat/chat_page.dart';
import 'get_start.dart';

// 1. Your Supabase Credentials preserved
const String url = 'https://bljokgoarqfpkcthkmvq.supabase.co';
const String key = 'sb_secret_99fIQ1nuXy1Hz1f2yYnrqQ_HsatXb3B';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      // Change this from LoginPage() to GetStartedPage()
      home: const GetStartedPage(),
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
  final GlobalKey<UserProfilePageState> _profileKey =
      GlobalKey<UserProfilePageState>();
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    // Logic preserved exactly
    _pages = [
      DiscoverPage(currentUserData: widget.userData),
      MapDiscoveryPage(userData: widget.userData),
      const SizedBox.shrink(),
      UserInboxPage(userData: widget.userData),
      UserProfilePage(key: _profileKey, userData: widget.userData),
    ];

    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      data,
    ) {
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

  // --- LOGIC PRESERVED: Stream for notifications ---
  Stream<bool> _globalNotificationStream() async* {
    final supabase = Supabase.instance.client;
    final userId = widget.userData['id'];

    final systemStream = supabase
        .from('system_messages')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId);
    final messagesStream = supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('receiver_id', userId);
    final bookingStream = supabase
        .from('bookings')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId.toString());
    final commentStream = supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId);

    final combinedStream = StreamGroup.merge([
      systemStream,
      messagesStream,
      bookingStream,
      commentStream,
    ]);
    yield await _checkRedDotConditions(supabase, userId);

    await for (final _ in combinedStream) {
      yield await _checkRedDotConditions(supabase, userId);
    }
  }

  // --- LOGIC PRESERVED: Condition checks ---
  Future<bool> _checkRedDotConditions(SupabaseClient supabase, dynamic userId) async {
    try {
      // Ensure userId is in the correct format for your queries
      final queryUserId = userId;

      final systemMessages = await supabase
          .from('system_messages')
          .select()
          .eq('user_id', queryUserId)
          .eq('is_read', false);

      final chatMessages = await supabase
          .from('messages')
          .select()
          .eq('receiver_id', queryUserId)
          .eq('is_read', false);

      final commentNotifications = await supabase
          .from('notifications')
          .select()
          .eq('user_id', queryUserId)
          .eq('is_read', false);
      final bookings = await supabase
          .from('bookings')
          .select()
          .eq('user_id', userId.toString());

      final now = DateTime.now();
      final String today = DateFormat('yyyy-MM-dd').format(now);
      final String currentTime = DateFormat('HH:mm:ss').format(now);

      bool hasNotification = bookings.any((b) {
        // Condition A: Booking is TODAY (Reminder)
        bool isToday = b['booking_date'] == today;
        String bTime = b['booking_time'] ?? "00:00:00";
        if (bTime.length == 5) bTime += ":00";
        String status = (b['status'] ?? "").toLowerCase();
        bool isActive = status != "rejected" && status != "cancelled";
        bool isReminder =
            isToday && bTime.compareTo(currentTime) >= 0 && isActive;

        // Condition B: Business updated the status and user hasn't seen it yet (New Notification)
        // This is the NEW logic linked to your SQL trigger
        bool isNewUpdate = b['user_viewed'] == false;

        return isReminder || isNewUpdate;
      });
      return systemMessages.isNotEmpty ||
          chatMessages.isNotEmpty ||
          commentNotifications.isNotEmpty ||
          hasNotification;
    } catch (e) {
      debugPrint("Red dot error: $e");
      return false;
    }
  }

  // --- LOGIC PRESERVED: Navigation handling ---
  void _onItemTapped(int index) async {
    if (index == 2) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              CreatePostPage(profileUserId: widget.userData['id'].toString()),
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
      backgroundColor: const Color(0xFF0F0C29),
      extendBody: true, // Crucial for content to show behind glass nav
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: _buildMidnightNavBar(),
    );
  }

  Widget _buildMidnightNavBar() {
    return ClipRRect(
      child: BackdropFilter(
        // Increased blur to handle high-detail map background
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          // height: 90 accounts for the bottom safe area on modern phones
          height: 90,
          padding: const EdgeInsets.only(bottom: 15),
          decoration: BoxDecoration(
            // Deeper midnight opacity for better icon contrast
            color: const Color(0xFF0F0C29).withOpacity(0.85),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.1), width: 0.5),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(LucideIcons.home, 0),
              _buildNavItem(LucideIcons.mapPin, 1),
              _buildAddNavItem(),
              _buildChatNavItem(3),
              _buildNavItem(LucideIcons.user, 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    bool isSelected = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onItemTapped(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              // Brighter Cyan and White for higher visibility on light maps
              color: isSelected
                  ? Colors.cyanAccent
                  : Colors.white.withOpacity(0.4),
              size: 26,
            ),
            const SizedBox(height: 4),
            // Added a subtle dot indicator for selected state
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 4,
              width: isSelected ? 4 : 0,
              decoration: const BoxDecoration(
                color: Colors.cyanAccent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Centered Add Button Item
  Widget _buildAddNavItem() {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onItemTapped(2),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [
                  Colors.cyanAccent,
                  Colors.blueAccent,
                  Colors.purpleAccent,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.cyanAccent.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              LucideIcons.plus,
              color: Color(0xFF0F0C29),
              size: 22,
            ),
          ),
        ),
      ),
    );
  }

  // Centered Chat Item with Stream Logic
  Widget _buildChatNavItem(int index) {
    bool isSelected = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onItemTapped(index),
        child: Center(
          child: StreamBuilder<bool>(
            stream: _globalNotificationStream(),
            builder: (context, snapshot) {
              final bool showRedDot = snapshot.data ?? false;
              return Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    LucideIcons.messageSquare,
                    color: isSelected ? Colors.cyanAccent : Colors.white38,
                    size: 24,
                  ),
                  if (showRedDot)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF0F0C29),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
