import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class BusinessMainNavigation extends StatefulWidget {
  final Map<String, dynamic> businessData;
  const BusinessMainNavigation({super.key, required this.businessData});

  @override
  State<BusinessMainNavigation> createState() => _BusinessMainNavigationState();
}

class _BusinessMainNavigationState extends State<BusinessMainNavigation> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    bool isDesktop = MediaQuery.of(context).size.width > 800;

    final List<Widget> pages = [
      _buildHomeStats(), // Business Overview
      const Center(child: Text("Manage Menu/Services")),
      const Center(child: Text("Business Settings")),
    ];

    return Scaffold(
      body: Row(
        children: [
          if (isDesktop)
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (i) => setState(() => _selectedIndex = i),
              extended: MediaQuery.of(context).size.width > 1000,
              leading: CircleAvatar(
                backgroundImage: NetworkImage(widget.businessData['ssm_url']),
              ),
              destinations: const [
                NavigationRailDestination(icon: Icon(LucideIcons.layoutDashboard), label: Text('Dashboard')),
                NavigationRailDestination(icon: Icon(LucideIcons.list), label: Text('Services')),
                NavigationRailDestination(icon: Icon(LucideIcons.settings), label: Text('Settings')),
              ],
            ),
          const VerticalDivider(width: 1),
          Expanded(child: pages[_selectedIndex]),
        ],
      ),
      bottomNavigationBar: isDesktop ? null : BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(LucideIcons.layoutDashboard), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.list), label: 'Services'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildHomeStats() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.purple.shade50],
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            "Welcome, ${widget.businessData['business_name']}!",
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildFeatureCard(),
        ],
      ),
    );
  }

  Widget _buildFeatureCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF8ECAFF), Colors.purpleAccent]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Account Status: Approved", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          Text("You can now start managing your business profile.", style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}