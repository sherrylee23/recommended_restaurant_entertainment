import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:recommended_restaurant_entertainment/loginModule/login_page.dart';
import 'business_edit_profile.dart';

class BusinessProfilePage extends StatefulWidget {
  final Map<String, dynamic> businessData;

  const BusinessProfilePage({super.key, required this.businessData});

  @override
  State<BusinessProfilePage> createState() => _BusinessProfilePageState();
}

class _BusinessProfilePageState extends State<BusinessProfilePage> {
  // --- Logout Logic ---
  Future<void> _handleLogout() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
              (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Logout failed: ${e.toString()}"), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- Verification Popup ---
  void _showVerificationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.verified, color: Colors.green),
            SizedBox(width: 10),
            Text("Verified Business"),
          ],
        ),
        content: const Text(
          "This business has been successfully verified via SSM (Suruhanjaya Syarikat Malaysia).",
          style: TextStyle(color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String businessName = widget.businessData['business_name']?.toString() ?? "Business";
    final String businessId = widget.businessData['id']?.toString() ?? "N/A";

    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          businessName,
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [_buildMenuPopup()],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- TOP SECTION: GRADIENT BACKGROUND ---
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Colors.blue.shade100, Colors.purple.shade50],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    // Header with Image, ID, and Name
                    _buildBusinessHeader(businessName, businessId),

                    // --- MOVED: Contact Info now sits below the Image/Name row ---
                    Padding(
                      padding: const EdgeInsets.only(left: 30, top: 15, bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoSection("Address:", widget.businessData['address']),
                          _buildInfoSection("Hours:", widget.businessData['hours']),
                          _buildInfoSection("Phone:", widget.businessData['phone']),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),
                    _buildStatsAndEditRow(),
                    const SizedBox(height: 25),
                  ],
                ),
              ),
            ),

            // --- BOTTOM SECTION: POST GRID ---
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Icon(Icons.grid_on, color: Colors.black87),
                  ),
                  _buildPostGrid(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuPopup() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.menu, color: Colors.black87),
      onSelected: (value) { if (value == 'logout') _handleLogout(); },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'logout',
          child: Row(children: [Icon(Icons.logout, color: Colors.redAccent), SizedBox(width: 10), Text("Logout")]),
        ),
      ],
    );
  }

  Widget _buildBusinessHeader(String name, String id) {
    final String? profileUrl = widget.businessData['profile_url']?.toString();
    final String businessType = widget.businessData['business_type']?.toString() ?? "Entertainment";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 45,
            backgroundColor: Colors.white,
            backgroundImage: profileUrl != null && profileUrl.isNotEmpty ? NetworkImage(profileUrl) : null,
            child: profileUrl == null || profileUrl.isEmpty
                ? const Icon(Icons.store, size: 60, color: Colors.brown)
                : null,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 5),
                    GestureDetector(
                      onTap: _showVerificationDialog,
                      child: const Icon(Icons.verified, size: 20, color: Colors.green),
                    ),
                  ],
                ),
                Text("ID:$id", style: const TextStyle(color: Colors.black54, fontSize: 14)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildPillContainer("Official Business", showIcon: true),
                    const SizedBox(width: 8),
                    _buildPillContainer(businessType),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillContainer(String label, {bool showIcon = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          if (showIcon) ...[
            const SizedBox(width: 4),
            const Icon(Icons.info_outline, size: 14, color: Colors.black54),
          ]
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, dynamic content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              title,
              style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline
              )
          ),
          const SizedBox(height: 4),
          Text(
            content?.toString() ?? "N/A",
            style: const TextStyle(color: Colors.black87, fontSize: 13, height: 1.2),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsAndEditRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        children: [
          const Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatItem(label: "Posts", count: "12"),
                _StatItem(label: "Likes", count: "8.5K"),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: () async {
              final updatedData = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BusinessEditProfilePage(businessData: widget.businessData),
                ),
              );
              if (updatedData != null) setState(() { widget.businessData.addAll(updatedData); });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              elevation: 2,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Edit Profile", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildPostGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 5,
        mainAxisSpacing: 5,
      ),
      itemCount: 9,
      itemBuilder: (context, index) => Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(4),
          image: const DecorationImage(
            image: AssetImage('assets/placeholder_image.png'), // Replace with your image logic
            fit: BoxFit.cover,
          ),
        ),
        child: const Icon(Icons.image, color: Colors.grey),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String count;
  const _StatItem({required this.label, required this.count});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(count, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ],
    );
  }
}