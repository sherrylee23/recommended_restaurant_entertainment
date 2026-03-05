import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:recommended_restaurant_entertainment/adminModule/admin_stats.dart';
import 'admin_approval_list.dart';
import 'admin_feedback_list.dart';
import 'admin_report_user.dart';
import 'admin_report_business.dart';

class AdminDashboard extends StatefulWidget {
  final Map<String, dynamic> adminData;
  const AdminDashboard({super.key, required this.adminData});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  late final List<Widget> _adminPages;

  @override
  void initState() {
    super.initState();
    _adminPages = [
      AdminApprovalList(adminData: widget.adminData),
      const AdminStatsPage(),
      const AdminFeedbackListPage(),
      const AdminReportUserListPage(),
      const AdminReportBusinessListPage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    bool isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0C29),
      extendBody: true, // Allows background to flow under bars
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
              // SIDEBAR: Optimized for Desktop
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
                    destinations: const [
                      NavigationRailDestination(icon: Icon(LucideIcons.checkCircle), label: Text('Approvals')),
                      NavigationRailDestination(icon: Icon(LucideIcons.barChart2), label: Text('Stats')),
                      NavigationRailDestination(icon: Icon(LucideIcons.messageSquare), label: Text('Feedback')),
                      NavigationRailDestination(icon: Icon(LucideIcons.alertTriangle), label: Text('Reports User')),
                      NavigationRailDestination(icon: Icon(LucideIcons.megaphone), label: Text('Report Business')),
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

              // PAGE CONTENT
              Expanded(
                child: ClipRRect(
                  child: _adminPages[_selectedIndex],
                ),
              ),
            ],
          ),
        ],
      ),

      // BOTTOM NAVIGATION: Optimized for Mobile
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
              items: const [
                BottomNavigationBarItem(icon: Icon(LucideIcons.checkCircle), label: 'Approvals'),
                BottomNavigationBarItem(icon: Icon(LucideIcons.barChart2), label: 'Stats'),
                BottomNavigationBarItem(icon: Icon(LucideIcons.messageSquare), label: 'Feedback'),
                BottomNavigationBarItem(icon: Icon(LucideIcons.alertTriangle), label: 'Reports'),
                BottomNavigationBarItem(icon: Icon(LucideIcons.megaphone), label: 'Business'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}