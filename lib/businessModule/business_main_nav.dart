import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'business_profile.dart';
import 'business_booking_history.dart';
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
    // Added BusinessBookingHistory to the list of pages
    final List<Widget> pages = [
      BusinessProfilePage(businessData: widget.businessData),
      BusinessBookingHistory(businessId: widget.businessData['id']), // New Tab
      BusinessInboxPage(businessData: widget.businessData),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: BottomAppBar(
        elevation: 10,
        child: SizedBox(
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Profile Tab
              IconButton(
                icon: Icon(LucideIcons.user,
                    color: _selectedIndex == 0 ? Colors.blueAccent : Colors.grey),
                onPressed: () => setState(() => _selectedIndex = 0),
              ),

              // Booking History Tab (Middle)
              IconButton(
                icon: Icon(LucideIcons.calendarCheck,
                    color: _selectedIndex == 1 ? Colors.blueAccent : Colors.grey),
                onPressed: () => setState(() => _selectedIndex = 1),
              ),

              // Inbox Tab
              IconButton(
                icon: Icon(LucideIcons.messageSquare,
                    color: _selectedIndex == 2 ? Colors.blueAccent : Colors.grey),
                onPressed: () => setState(() => _selectedIndex = 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}