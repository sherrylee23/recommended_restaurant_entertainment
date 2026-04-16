import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:recommended_restaurant_entertainment/postModule/post_detail.dart';
import '../language_provider.dart';

class CommentNotificationPage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const CommentNotificationPage({super.key, required this.userData});

  @override
  State<CommentNotificationPage> createState() => _CommentNotificationPageState();
}

class _CommentNotificationPageState extends State<CommentNotificationPage> {
  final _supabase = Supabase.instance.client;
  Key _refreshKey = UniqueKey();

  Future<void> _handleRefresh() async {
    setState(() { _refreshKey = UniqueKey(); });
    await Future.delayed(const Duration(milliseconds: 500));
  }

  String _formatDate(String? timestamp) {
    if (timestamp == null) return "";
    try {
      final DateTime dt = DateTime.parse(timestamp).toLocal();
      return DateFormat('MMM d, h:mm a').format(dt);
    } catch (e) { return ""; }
  }

  @override
  Widget build(BuildContext context) {
    final lp = Provider.of<LanguageProvider>(context); // Access Provider
    final String? userId = widget.userData['id']?.toString();

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF0F0C29),
      appBar: AppBar(
        title: Text(
          lp.getString('comments_title'), // TRANSLATED
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: Colors.blueAccent,
          backgroundColor: const Color(0xFF16162E),
          child: userId == null
              ? _buildErrorState(lp.getString('user_session_invalid')) // TRANSLATED
              : _buildNotificationStream(userId, lp),
        ),
      ),
    );
  }

  Widget _buildNotificationStream(String userId, LanguageProvider lp) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      key: _refreshKey,
      stream: _supabase.from('notifications').stream(primaryKey: ['id']).eq('user_id', userId),
      builder: (context, snapshot) {
        if (snapshot.hasError) return _buildErrorState("Error: ${snapshot.error}");
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
        }

        final notifications = snapshot.data ?? [];
        if (notifications.isEmpty) return _buildEmptyState(lp);

        // Sort newest first
        final sortedList = List<Map<String, dynamic>>.from(notifications);
        sortedList.sort((a, b) => (b['created_at'] ?? "").compareTo(a['created_at'] ?? ""));

        return ListView.builder(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 70,
            left: 20, right: 20, bottom: 20,
          ),
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: sortedList.length,
          itemBuilder: (context, index) {
            final item = sortedList[index];
            final bool isRead = item['is_read'] ?? false;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isRead ? Colors.white.withOpacity(0.03) : Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isRead ? Colors.white.withOpacity(0.05) : Colors.blueAccent.withOpacity(0.3),
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isRead ? Colors.white.withOpacity(0.05) : Colors.blueAccent.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          LucideIcons.messageSquare,
                          color: isRead ? Colors.white24 : Colors.blueAccent,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        item['content'] ?? lp.getString('new_comment_notif'), // TRANSLATED FALLBACK
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isRead ? Colors.white60 : Colors.white,
                          fontSize: 14,
                          fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          _formatDate(item['created_at']),
                          style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.3)),
                        ),
                      ),
                      trailing: !isRead
                          ? Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.orangeAccent,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.orangeAccent, blurRadius: 6)],
                        ),
                      )
                          : null,
                      onTap: () => _handleNotificationTap(item, userId, lp),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // UI

  Widget _buildEmptyState(LanguageProvider lp) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
        Icon(LucideIcons.messageCircle, size: 60, color: Colors.white.withOpacity(0.1)),
        const SizedBox(height: 20),
        Center(
          child: Text(
            lp.getString('no_comments_yet'), // TRANSLATED
            style: const TextStyle(color: Colors.white38, fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(String error) {
    return Center(child: Text(error, style: const TextStyle(color: Colors.white54)));
  }

  // tap logic
  Future<void> _handleNotificationTap(Map<String, dynamic> item, String userId, LanguageProvider lp) async {
    try {
      await _supabase.from('notifications').update({'is_read': true}).eq('id', item['id']);
      if (item['related_post_id'] == null) return;

      final postData = await _supabase
          .from('posts')
          .select('*, profiles(username, profile_url)')
          .eq('id', item['related_post_id'])
          .maybeSingle();

      if (postData == null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(lp.getString('post_unavailable')), behavior: SnackBarBehavior.floating));
        return;
      }

      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostDetailPage(
              post: postData,
              userName: postData['profiles']?['username'] ?? 'User',
              viewerProfileId: userId,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }
}