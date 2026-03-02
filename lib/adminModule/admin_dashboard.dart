import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:recommended_restaurant_entertainment/adminModule/admin_stats.dart';
import 'admin_approval_list.dart';
import 'admin_feedback_list.dart';
import 'report_user_list.dart';
import 'report_business_list.dart';

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
      const AdminReportBusinessListPage(), // 1. Added the Complaint Page to the index
    ];
  }

  @override
  Widget build(BuildContext context) {
    // Check if the app is being viewed on a Desktop/Large screen
    bool isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      body: Row(
        children: [
          // SIDEBAR: Only visible on Desktop
          if (isDesktop)
            NavigationRail(
              selectedIndex: _selectedIndex,
              extended: MediaQuery.of(context).size.width > 1000,
              onDestinationSelected: (int index) =>
                  setState(() => _selectedIndex = index),
              leading: const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Icon(
                  LucideIcons.shieldCheck,
                  color: Colors.blueAccent,
                  size: 40,
                ),
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(LucideIcons.checkCircle),
                  selectedIcon: Icon(LucideIcons.checkCircle, color: Colors.blueAccent),
                  label: Text('Approvals'),
                ),
                NavigationRailDestination(
                  icon: Icon(LucideIcons.barChart2),
                  selectedIcon: Icon(LucideIcons.barChart2, color: Colors.blueAccent),
                  label: Text('Stats'),
                ),
                NavigationRailDestination(
                  icon: Icon(LucideIcons.messageSquare),
                  selectedIcon: Icon(LucideIcons.messageSquare, color: Colors.blueAccent),
                  label: Text('Feedback'),
                ),
                NavigationRailDestination(
                  icon: Icon(LucideIcons.alertTriangle),
                  selectedIcon: Icon(LucideIcons.alertTriangle, color: Colors.blueAccent),
                  label: Text('Reports User'),
                ),
                // 2. Added Complaints Destination for Desktop
                NavigationRailDestination(
                  icon: Icon(LucideIcons.megaphone),
                  selectedIcon: Icon(LucideIcons.megaphone, color: Colors.blueAccent),
                  label: Text('Report Business'),
                ),
              ],
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: IconButton(
                      icon: const Icon(
                        LucideIcons.logOut,
                        color: Colors.redAccent,
                      ),
                      onPressed: () => Navigator.pop(context),
                      tooltip: "Logout Admin",
                    ),
                  ),
                ),
              ),
            ),

          if (isDesktop) const VerticalDivider(thickness: 1, width: 1),

          // Main Content Area
          Expanded(child: _adminPages[_selectedIndex]),
        ],
      ),
      // BOTTOM BAR: Only visible on Mobile
      bottomNavigationBar: isDesktop
          ? null
          : BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.checkCircle),
            label: 'Approvals',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.barChart2),
            label: 'Stats',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.messageSquare),
            label: 'Feedback',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.alertTriangle),
            label: 'Reports',
          ),
          // 3. Added Complaints Item for Mobile
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.megaphone),
            label: 'Complaints',
          ),
        ],
      ),
    );
  }
}

// 4. Temporary Placeholder for the Complaint List Page
// You can move this to a separate file later.
class AdminComplaintListPage extends StatelessWidget {
  const AdminComplaintListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("User Complaints")),
      body: const Center(
        child: Text("Complaints Management System"),
      ),
    );
  }
}