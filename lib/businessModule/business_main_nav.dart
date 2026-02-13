import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'business_profile.dart'; // Ensure this matches your file name

class BusinessMainNavigation extends StatefulWidget {
  final Map<String, dynamic> businessData;
  const BusinessMainNavigation({super.key, required this.businessData});

  @override
  State<BusinessMainNavigation> createState() => _BusinessMainNavigationState();
}

class _BusinessMainNavigationState extends State<BusinessMainNavigation> {
  int _selectedIndex = 0; // Default to Profile

  @override
  Widget build(BuildContext context) {
    // Page list: Profile (0), Create Post (1), Chat (2)
    final List<Widget> pages = [
      BusinessProfilePage(businessData: widget.businessData), // Index 0
      const Center(child: Text("Create Post Screen")),        // Index 1
      const Center(child: Text("Chat Screen")),               // Index 2
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomAppBar(
        elevation: 10,
        child: SizedBox(
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 1. PROFILE ICON (Left)
              IconButton(
                icon: Icon(
                  LucideIcons.user,
                  size: 28,
                  color: _selectedIndex == 0 ? Colors.blueAccent : Colors.grey,
                ),
                onPressed: () => setState(() => _selectedIndex = 0),
              ),

              // 2. ADD BUTTON (Center)
              GestureDetector(
                onTap: () => setState(() => _selectedIndex = 1),
                child: Container(
                  height: 50,
                  width: 50,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF8ECAFF), Colors.purpleAccent],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(LucideIcons.plus, color: Colors.white, size: 28),
                ),
              ),

              // 3. CHAT ICON (Right)
              IconButton(
                icon: Icon(
                  LucideIcons.messageSquare,
                  size: 28,
                  color: _selectedIndex == 2 ? Colors.blueAccent : Colors.grey,
                ),
                onPressed: () => setState(() => _selectedIndex = 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}