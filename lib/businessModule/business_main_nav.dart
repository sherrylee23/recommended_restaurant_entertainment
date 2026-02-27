import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'business_profile.dart';
import 'inbox_page.dart';

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
    final List<Widget> pages = [
      BusinessProfilePage(businessData: widget.businessData),
      const Center(child: Text("Create Post Screen")),
      BusinessInboxPage(businessData: widget.businessData), // Now correctly linked
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: BottomAppBar(
        elevation: 10,
        child: SizedBox(
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(LucideIcons.user, color: _selectedIndex == 0 ? Colors.blueAccent : Colors.grey),
                onPressed: () => setState(() => _selectedIndex = 0),
              ),
              _buildAddButton(),
              IconButton(
                icon: Icon(LucideIcons.messageSquare, color: _selectedIndex == 2 ? Colors.blueAccent : Colors.grey),
                onPressed: () => setState(() => _selectedIndex = 2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = 1),
      child: Container(
        height: 50, width: 50,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(colors: [Color(0xFF8ECAFF), Colors.purpleAccent]), //
        ),
        child: const Icon(LucideIcons.plus, color: Colors.white, size: 28),
      ),
    );
  }
}