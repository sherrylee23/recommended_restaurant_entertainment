import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../postModule/post_detail.dart';

class BrowsingHistoryPage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const BrowsingHistoryPage({super.key, required this.userData});

  @override
  State<BrowsingHistoryPage> createState() => _BrowsingHistoryPageState();
}

class _BrowsingHistoryPageState extends State<BrowsingHistoryPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _historyPosts = [];
  RealtimeChannel? _historySyncChannel;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
    _setupRealtime();
  }

  @override
  void dispose() {
    if (_historySyncChannel != null) {
      Supabase.instance.client.removeChannel(_historySyncChannel!);
    }
    super.dispose();
  }

  void _setupRealtime() {
    _historySyncChannel = Supabase.instance.client
        .channel('history_sync')
        .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'likes',
        callback: (payload) => _fetchHistory())
        .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'comments',
        callback: (payload) => _fetchHistory());

    _historySyncChannel!.subscribe();
  }

  Future<void> _fetchHistory() async {
    try {
      final supabase = Supabase.instance.client;
      final viewerId = widget.userData['id'];

      // --- LOGIC UPDATED TO MATCH USER PROFILE ---
      // We filter the user_liked join by the current viewer's ID
      final data = await supabase
          .from('browsing_history')
          .select('''
            viewed_at, 
            posts(
              *, 
              profiles(username, profile_url), 
              likes(count), 
              comments(count), 
              user_liked:likes(profile_id)
            )
          ''')
          .eq('user_id', viewerId)
          .eq('posts.user_liked.profile_id', viewerId) // Filter likes to only show if viewer liked it
          .order('viewed_at', ascending: false);

      if (mounted) {
        setState(() {
          _historyPosts = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Fetch History Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Recent History",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
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
        child: _isLoading && _historyPosts.isEmpty
            ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
            : SafeArea(
          child: _historyPosts.isEmpty
              ? _buildEmptyState()
              : GridView.builder(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 10, bottom: 40),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.72,
            ),
            itemCount: _historyPosts.length,
            itemBuilder: (context, index) => _buildHistoryCard(_historyPosts[index]['posts']),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> post) {
    final profile = post['profiles'] ?? {};
    final List media = post['media_urls'] ?? [];

    final int postLikeCount = (post['likes'] as List?)?.isNotEmpty == true
        ? post['likes'][0]['count'] ?? 0 : 0;
    final int postCommentCount = (post['comments'] as List?)?.isNotEmpty == true
        ? post['comments'][0]['count'] ?? 0 : 0;

    // --- LOGIC MATCHED TO USER PROFILE ---
    // If user_liked list is not empty, it means the current viewer has liked it
    final bool isLikedByMe = (post['user_liked'] as List?)?.isNotEmpty == true;

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostDetailPage(
              post: post,
              userName: profile['username'] ?? 'User',
              viewerProfileId: widget.userData['id'],
            ),
          ),
        );
        _fetchHistory();
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: media.isNotEmpty
                        ? Image.network(media[0], width: double.infinity, fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.white10,
                        child: const Icon(LucideIcons.image, color: Colors.white24),
                      ),
                    )
                        : Container(
                      color: Colors.white.withOpacity(0.05),
                      child: const Icon(LucideIcons.image, color: Colors.white24),
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
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(LucideIcons.messageCircle, size: 12, color: Colors.white.withOpacity(0.4)),
                          const SizedBox(width: 4),
                          Text("$postCommentCount", style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.6))),
                          const SizedBox(width: 8),
                          // --- HEART ICON LOGIC (FULL vs EMPTY) ---
                          Icon(
                            isLikedByMe ? Icons.favorite : Icons.favorite_border,
                            size: 14,
                            color: isLikedByMe ? Colors.redAccent : Colors.white.withOpacity(0.4),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "$postLikeCount",
                            style: TextStyle(
                              fontSize: 11,
                              color: isLikedByMe ? Colors.redAccent : Colors.white.withOpacity(0.6),
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
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.history, size: 60, color: Colors.white24),
          const SizedBox(height: 16),
          const Text("No browsing history found.", style: TextStyle(color: Colors.white60)),
        ],
      ),
    );
  }
}