import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  final _supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    final dynamic businessId = widget.businessData['id'];

    final List<Widget> pages = [
      BusinessProfilePage(businessData: widget.businessData),
      BusinessBookingHistory(businessId: widget.businessData['id']),
      BusinessInboxPage(businessData: widget.businessData),
    ];

    return Scaffold(
      extendBody: true, // Crucial: Allows pages to draw behind the nav bar
      backgroundColor: const Color(0xFF0F0C29),
      body: IndexedStack(index: _selectedIndex, children: pages),

      // Floating Glassmorphic Navigation Bar
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 25), // Floating effect
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              height: 75,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Profile Tab
                  _buildNavItem(LucideIcons.user, 0),

                  // Booking History Tab

                  // Inbox Tab with Real-time Logic Preserved
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _supabase
                        .from('bookings')
                        .stream(primaryKey: ['id'])
                        .eq('business_id', businessId.toString()),
                    builder: (context, snapshot) {
                      bool hasNewBooking = false;
                      if (snapshot.hasData) {
                        // Show dot if any booking is still 'pending'
                        hasNewBooking = snapshot.data!.any((b) => b['status'] == 'pending');
                      }

                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          _buildNavItem(LucideIcons.calendarCheck, 1),
                          if (hasNewBooking)
                            Positioned(
                              right: 12,
                              top: 15,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: Colors.orangeAccent, // Using orange for bookings to distinguish from messages
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFF1A1A35), width: 1.5),
                                  boxShadow: [BoxShadow(color: Colors.orangeAccent.withOpacity(0.5), blurRadius: 5)],
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),

                  // 3. Inbox Tab (Keep your existing logic)
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _supabase.from('messages').stream(primaryKey: ['id']),
                    builder: (context, snapshot) {
                      bool hasUnread = false;
                      if (snapshot.hasData) {
                        hasUnread = snapshot.data!.any((m) =>
                        m['receiver_id'].toString() == businessId.toString() &&
                            m['is_read'] == false);
                      }
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          _buildNavItem(LucideIcons.messageSquare, 2),
                          if (hasUnread)
                            Positioned(
                              right: 12,
                              top: 15,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFF1A1A35), width: 1.5),
                                  boxShadow: [BoxShadow(color: Colors.redAccent.withOpacity(0.5), blurRadius: 5)],
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.cyanAccent.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          icon,
          size: 26,
          color: isSelected ? Colors.cyanAccent : Colors.white.withOpacity(0.4),
        ),
      ),
    );
  }
}