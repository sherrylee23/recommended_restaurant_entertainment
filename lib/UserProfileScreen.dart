import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:recommended_restaurant_entertainment/UserEditProfile.dart';
import 'package:recommended_restaurant_entertainment/help_center.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // length: 2 corresponds to the Grid and Video tabs
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor:
            Colors.transparent, // Make this transparent to see the gradient
        elevation: 0,
        title: const Text(
          'windy0303',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        // --- This is where you add the gradient ---
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.shade100, // Light blue at the top left
                Colors.purple.shade50, // Transition to soft purple
              ],
            ),
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(LucideIcons.menu, color: Colors.black),
            onSelected: (value) {
              if (value == 'help') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const help_center()),
                );
              } else if (value == 'logout') {
                // Add your logout logic here (e.g., clear Supabase session)
                print("User logged out");
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'help',
                child: Row(
                  children: [
                    Icon(LucideIcons.helpCircle, size: 18, color: Colors.black),
                    SizedBox(width: 10),
                    Text('Help Center'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(LucideIcons.logOut, size: 18, color: Colors.red),
                    SizedBox(width: 10),
                    Text('Logout', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // --- 1. User Info Header ---
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              // You can customize these colors to fit your FYP's theme
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue.shade100, // Soft start color
                  Colors.purple.shade50, // Soft end color
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                children: [
                  Stack(
                    children: [
                      const CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.grey,
                        backgroundImage: NetworkImage(
                          'https://api.dicebear.com/7.x/avataaars/png?seed=windy',
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(blurRadius: 2, color: Colors.black26),
                            ],
                          ),
                          child: const Icon(
                            LucideIcons.edit3,
                            size: 14,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'windy0303',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Icon(
                            Icons.female,
                            color: Colors.pinkAccent.shade100,
                            size: 18,
                          ),
                        ],
                      ),
                      const Text(
                        'ID:12345678',
                        style: TextStyle(color: Colors.black54, fontSize: 14),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Text(
                              'New Users ',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Icon(
                              LucideIcons.info,
                              size: 12,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // --- 2. Stats Row ---
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.blue.shade100, // Light blue tint
                  Colors.purple.shade50, // Light purple tint
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStat('5', 'Posts'),
                  _buildStat('100', 'Followers'),
                  _buildStat('10', 'Following'),
                  _buildStat('1090', 'Likes'),

                  // --- Button with a slightly more visible gradient feel ---
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const UserEditProfile(),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(
                          0.7,
                        ), // Semi-transparent to let gradient show
                        side: BorderSide(color: Colors.blue.shade100),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'Edit Profile',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- 3. Custom Tab Bar ---
          TabBar(
            controller: _tabController,
            indicatorColor: Colors.black,
            indicatorWeight: 1,
            tabs: const [
              Tab(icon: Icon(LucideIcons.layoutGrid, color: Colors.black)),
              Tab(icon: Icon(LucideIcons.video, color: Colors.black)),
            ],
          ),

          // --- 4. Tab Content (Photos/Videos) ---
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                GridView.builder(
                  padding: const EdgeInsets.all(2),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 2,
                    mainAxisSpacing: 2,
                  ),
                  itemCount: 2, // From your UI image
                  itemBuilder: (context, index) {
                    return Image.network(
                      'https://picsum.photos/400?random=$index',
                      fit: BoxFit.cover,
                    );
                  },
                ),
                const Center(
                  child: Icon(
                    LucideIcons.videoOff,
                    size: 50,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // --- 5. Bottom Navigation Bar ---
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}
