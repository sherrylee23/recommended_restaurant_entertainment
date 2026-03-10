import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'edit_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:recommended_restaurant_entertainment/loginModule/login_page.dart';
import 'help_center.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../postModule/post_detail.dart';
import 'package:recommended_restaurant_entertainment/userModule/personalized.dart';
import 'package:recommended_restaurant_entertainment/customer_service/my_report.dart';
import 'package:recommended_restaurant_entertainment/userModule/browsing_history.dart';
import '../language_provider.dart';

class UserProfilePage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const UserProfilePage({super.key, required this.userData});

  @override
  State<UserProfilePage> createState() => UserProfilePageState();
}

class UserProfilePageState extends State<UserProfilePage> {
  List<Map<String, dynamic>> _userPosts = [];
  bool _isLoading = true;
  int _totalLikesReceived = 0;
  int _timelineCount = 0;
  String _activeTab = "Timeline";
  RealtimeChannel? _profileSyncChannel;

  @override
  void initState() {
    super.initState();
    refreshPosts();
    _setupRealtime();
  }

  @override
  void dispose() {
    if (_profileSyncChannel != null) {
      Supabase.instance.client.removeChannel(_profileSyncChannel!);
    }
    super.dispose();
  }

  void _setupRealtime() {
    _profileSyncChannel = Supabase.instance.client
        .channel('profile_sync')
        .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'likes',
        callback: (payload) => refreshPosts())
        .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'comments',
        callback: (payload) => refreshPosts());

    _profileSyncChannel!.subscribe();
  }

  // --- DELETE ACCOUNT LOGIC ---
  Future<void> _handleDeleteAccount(LanguageProvider lp) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: const Color(0xFF1A1A35),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.redAccent, width: 0.5)),
          title: Text(lp.getString('delete_confirm_title'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Text(lp.getString('delete_confirm_msg'), style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(lp.getString('cancel'), style: const TextStyle(color: Colors.white60))),
            TextButton(onPressed: () => Navigator.pop(context, true), child: Text(lp.getString('delete'), style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))),
          ],
        ),
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        final supabase = Supabase.instance.client;
        final profileId = widget.userData['id'];

        await supabase.from('profiles').delete().eq('id', profileId);
        await supabase.auth.signOut();

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
          );
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(lp.getString('acc_deleted')), backgroundColor: Colors.orange)
          );
        }
      } catch (e) {
        debugPrint("Delete error: $e");
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
        }
      }
    }
  }

  void _showLanguageDialog() {
    final lp = Provider.of<LanguageProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: const Color(0xFF1A1A35).withOpacity(0.9),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
              side: BorderSide(color: Colors.white.withOpacity(0.1))),
          title: Text(lp.getString('select_language'),
              style: const TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _langTile("English", "en", lp),
              _langTile("中文 (Chinese)", "zh", lp),
              _langTile("Bahasa Melayu", "ms", lp),
            ],
          ),
        ),
      ),
    );
  }

  Widget _langTile(String label, String code, LanguageProvider lp) {
    bool isSel = lp.currentLocale.languageCode == code;
    return ListTile(
      title: Text(label,
          style: TextStyle(
              color: isSel ? Colors.cyanAccent : Colors.white70,
              fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
      trailing: isSel ? const Icon(Icons.check_circle, color: Colors.cyanAccent) : null,
      onTap: () {
        lp.changeLanguage(code);
        Navigator.pop(context);
      },
    );
  }

  // Helper to get translated status title
  String _getStatusTitle(LanguageProvider lp) {
    final String? createdAtRaw = widget.userData['created_at'];
    if (createdAtRaw == null) return lp.getString('status_new');
    final DateTime createdAt = DateTime.parse(createdAtRaw);
    final int daysJoined = DateTime.now().difference(createdAt).inDays;
    if (daysJoined >= 365) return lp.getString('status_trusted');
    if (daysJoined >= 14) return lp.getString('status_active');
    return lp.getString('status_new');
  }

  void _showStatusInfoPopup(LanguageProvider lp) {
    String title = _getStatusTitle(lp);
    String description = "";

    if (title == lp.getString('status_trusted')) {
      description = lp.getString('desc_trusted');
    } else if (title == lp.getString('status_active')) {
      description = lp.getString('desc_active');
    } else {
      description = lp.getString('desc_new');
    }

    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: const Color(0xFF16162E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.blueAccent, width: 0.5)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          content: Text(description, style: const TextStyle(fontSize: 14, color: Colors.white70)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(lp.getString('got_it'), style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold))),
          ],
        ),
      ),
    );
  }

  Future<void> refreshPosts() async {
    try {
      final supabase = Supabase.instance.client;
      final profileId = widget.userData['id'];

      if (_activeTab == "Timeline") {
        final postsData = await supabase
            .from('posts')
            .select('*, likes(count), comments(count), user_liked:likes(profile_id)')
            .eq('profile_id', profileId)
            .eq('user_liked.profile_id', profileId)
            .order('created_at', ascending: false);

        int likesSum = 0;
        for (var post in postsData) {
          final likesList = post['likes'] as List?;
          if (likesList != null && likesList.isNotEmpty) {
            likesSum += (likesList.first['count'] as int? ?? 0);
          }
        }

        if (mounted) {
          setState(() {
            _userPosts = List<Map<String, dynamic>>.from(postsData);
            _timelineCount = _userPosts.length;
            _totalLikesReceived = likesSum;
            _isLoading = false;
          });
        }
      } else {
        final timelineResponse = await supabase.from('posts').select('id').eq('profile_id', profileId);
        final likedData = await supabase
            .from('likes')
            .select('post_id, posts(*, profiles(username, profile_url), likes(count), comments(count), user_liked:likes(profile_id))')
            .eq('profile_id', profileId)
            .eq('posts.user_liked.profile_id', profileId)
            .order('created_at', ascending: false);

        if (mounted) {
          setState(() {
            _userPosts = List<Map<String, dynamic>>.from(likedData.map((item) => item['posts']).where((p) => p != null));
            _timelineCount = timelineResponse.length;
            _isLoading = false;
          });
        }
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
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginPage()), (route) => false);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Logout failed: $e"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final lp = Provider.of<LanguageProvider>(context);
    final String username = widget.userData['username'] ?? "User";
    final String fullName = widget.userData['name'] ?? "No Name Provided";
    final String userId = widget.userData['id']?.toString() ?? "0";

    return Scaffold(
      backgroundColor: const Color(0xFF0F0C29),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(username, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [_buildMenuPopup(lp)],
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
                _buildModernHeader(fullName, userId, lp),
                _buildTabToggle(lp),
                _buildPostGrid(username, lp),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabToggle(LanguageProvider lp) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildTabItem(lp.getString('timeline'), "Timeline", LucideIcons.layoutGrid),
          const SizedBox(width: 40),
          _buildTabItem(lp.getString('likes'), "Likes", LucideIcons.heart),
        ],
      ),
    );
  }

  Widget _buildTabItem(String label, String tabKey, IconData icon) {
    bool isActive = _activeTab == tabKey;
    return GestureDetector(
      onTap: () {
        if (!isActive) {
          setState(() {
            _activeTab = tabKey;
            _isLoading = true;
            _userPosts = [];
          });
          refreshPosts();
        }
      },
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: isActive ? Colors.cyanAccent : Colors.white38),
              const SizedBox(width: 8),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  fontSize: 13,
                  color: isActive ? Colors.white : Colors.white38,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          AnimatedContainer(duration: const Duration(milliseconds: 300), height: 2, width: isActive ? 80 : 0, color: Colors.cyanAccent)
        ],
      ),
    );
  }

  Widget _buildModernHeader(String fullName, String userId, LanguageProvider lp) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: Column(
        children: [
          const SizedBox(height: kToolbarHeight + 25),
          _buildProfileAvatar(fullName, userId, lp),
          const SizedBox(height: 15),
          _buildStatsAndEditRow(lp),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(String fullName, String id, LanguageProvider lp) {
    IconData genderIcon = Icons.help_outline;
    Color genderColor = Colors.grey;
    final String gender = (widget.userData['gender'] ?? "").toString().toLowerCase();
    final String? profileUrl = widget.userData['profile_url'];
    if (gender == "female") { genderIcon = Icons.female; genderColor = Colors.pinkAccent; }
    else if (gender == "male") { genderIcon = Icons.male; genderColor = Colors.cyanAccent; }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Row(
        children: [
          _avatarCircle(profileUrl),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(children: [Flexible(child: Text(fullName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, overflow: TextOverflow.ellipsis))), const SizedBox(width: 8), Icon(genderIcon, size: 18, color: genderColor)]),
                Text("ID: $id", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
                const SizedBox(height: 6),
                _buildUserStatusBadge(lp),
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
      decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [Colors.cyanAccent, Colors.purpleAccent]), boxShadow: [BoxShadow(color: Colors.cyanAccent.withOpacity(0.3), blurRadius: 15)]),
      child: CircleAvatar(radius: 40, backgroundColor: const Color(0xFF1A1A35), backgroundImage: profileUrl != null && profileUrl.isNotEmpty ? NetworkImage(profileUrl) : null, child: profileUrl == null || profileUrl.isEmpty ? const Icon(Icons.face, size: 60, color: Colors.white24) : null),
    );
  }

  Widget _buildUserStatusBadge(LanguageProvider lp) {
    final String statusTitle = _getStatusTitle(lp);
    return GestureDetector(
      onTap: () => _showStatusInfoPopup(lp),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: Colors.cyanAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.cyanAccent.withOpacity(0.5), width: 1)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [Text(statusTitle, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.cyanAccent)), const SizedBox(width: 6), const Icon(LucideIcons.info, size: 12, color: Colors.cyanAccent)]),
      ),
    );
  }

  Widget _buildStatsAndEditRow(LanguageProvider lp) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _StatItem(label: lp.getString('posts'), count: _timelineCount.toString()),
              const SizedBox(width: 35),
              _StatItem(label: lp.getString('likes'), count: _totalLikesReceived.toString()),
            ],
          ),
          ElevatedButton(
            onPressed: () async {
              final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => EditProfilePage(userData: widget.userData)));
              if (result != null && result is Map<String, dynamic>) setState(() { widget.userData.addAll(result); });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.05), foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.white.withOpacity(0.2)))),
            child: Text(lp.getString('edit_profile'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildPostGrid(String username, LanguageProvider lp) {
    if (_isLoading) return const Padding(padding: EdgeInsets.all(50), child: Center(child: CircularProgressIndicator(color: Colors.cyanAccent)));
    if (_userPosts.isEmpty) return Padding(padding: const EdgeInsets.all(100), child: Center(child: Text(lp.getString('no_posts_found'), style: const TextStyle(color: Colors.white38))));

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(left: 16, right: 16, top: 0, bottom: 40),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.72),
      itemCount: _userPosts.length,
      itemBuilder: (context, index) {
        final post = _userPosts[index];
        final List<dynamic> media = post['media_urls'] ?? [];
        final authorProfile = _activeTab == "Timeline" ? widget.userData : (post['profiles'] ?? {});
        final String authorName = authorProfile['username'] ?? "User";
        final String authorUrl = authorProfile['profile_url'] ?? "";
        final int postLikeCount = (post['likes'] as List?)?.isNotEmpty == true ? post['likes'].first['count'] ?? 0 : 0;
        final int postCommentCount = (post['comments'] as List?)?.isNotEmpty == true ? post['comments'].first['count'] ?? 0 : 0;
        final bool isLikedByMe = (post['user_liked'] as List?)?.isNotEmpty == true;

        return GestureDetector(
          onTap: () async {
            final Map<String, dynamic> postWithProfile = Map.from(post);
            postWithProfile['profiles'] = {'profile_url': authorUrl, 'username': authorName};
            await Navigator.push(context, MaterialPageRoute(builder: (context) => PostDetailPage(post: postWithProfile, userName: authorName, viewerProfileId: widget.userData['id'])));
            refreshPosts();
          },
          child: Container(
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.1))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(20)), child: media.isNotEmpty ? Image.network(media[0], width: double.infinity, fit: BoxFit.cover) : Container(color: Colors.white10, child: const Icon(LucideIcons.image, color: Colors.white24)))),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post['title'] ?? "Untitled", maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                      const SizedBox(height: 8),
                      Row(mainAxisAlignment: MainAxisAlignment.end, children: [Icon(LucideIcons.messageCircle, size: 12, color: Colors.white.withOpacity(0.4)), const SizedBox(width: 4), Text("$postCommentCount", style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.6))), const SizedBox(width: 8), Icon(isLikedByMe ? Icons.favorite : Icons.favorite_border, size: 14, color: isLikedByMe ? Colors.redAccent : Colors.white.withOpacity(0.4)), const SizedBox(width: 4), Text("$postLikeCount", style: TextStyle(fontSize: 11, color: isLikedByMe ? Colors.redAccent : Colors.white.withOpacity(0.6)))]),
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

  Widget _buildMenuPopup(LanguageProvider lp) {
    return PopupMenuButton<String>(
      icon: const Icon(LucideIcons.moreVertical, color: Colors.white),
      color: const Color(0xFF1A1A35),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.white.withOpacity(0.1))),
      onSelected: (value) async {
        switch (value) {
          case 'history': Navigator.push(context, MaterialPageRoute(builder: (context) => BrowsingHistoryPage(userData: widget.userData))); break;
          case 'logout': _handleLogout(); break;
          case 'help': Navigator.push(context, MaterialPageRoute(builder: (context) => HelpCenterPage(userData: widget.userData))); break;
          case 'personalized':
            final newInterests = await Navigator.push(context, MaterialPageRoute(builder: (context) => PersonalizedPage(userData: widget.userData)));
            if (newInterests != null) setState(() { widget.userData['interests'] = newInterests; });
            break;
          case 'reports': Navigator.push(context, MaterialPageRoute(builder: (context) => MyReportListPage(userData: widget.userData))); break;
          case 'language': _showLanguageDialog(); break;
          case 'delete_acc': _handleDeleteAccount(lp); break;
        }
      },
      itemBuilder: (context) => [
        _buildPopupItem('personalized', Icons.auto_awesome, lp.getString('personalized'), Colors.cyanAccent),
        _buildPopupItem('reports', Icons.description_outlined, lp.getString('reports'), Colors.white),
        _buildPopupItem('history', LucideIcons.history, lp.getString('history'), Colors.white),
        _buildPopupItem('help', Icons.help_outline, lp.getString('help'), Colors.white),
        _buildPopupItem('language', LucideIcons.languages, lp.getString('language'), Colors.white),
        _buildPopupItem('delete_acc', LucideIcons.userX, lp.getString('delete_acc'), Colors.redAccent),
        _buildPopupItem('logout', Icons.logout, lp.getString('logout'), Colors.redAccent),
      ],
    );
  }

  PopupMenuItem<String> _buildPopupItem(String value, IconData icon, String text, Color color) {
    return PopupMenuItem(value: value, child: Row(children: [Icon(icon, color: color.withOpacity(0.8), size: 20), const SizedBox(width: 12), Text(text, style: TextStyle(color: color))]));
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
        Text(count, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5))),
      ],
    );
  }
}