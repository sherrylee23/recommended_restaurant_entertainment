import 'package:flutter/material.dart';
import 'edit_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:recommended_restaurant_entertainment/loginModule/login_page.dart';
import 'dart:math';
import 'help_center.dart';

class UserProfilePage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const UserProfilePage({super.key, required this.userData});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
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
          SnackBar(
            content: Text("Logout failed: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String username = widget.userData['username'] ?? "User";
    final String userId = widget.userData['id']?.toString() ??
        (10000000 + Random().nextInt(90000000)).toString();

    return Scaffold(
      backgroundColor: Colors.white, // Grid area will be white
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          username,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
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
                  colors: [
                    Colors.blue.shade100,
                    Colors.purple.shade50,
                  ],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    _buildProfileHeader(username, userId),
                    const SizedBox(height: 20),
                    _buildStatsAndEditRow(),
                    const SizedBox(height: 25), // Spacing before it turns white
                  ],
                ),
              ),
            ),

            // --- BOTTOM SECTION: SOLID WHITE BACKGROUND ---
            // No line here anymore, just a direct transition
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  _buildToggleIcons(),
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
      onSelected: (value) {
        if (value == 'logout') {
          _handleLogout();
        } else if (value == 'help') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HelpCenterPage()),
          );
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'help',
          child: Row(
            children: [
              Icon(Icons.help_outline, color: Colors.black87),
              SizedBox(width: 10),
              Text("Help Center"),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, color: Colors.redAccent),
              SizedBox(width: 10),
              Text("Logout", style: TextStyle(color: Colors.redAccent)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHeader(String username, String id) {
    IconData genderIcon = Icons.help_outline;
    Color genderColor = Colors.grey;
    final String gender = (widget.userData['gender'] ?? "").toString().toLowerCase();
    final String? profileUrl = widget.userData['profile_url'];

    if (gender == "female") {
      genderIcon = Icons.female;
      genderColor = Colors.pinkAccent;
    } else if (gender == "male") {
      genderIcon = Icons.male;
      genderColor = Colors.blueAccent;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 45,
            backgroundColor: Colors.white,
            backgroundImage: profileUrl != null && profileUrl.isNotEmpty
                ? NetworkImage(profileUrl)
                : null,
            child: profileUrl == null || profileUrl.isEmpty
                ? const Icon(Icons.face, size: 70, color: Colors.brown)
                : null,
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    username,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 5),
                  Icon(genderIcon, size: 18, color: genderColor),
                ],
              ),
              Text(
                "ID:$id",
                style: const TextStyle(color: Colors.black54, fontSize: 14),
              ),
              const SizedBox(height: 5),
              _buildUserStatusBadge(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserStatusBadge() {
    final String statusTitle = widget.userData['status'] ?? "New Users";
    String statusMessage = "";
    if (statusTitle == "New Users") {
      statusMessage = "New users are limited to comment 3 reviews per day.";
    } else if (statusTitle == "Active Users") {
      statusMessage = "Active users have used the system for 14+ days.";
    } else {
      statusMessage = "This account is trusted.";
    }

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(statusTitle),
            content: Text(statusMessage),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
            ],
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(statusTitle, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
            const SizedBox(width: 4),
            const Icon(Icons.info_outline, size: 12),
          ],
        ),
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
                _StatItem(label: "Posts", count: "5"),
                _StatItem(label: "Followers", count: "100"),
                _StatItem(label: "Following", count: "10"),
                _StatItem(label: "Likes", count: "1090"),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EditProfilePage(userData: widget.userData)),
              );
              if (result != null && result is Map<String, dynamic>) {
                setState(() {
                  widget.userData.addAll(result);
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.8),
              foregroundColor: Colors.black87,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Edit Profile", style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleIcons() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Icon(Icons.grid_on, color: Colors.black87),
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
        Text(count, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
      ],
    );
  }
}