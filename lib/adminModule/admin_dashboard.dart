import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:recommended_restaurant_entertainment/adminModule/admin_stats.dart';
import 'admin_approval_list.dart';
import 'admin_feedback_list.dart';
import 'admin_report_user.dart';
import 'admin_report_business.dart';
import 'admin_chat_list.dart'; // Ensure this matches your filename

class AdminDashboard extends StatefulWidget {
  final Map<String, dynamic> adminData;
  const AdminDashboard({super.key, required this.adminData});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  late final List<Widget> _adminPages;
  RealtimeChannel? _statusSubscription;

  @override
  void initState() {
    super.initState();
    _adminPages = [
      AdminApprovalList(adminData: widget.adminData),
      const AdminStatsPage(),
      const AdminChatPage(), // Index 2
      const AdminFeedbackListPage(),
      const AdminReportUserListPage(),
      const AdminReportBusinessListPage(),
    ];
    _setupAdminNotifications();
  }

  // --- REALTIME NOTIFICATION LOGIC ---
  void _setupAdminNotifications() {
    _statusSubscription = Supabase.instance.client
        .channel('admin-alerts')
        .onPostgresChanges(
      event: PostgresChangeEvent.all, // Listen for Inserts or Updates
      schema: 'public',
      table: 'support_chats',
      callback: (payload) {
        final newStatus = payload.newRecord['status'];
        // Only alert if someone just moved to 'waiting_for_agent'
        if (newStatus == 'waiting_for_agent') {
          _showNewChatAlert(payload.newRecord['user_id'].toString());
        }
      },
    )
        .subscribe();
  }

  void _showNewChatAlert(String userId) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        elevation: 10,
        backgroundColor: Colors.cyanAccent,
        leading: const Icon(LucideIcons.bellRing, color: Color(0xFF0F0C29)),
        content: Text(
          "New Support Request! User #$userId is waiting for help.",
          style: const TextStyle(color: Color(0xFF0F0C29), fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
              setState(() => _selectedIndex = 2); // Navigate to Chat Page
            },
            child: const Text("OPEN CHAT", style: TextStyle(color: Color(0xFF0F0C29), fontWeight: FontWeight.bold)),
          ),
          IconButton(
            icon: const Icon(LucideIcons.x, color: Color(0xFF0F0C29)),
            onPressed: () => ScaffoldMessenger.of(context).hideCurrentMaterialBanner(),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    if (_statusSubscription != null) {
      Supabase.instance.client.removeChannel(_statusSubscription!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0C29),
      extendBody: true,
      body: Stack(
        children: [
          // 1. GLOBAL BACKGROUND GRADIENT
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
              ),
            ),
          ),

          // 2. MAIN LAYOUT
          Row(
            children: [
              if (isDesktop)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    border: Border(right: BorderSide(color: Colors.white.withOpacity(0.1))),
                  ),
                  child: NavigationRail(
                    backgroundColor: Colors.transparent,
                    selectedIndex: _selectedIndex,
                    extended: MediaQuery.of(context).size.width > 1000,
                    unselectedIconTheme: IconThemeData(color: Colors.white.withOpacity(0.4)),
                    selectedIconTheme: const IconThemeData(color: Colors.cyanAccent),
                    unselectedLabelTextStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                    selectedLabelTextStyle: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
                    onDestinationSelected: (int index) => setState(() => _selectedIndex = index),
                    leading: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 30),
                      child: Icon(LucideIcons.shieldCheck, color: Colors.cyanAccent, size: 45),
                    ),
                    destinations: [
                      const NavigationRailDestination(icon: Icon(LucideIcons.checkCircle), label: Text('Approvals')),
                      const NavigationRailDestination(icon: Icon(LucideIcons.barChart2), label: Text('Stats')),

                      // CHAT DESTINATION WITH BADGE
                      NavigationRailDestination(
                        icon: _buildChatIcon(LucideIcons.messageCircle),
                        label: const Text('Live Chat'),
                      ),

                      const NavigationRailDestination(icon: Icon(LucideIcons.messageSquare), label: Text('Feedback')),
                      const NavigationRailDestination(icon: Icon(LucideIcons.alertTriangle), label: Text('Reports User')),
                      const NavigationRailDestination(icon: Icon(LucideIcons.megaphone), label: Text('Report Business')),
                    ],
                    trailing: Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 25),
                          child: IconButton(
                            icon: const Icon(LucideIcons.logOut, color: Colors.redAccent, size: 28),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              Expanded(
                child: ClipRRect(
                  child: _adminPages[_selectedIndex],
                ),
              ),
            ],
          ),
        ],
      ),

      // BOTTOM NAVIGATION (Mobile)
      bottomNavigationBar: isDesktop
          ? null
          : Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white.withOpacity(0.05),
              elevation: 0,
              onTap: (index) => setState(() => _selectedIndex = index),
              selectedItemColor: Colors.cyanAccent,
              unselectedItemColor: Colors.white.withOpacity(0.4),
              items: [
                const BottomNavigationBarItem(icon: Icon(LucideIcons.checkCircle), label: 'Approvals'),
                const BottomNavigationBarItem(icon: Icon(LucideIcons.barChart2), label: 'Stats'),

                // CHAT ITEM WITH BADGE
                BottomNavigationBarItem(
                  icon: _buildChatIcon(LucideIcons.messageCircle),
                  label: 'Chat',
                ),

                const BottomNavigationBarItem(icon: Icon(LucideIcons.messageSquare), label: 'Feedback'),
                const BottomNavigationBarItem(icon: Icon(LucideIcons.alertTriangle), label: 'Reports'),
                const BottomNavigationBarItem(icon: Icon(LucideIcons.megaphone), label: 'Business'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper widget to show a red badge if users are waiting
  Widget _buildChatIcon(IconData icon) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client
          .from('support_chats')
          .stream(primaryKey: ['user_id'])
          .eq('status', 'waiting_for_agent'),
      builder: (context, snapshot) {
        int count = snapshot.hasData ? snapshot.data!.length : 0;
        return Badge(
          label: Text(count.toString()),
          isLabelVisible: count > 0,
          backgroundColor: Colors.redAccent,
          child: Icon(icon),
        );
      },
    );
  }
}