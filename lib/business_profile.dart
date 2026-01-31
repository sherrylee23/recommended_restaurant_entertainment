import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:recommended_restaurant_entertainment/database.dart';
import 'package:recommended_restaurant_entertainment/help_center.dart';
import 'loginModule/login_page.dart';

class BusinessProfileScreen extends StatefulWidget {
  const BusinessProfileScreen({super.key});

  @override
  State<BusinessProfileScreen> createState() => _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends State<BusinessProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Business-specific dynamic variables
  String businessName = "Loading...";
  String businessID = "";
  String category = "Cafe";
  String address = "Not set";
  String hours = "Not set";
  String phone = "Not set";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBusinessData();
  }

  Future<void> _loadBusinessData() async {
    // Assuming 'business_cache' or similar table for business profiles
    final data = await DBHelper.instance.getProfile('24681357');
    if (data != null && mounted) {
      setState(() {
        businessName = data['fullname'] ?? "ABC Restaurant";
        businessID = data['id'] ?? "24681357";
        // Additional business fields (ensure these exist in your SQLite schema)
        address = data['address'] ?? "Selangor Mansion, 1009, Jalan Masjid India";
        hours = data['hours'] ?? "Sun - Sat Open 24 hours";
        phone = data['phone'] ?? "03-2693 3314";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          businessName,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue.shade100, Colors.purple.shade50],
            ),
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(LucideIcons.menu, color: Colors.black),
            onSelected: (value) {
              if (value == 'logout') {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                      (route) => false,
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'help', child: Text('Help Center')),
              const PopupMenuItem(value: 'logout', child: Text('Logout', style: TextStyle(color: Colors.red))),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Business Info Header (Same layout as User Profile) [cite: 142, 143]
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.blue.shade100, Colors.purple.shade50],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.purpleAccent,
                        child: Text("A", style: TextStyle(fontSize: 30, color: Colors.white)),
                      ),
                      const SizedBox(width: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(businessName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          Text('ID:$businessID', style: const TextStyle(color: Colors.black54, fontSize: 14)),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              _buildBadge("Businesses"),
                              const SizedBox(width: 5),
                              _buildBadge("Cafe"),
                              const SizedBox(width: 5),
                              const Icon(Icons.check_circle, color: Colors.green, size: 18),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  _buildDetailRow("Address:", address),
                  _buildDetailRow("Hours:", hours),
                  _buildDetailRow("Phone:", phone),
                ],
              ),
            ),
          ),

          // 2. Stats Row [cite: 154, 155]
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Colors.blue.shade100, Colors.purple.shade50],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStat('1', 'Posts'),
                  _buildStat('999', 'Followers'),
                  _buildStat('1', 'Following'),
                  _buildStat('1K', 'Likes'),
                  OutlinedButton(
                    onPressed: () {}, // Navigate to business edit
                    child: const Text('Edit Profile', style: TextStyle(fontSize: 12, color: Colors.black87)),
                  ),
                ],
              ),
            ),
          ),

          // 3. Custom Tab Bar [cite: 167]
          TabBar(
            controller: _tabController,
            indicatorColor: Colors.black,
            tabs: const [
              Tab(icon: Icon(LucideIcons.layoutGrid, color: Colors.black)),
              Tab(icon: Icon(LucideIcons.video, color: Colors.black)),
            ],
          ),

          // 4. Tab Content (Grid View) [cite: 168, 169]
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                GridView.builder(
                  padding: const EdgeInsets.all(10),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 5, mainAxisSpacing: 5),
                  itemCount: 1,
                  itemBuilder: (context, index) => Container(
                    color: Colors.grey.shade200,
                    child: Center(child: Text("Try Us")),
                  ),
                ),
                const Center(child: Icon(LucideIcons.videoOff, size: 50, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(color: Colors.white70, borderRadius: BorderRadius.circular(12)),
    child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
  );

  Widget _buildDetailRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: Text.rich(TextSpan(children: [
      TextSpan(text: "$label ", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      TextSpan(text: value, style: const TextStyle(fontSize: 12)),
    ])),
  );

  Widget _buildStat(String value, String label) => Column(
    children: [
      Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
    ],
  );
}