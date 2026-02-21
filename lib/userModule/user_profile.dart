import 'package:flutter/material.dart';
import 'edit_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:recommended_restaurant_entertainment/loginModule/login_page.dart';
import 'dart:math';
import 'help_center.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../postModule/post_detail.dart';
import 'package:recommended_restaurant_entertainment/userModule/personalized.dart';

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

  Future<void> refreshPosts() async {
    try {
      final supabase = Supabase.instance.client;
      final profileId = widget.userData['id'];

      final postsData = await supabase
          .from('posts')
          .select('''
            *,
            likes(count),
            user_liked:likes(profile_id)
          ''')
          .eq('profile_id', profileId)
          .eq('user_liked.profile_id', profileId)
          .order('created_at', ascending: false);

      int likesSum = 0;
      if (postsData.isNotEmpty) {
        for (var post in postsData) {
          final list = post['likes'] as List;
          if (list.isNotEmpty) {
            likesSum += (list.first['count'] as int);
          }
        }
      }

      if (mounted) {
        setState(() {
          _userPosts = List<Map<String, dynamic>>.from(postsData);
          _totalLikes = likesSum;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching posts or likes: $e");
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Logout failed: ${e.toString()}"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String username = widget.userData['username'] ?? "User";
    final String userId = widget.userData['id']?.toString() ?? "0";

    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(username, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [_buildMenuPopup()],
      ),
      body: RefreshIndicator(
        onRefresh: refreshPosts,
        color: Colors.blueAccent,
        backgroundColor: Colors.white,
        displacement: 100,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
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
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      _buildProfileHeader(username, userId),
                      const SizedBox(height: 20),
                      _buildStatsAndEditRow(),
                      const SizedBox(height: 25),
                    ],
                  ),
                ),
              ),
              Container(
                color: Colors.white,
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 15),
                      child: Text("MY POSTS", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 12)),
                    ),
                    _buildPostGrid(username),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostGrid(String username) {
    if (_isLoading) return const Padding(padding: EdgeInsets.all(50), child: Center(child: CircularProgressIndicator()));

    if (_userPosts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(100),
        child: Center(child: Text("No posts yet.", style: TextStyle(color: Colors.grey))),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.68, // MATCHED: From Discover Page
      ),
      itemCount: _userPosts.length,
      itemBuilder: (context, index) {
        final post = _userPosts[index];
        final List<dynamic> media = post['media_urls'] ?? [];
        final String profileUrl = widget.userData['profile_url'] ?? "";

        final int postLikeCount = (post['likes'] as List).isNotEmpty
            ? (post['likes'] as List).first['count'] ?? 0
            : 0;

        final bool isLikedByMe = (post['user_liked'] as List).isNotEmpty;

        return GestureDetector(
          onTap: () async {
            final Map<String, dynamic> postWithProfile = Map.from(post);
            postWithProfile['profiles'] = {
              'profile_url': widget.userData['profile_url'],
              'username': username,
            };

            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PostDetailPage(
                  post: postWithProfile,
                  userName: username,
                  viewerProfileId: widget.userData['id'],
                ),
              ),
            );
            if (result == true) refreshPosts();
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15), // MATCHED
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05), // MATCHED
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // MATCHED: Image Section using Expanded and BoxFit.cover
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                    child: media.isNotEmpty
                        ? Image.network(
                      media[0],
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey.shade100,
                        child: const Icon(LucideIcons.image, color: Colors.grey),
                      ),
                    )
                        : Container(
                      color: Colors.grey.shade100,
                      width: double.infinity,
                      child: const Icon(LucideIcons.image, color: Colors.grey),
                    ),
                  ),
                ),
                // MATCHED: Text and Stats Section
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post['title'] ?? "Untitled",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 10,
                            backgroundImage: profileUrl.isNotEmpty ? NetworkImage(profileUrl) : null,
                            child: profileUrl.isEmpty ? const Icon(Icons.person, size: 10) : null,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              username,
                              style: const TextStyle(fontSize: 11, color: Colors.black54),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            isLikedByMe ? Icons.favorite : Icons.favorite_border,
                            size: 14,
                            color: isLikedByMe ? Colors.redAccent : Colors.grey,
                          ),
                          const SizedBox(width: 2),
                          Text("$postLikeCount", style: const TextStyle(fontSize: 11)),
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
      icon: const Icon(Icons.menu, color: Colors.black87),
      onSelected: (value) async {
        if (value == 'logout') {
          _handleLogout();
        } else if (value == 'help') {
          Navigator.push(context,
              MaterialPageRoute(
                  builder: (context) => HelpCenterPage(userData: widget.userData)));
        } else if (value == 'personalized') {
          final newInterests = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PersonalizedPage(userData: widget.userData)),
          );
          if (newInterests != null) {
            setState(() {
              widget.userData['interests'] = newInterests;
            });
          }
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'personalized',
          child: Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.blueAccent),
              SizedBox(width: 10),
              Text("AI Personalized"),
            ],
          ),
        ),
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
    if (gender == "female") { genderIcon = Icons.female; genderColor = Colors.pinkAccent; }
    else if (gender == "male") { genderIcon = Icons.male; genderColor = Colors.blueAccent; }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 45,
            backgroundColor: Colors.white,
            backgroundImage: profileUrl != null && profileUrl.isNotEmpty ? NetworkImage(profileUrl) : null,
            child: profileUrl == null || profileUrl.isEmpty ? const Icon(Icons.face, size: 70, color: Colors.brown) : null,
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [Text(username, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(width: 5), Icon(genderIcon, size: 18, color: genderColor)]),
              Text("ID:$id", style: const TextStyle(color: Colors.black54, fontSize: 14)),
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
    String statusMessage = statusTitle == "New Users" ? "New users are limited to comment 3 reviews per day." : statusTitle == "Active Users" ? "Active users have used the system for 14+ days." : "This account is trusted.";
    return GestureDetector(
      onTap: () => showDialog(context: context, builder: (context) => AlertDialog(title: Text(statusTitle), content: Text(statusMessage), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))])),
      child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(5)), child: Row(mainAxisSize: MainAxisSize.min, children: [Text(statusTitle, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)), const SizedBox(width: 4), const Icon(Icons.info_outline, size: 12)])),
    );
  }

  Widget _buildStatsAndEditRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [_StatItem(label: "Posts", count: _userPosts.length.toString()), const SizedBox(width: 30), _StatItem(label: "Likes", count: _totalLikes.toString())]),
          ElevatedButton(
            onPressed: () async {
              final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => EditProfilePage(userData: widget.userData)));
              if (result != null && result is Map<String, dynamic>) setState(() { widget.userData.addAll(result); });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.9), foregroundColor: Colors.black87, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey.shade300))),
            child: const Text("Edit Profile", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
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
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(count, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54))]);
  }
}