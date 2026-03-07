import 'dart:ui';
import 'package:flutter/material.dart';
import 'edit_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:recommended_restaurant_entertainment/loginModule/login_page.dart';
import 'help_center.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../postModule/post_detail.dart';
import 'package:recommended_restaurant_entertainment/userModule/personalized.dart';
import 'package:recommended_restaurant_entertainment/customer_service/my_report.dart';

class UserProfilePage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const UserProfilePage({super.key, required this.userData});

  @override
  State<UserProfilePage> createState() => UserProfilePageState();
}

class UserProfilePageState extends State<UserProfilePage> {
  List<Map<String, dynamic>> _userPosts = [];
  bool _isLoading = true;
  int _totalLikes = 0;

  @override
  void initState() {
    super.initState();
    refreshPosts();
  }

  // --- LOGIC PRESERVED ---
  String _calculateStatus() {
    final String? createdAtRaw = widget.userData['created_at'];
    if (createdAtRaw == null) return "New Users";
    final DateTime createdAt = DateTime.parse(createdAtRaw);
    final int daysJoined = DateTime.now().difference(createdAt).inDays;
    if (daysJoined >= 365) return "Trusted User";
    if (daysJoined >= 14) return "Active User";
    return "New Users";
  }

  void _showStatusInfoPopup(String status) {
    String description = (status == "Trusted User")
        ? "This account is trusted."
        : (status == "Active User")
        ? "Active users are those who have used the system for 14 days or longer."
        : "New users are limited to comment a maximum of 3 reviews per day.";

    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: const Color(0xFF16162E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.blueAccent, width: 0.5),
          ),
          title: Text(
            status,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          content: Text(
            description,
            style: const TextStyle(fontSize: 14, color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Got it",
                style: TextStyle(
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> refreshPosts() async {
    try {
      final supabase = Supabase.instance.client;
      final profileId = widget.userData['id'];

      final postsData = await supabase
          .from('posts')
          .select('''
            *,
            likes(count),
            comments(count),
            user_liked:likes(profile_id)
          ''')
          .eq('profile_id', profileId)
          .eq('user_liked.profile_id', profileId)
          .order('created_at', ascending: false);

      int likesSum = 0;
      if (postsData != null) {
        for (var post in postsData) {
          final likesList = post['likes'] as List?;
          if (likesList != null && likesList.isNotEmpty) {
            likesSum += (likesList.first['count'] as int? ?? 0);
          }
        }
      }

      if (mounted) {
        setState(() {
          _userPosts = postsData != null
              ? List<Map<String, dynamic>>.from(postsData)
              : [];
          _totalLikes = likesSum;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching posts: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Logout failed: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Extract variables from widget.userData
    final String username = widget.userData['username'] ?? "User";
    final String fullName =
        widget.userData['name'] ??
        "No Name Provided"; // Using 'name' from registration
    final String userId = widget.userData['id']?.toString() ?? "0";

    return Scaffold(
      backgroundColor: const Color(0xFF0F0C29),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        // HEADER: Display Username
        title: Text(
          username,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [_buildMenuPopup()],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: refreshPosts,
          color: Colors.cyanAccent,
          backgroundColor: const Color(0xFF1A1A35),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // Pass fullName and userId to the header
                _buildModernHeader(fullName, userId),
                _buildPostSection(username),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader(String username, String userId) {
    return Container(
      width: double.infinity,
      // Reduced bottom padding from 30 to 15
      padding: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      child: Column(
        children: [
          // This adds just enough space for the AppBar height without the huge SafeArea gap
          const SizedBox(height: kToolbarHeight + 25),
          _buildProfileAvatar(username, userId),
          // Reduced height between avatar and stats from 25 to 15
          const SizedBox(height: 15),
          _buildStatsAndEditRow(),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(String fullName, String id) {
    // 2. Logic for Gender and Activity Level
    IconData genderIcon = Icons.help_outline;
    Color genderColor = Colors.grey;
    final String gender = (widget.userData['gender'] ?? "")
        .toString()
        .toLowerCase();
    final String? profileUrl = widget.userData['profile_url'];

    if (gender == "female") {
      genderIcon = Icons.female;
      genderColor = Colors.pinkAccent;
    } else if (gender == "male") {
      genderIcon = Icons.male;
      genderColor = Colors.cyanAccent;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Row(
        children: [
          _avatarCircle(profileUrl), // Extracted for cleanliness
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // FULL NAME & GENDER
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        fullName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(genderIcon, size: 18, color: genderColor),
                  ],
                ),

                // ID
                Text(
                  "ID: $id",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 6),

                // ACTIVITY LEVEL (Status Badge) [cite: 40, 41]
                _buildUserStatusBadge(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarCircle(String? profileUrl) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Colors.cyanAccent, Colors.purpleAccent],
        ),
        boxShadow: [
          BoxShadow(color: Colors.cyanAccent.withOpacity(0.3), blurRadius: 15),
        ],
      ),
      child: CircleAvatar(
        radius: 40,
        backgroundColor: const Color(0xFF1A1A35),
        backgroundImage: profileUrl != null && profileUrl.isNotEmpty
            ? NetworkImage(profileUrl)
            : null,
        child: profileUrl == null || profileUrl.isEmpty
            ? const Icon(Icons.face, size: 60, color: Colors.white24)
            : null,
      ),
    );
  }

  Widget _buildUserStatusBadge() {
    final String statusTitle = _calculateStatus();
    return GestureDetector(
      onTap: () => _showStatusInfoPopup(statusTitle),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.cyanAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.cyanAccent.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              statusTitle,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.cyanAccent,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(LucideIcons.info, size: 12, color: Colors.cyanAccent),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsAndEditRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _StatItem(label: "Posts", count: _userPosts.length.toString()),
              const SizedBox(width: 35),
              _StatItem(label: "Likes", count: _totalLikes.toString()),
            ],
          ),
          ElevatedButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      EditProfilePage(userData: widget.userData),
                ),
              );
              if (result != null && result is Map<String, dynamic>)
                setState(() {
                  widget.userData.addAll(result);
                });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.05),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.white.withOpacity(0.2)),
              ),
            ),
            child: const Text(
              "Edit Profile",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostSection(String username) {
    return Container(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: Text(
              "MY TIMELINE",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                fontSize: 12,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ),
          _buildPostGrid(username),
        ],
      ),
    );
  }

  Widget _buildPostGrid(String username) {
    if (_isLoading)
      return const Padding(
        padding: EdgeInsets.all(50),
        child: Center(
          child: CircularProgressIndicator(color: Colors.cyanAccent),
        ),
      );
    if (_userPosts.isEmpty)
      return Padding(
        padding: const EdgeInsets.all(100),
        child: Center(
          child: Text(
            "No posts yet.",
            style: TextStyle(color: Colors.white.withOpacity(0.3)),
          ),
        ),
      );

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      // FIX: Increased bottom padding from 10 to 40
      padding: const EdgeInsets.only(left: 16, right: 16, top: 10, bottom: 40),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.72,
      ),
      itemCount: _userPosts.length,
      itemBuilder: (context, index) {
        final post = _userPosts[index];
        final List<dynamic> media = post['media_urls'] ?? [];
        final String profileUrl = widget.userData['profile_url'] ?? "";

        final int postLikeCount = (post['likes'] as List?)?.isNotEmpty == true
            ? post['likes'].first['count'] ?? 0
            : 0;
        final int postCommentCount =
            (post['comments'] as List?)?.isNotEmpty == true
            ? post['comments'].first['count'] ?? 0
            : 0;
        final bool isLikedByMe =
            (post['user_liked'] as List?)?.isNotEmpty == true;

        return GestureDetector(
          onTap: () async {
            final Map<String, dynamic> postWithProfile = Map.from(post);
            postWithProfile['profiles'] = {
              'profile_url': profileUrl,
              'username': username,
            };
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PostDetailPage(
                  post: postWithProfile,
                  userName: username,
                  viewerProfileId: widget.userData['id'],
                ),
              ),
            );
            refreshPosts();
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: media.isNotEmpty
                        ? Image.network(
                            media[0],
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: Colors.white.withOpacity(0.05),
                            child: const Icon(
                              LucideIcons.image,
                              color: Colors.white24,
                            ),
                          ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post['title'] ?? "Untitled",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment
                            .end, // Pushes everything to the right
                        children: [
                          Icon(
                            LucideIcons.messageCircle,
                            size: 12,
                            color: Colors.white.withOpacity(0.4),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "$postCommentCount",
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(
                            width: 8,
                          ), // Add spacing between comment and like groups
                          Icon(
                            isLikedByMe
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 14,
                            color: isLikedByMe
                                ? Colors.redAccent
                                : Colors.white.withOpacity(0.4),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "$postLikeCount",
                            style: TextStyle(
                              fontSize: 11,
                              color: isLikedByMe
                                  ? Colors.redAccent
                                  : Colors.white.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuPopup() {
    return PopupMenuButton<String>(
      icon: const Icon(LucideIcons.moreVertical, color: Colors.white),
      color: const Color(0xFF1A1A35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      onSelected: (value) async {
        switch (value) {
          case 'logout':
            _handleLogout();
            break;
          case 'help':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HelpCenterPage(userData: widget.userData),
              ),
            );
            break;
          case 'personalized':
            final newInterests = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    PersonalizedPage(userData: widget.userData),
              ),
            );
            if (newInterests != null)
              setState(() {
                widget.userData['interests'] = newInterests;
              });
            break;
          case 'reports':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    MyReportListPage(userData: widget.userData),
              ),
            );
            break;
        }
      },
      itemBuilder: (context) => [
        _buildPopupItem(
          'personalized',
          Icons.auto_awesome,
          "Personalized",
          Colors.cyanAccent,
        ),
        _buildPopupItem(
          'reports',
          Icons.description_outlined,
          "My Reports",
          Colors.white,
        ),
        _buildPopupItem(
          'help',
          Icons.help_outline,
          "Help Center",
          Colors.white,
        ),
        _buildPopupItem('logout', Icons.logout, "Logout", Colors.redAccent),
      ],
    );
  }

  PopupMenuItem<String> _buildPopupItem(
    String value,
    IconData icon,
    String text,
    Color color,
  ) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color.withOpacity(0.8), size: 20),
          const SizedBox(width: 12),
          Text(text, style: TextStyle(color: color)),
        ],
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          count,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5)),
        ),
      ],
    );
  }
}
