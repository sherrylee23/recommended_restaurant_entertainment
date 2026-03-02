import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Add this
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

              // Booking History Tab
              IconButton(
                icon: Icon(LucideIcons.calendarCheck,
                    color: _selectedIndex == 1 ? Colors.blueAccent : Colors.grey),
                onPressed: () => setState(() => _selectedIndex = 1),
              ),

              // Inbox Tab with Red Dot Logic
              StreamBuilder<List<Map<String, dynamic>>>(
                // Listen to the messages table in real-time
                stream: _supabase
                    .from('messages')
                    .stream(primaryKey: ['id'])
                    .eq('receiver_id', businessId),
                builder: (context, snapshot) {
                  // Check if there are any messages that are not read
                  bool hasUnread = false;
                  if (snapshot.hasData) {
                    hasUnread = snapshot.data!.any((m) => m['is_read'] == false);
                  }

                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      IconButton(
                        icon: Icon(LucideIcons.messageSquare,
                            color: _selectedIndex == 2 ? Colors.blueAccent : Colors.grey),
                        onPressed: () => setState(() => _selectedIndex = 2),
                      ),
                      if (hasUnread)
                        Positioned(
                          right: 8,
                          top: 8,
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
            ],
          ),
        ),
      ),
    );
  }
}