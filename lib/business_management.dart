import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class BusinessManagement extends StatefulWidget {
  const BusinessManagement({super.key});

  @override
  State<BusinessManagement> createState() => _BusinessManagementState();
}

class _BusinessManagementState extends State<BusinessManagement> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Consistent with your current layout colors
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.shade100,
                Colors.purple.shade50,
                Colors.white,
              ],
            ),
          ),
        ),
        title: const Text(
          "Business Manager",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.bell, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Business Header ---
            const Text(
              "Welcome, Windy's Cafe",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Text(
              "Manage your restaurant and promotions here.",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 25),

            // --- Stats Overview (Using your Gradient style) ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8ECAFF), Color(0xFF4A90E2), Colors.purpleAccent],
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueAccent.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _BusinessStat(label: "Views", value: "1.2k"),
                  _BusinessStat(label: "Bookings", value: "45"),
                  _BusinessStat(label: "Rating", value: "4.8"),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // --- Quick Actions ---
            const Text(
              "Management Tools",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 1.3,
              children: [
                _buildActionCard(LucideIcons.utensils, "Menu Items", Colors.orange),
                _buildActionCard(LucideIcons.megaphone, "Promotions", Colors.pink),
                _buildActionCard(LucideIcons.messageCircle, "Customer Reviews", Colors.blue),
                _buildActionCard(LucideIcons.settings, "Store Settings", Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(IconData icon, String title, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 5,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _BusinessStat extends StatelessWidget {
  final String label;
  final String value;

  const _BusinessStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}