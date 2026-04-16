import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:recommended_restaurant_entertainment/searchModule/search_entry.dart';
import '../postModule/post_detail.dart';
import '../language_provider.dart';

class DiscoverPage extends StatefulWidget {
  final Map<String, dynamic> currentUserData;
  const DiscoverPage({super.key, required this.currentUserData});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  List<Map<String, dynamic>> _posts = [];
  bool _isLoading = true;

  // realtime
  RealtimeChannel? _discoverSyncChannel;

  @override
  void initState() {
    super.initState();
    _fetchPersonalizedAiFeed();
    _setupRealtime(); // Initialize the realtime listener
  }

  @override
  void dispose() {
    // DISPOSE REALTIME CHANNEL
    if (_discoverSyncChannel != null) {
      Supabase.instance.client.removeChannel(_discoverSyncChannel!);
    }
    super.dispose();
  }

  // REALTIME LOGIC
  void _setupRealtime() {
    _discoverSyncChannel = Supabase.instance.client
        .channel('discover_sync')
        .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'likes',
        callback: (payload) => _fetchPersonalizedAiFeed())
        .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'comments',
        callback: (payload) => _fetchPersonalizedAiFeed());

    _discoverSyncChannel!.subscribe();
  }

  String get _postSelectQuery => '''
    *, 
    profiles(username, profile_url), 
    likes(count), 
    comments(count),
    user_liked:likes(profile_id)
  ''';

  Future<void> _fetchStandardFeed() async {
    try {
      final supabase = Supabase.instance.client;
      final currentUserId = widget.currentUserData['id'];

      final response = await supabase
          .from('posts')
          .select(_postSelectQuery)
          .eq('user_liked.profile_id', currentUserId)
          .order('created_at', ascending: false)
          .limit(20);

      if (mounted) {
        setState(() {
          _posts = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Standard Feed Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchPersonalizedAiFeed() async {
    if (_posts.isEmpty) setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final currentUserId = widget.currentUserData['id'];

      final profileResponse = await supabase
          .from('profiles')
          .select('interest_analysis')
          .eq('id', currentUserId)
          .single();

      final Map<String, dynamic> rawInterests =
          profileResponse['interest_analysis'] ?? {};

      final Map<String, double> normalizedInterests = {};
      rawInterests.forEach((key, value) {
        final String lowerKey = key.toLowerCase().trim();
        final double score = (value as num).toDouble();
        normalizedInterests[lowerKey] =
            (normalizedInterests[lowerKey] ?? 0) + score;
      });

      final postsResponse = await supabase
          .from('posts')
          .select(_postSelectQuery)
          .eq('user_liked.profile_id', currentUserId);

      List<Map<String, dynamic>> allPosts =
      List<Map<String, dynamic>>.from(postsResponse);

      allPosts.sort((a, b) {
        double scoreA = 0;
        double scoreB = 0;
        final List<dynamic> catA = a['category_names'] ?? [];
        for (var cat in catA) {
          final String lowerCat = cat.toString().toLowerCase().trim();
          scoreA += normalizedInterests[lowerCat] ?? 0;
        }
        final List<dynamic> catB = b['category_names'] ?? [];
        for (var cat in catB) {
          final String lowerCat = cat.toString().toLowerCase().trim();
          scoreB += normalizedInterests[lowerCat] ?? 0;
        }
        final int likesA = (a['likes'] as List?)?.isNotEmpty == true
            ? a['likes'][0]['count'] ?? 0
            : 0;
        final int likesB = (b['likes'] as List?)?.isNotEmpty == true
            ? b['likes'][0]['count'] ?? 0
            : 0;
        final int commA = (a['comments'] as List?)?.isNotEmpty == true
            ? a['comments'][0]['count'] ?? 0
            : 0;
        final int commB = (b['comments'] as List?)?.isNotEmpty == true
            ? b['comments'][0]['count'] ?? 0
            : 0;

        scoreA += (likesA * 0.5) + (commA * 1.0);
        scoreB += (likesB * 0.5) + (commB * 1.0);
        return scoreB.compareTo(scoreA);
      });

      if (mounted) {
        setState(() {
          _posts = allPosts;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Hybrid AI Feed Error: $e");
      _fetchStandardFeed();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Access the language provider
    final lp = Provider.of<LanguageProvider>(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
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
        child: Stack(
          children: [
            Positioned(
              top: 100,
              right: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.blueAccent.withOpacity(0.15),
                        blurRadius: 100,
                        spreadRadius: 50)
                  ],
                ),
              ),
            ),
            SafeArea(
              child: _isLoading && _posts.isEmpty
                  ? const Center(
                  child: CircularProgressIndicator(color: Colors.white))
                  : RefreshIndicator(
                onRefresh: _fetchPersonalizedAiFeed,
                color: Colors.blueAccent,
                backgroundColor: Colors.white,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    _buildGlassAppBar(lp),
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: _posts.isEmpty
                          ? SliverFillRemaining(child: _buildEmptyState(lp))
                          : SliverGrid(
                        gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 15,
                          mainAxisSpacing: 15,
                          childAspectRatio: 0.7,
                        ),
                        delegate: SliverChildBuilderDelegate(
                              (context, index) =>
                              _discoverCard(_posts[index]),
                          childCount: _posts.length,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassAppBar(LanguageProvider lp) {
    return SliverAppBar(
      floating: true,
      backgroundColor: Colors.white.withOpacity(0.05),
      elevation: 0,
      centerTitle: true,
      title: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Text(
            lp.getString('discover'), // TRANSLATED TITLE
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(LucideIcons.search, color: Colors.white),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    SearchEntryPage(currentUserData: widget.currentUserData)),
          ),
        ),
      ],
    );
  }

  Widget _discoverCard(Map<String, dynamic> post) {
    final profile = post['profiles'] ?? {};
    final media = post['media_urls'] as List? ?? [];
    final int likeCount = (post['likes'] as List?)?.isNotEmpty == true
        ? post['likes'][0]['count'] ?? 0
        : 0;
    final int commentCount = (post['comments'] as List?)?.isNotEmpty == true
        ? post['comments'][0]['count'] ?? 0
        : 0;
    final bool isLikedByMe = (post['user_liked'] as List?)?.isNotEmpty ?? false;

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostDetailPage(
              post: post,
              userName: profile['username'] ?? 'User',
              viewerProfileId: widget.currentUserData['id'],
            ),
          ),
        );
        _fetchPersonalizedAiFeed();
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(25),
              border:
              Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(6),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        media.isNotEmpty
                            ? media[0]
                            : "https://picsum.photos/400/500",
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
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
                            color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 10,
                            backgroundColor: Colors.white24,
                            backgroundImage: (profile['profile_url'] != null)
                                ? NetworkImage(profile['profile_url'])
                                : null,
                            child: (profile['profile_url'] == null)
                                ? const Icon(Icons.person,
                                size: 10, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              profile['username'] ?? "User",
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.white70),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(LucideIcons.messageCircle,
                              size: 12, color: Colors.white.withOpacity(0.5)),
                          const SizedBox(width: 2),
                          Text("$commentCount",
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.white)),
                          const SizedBox(width: 6),
                          Icon(
                            isLikedByMe ? Icons.favorite : Icons.favorite_border,
                            size: 13,
                            color: isLikedByMe
                                ? Colors.redAccent
                                : Colors.white.withOpacity(0.5),
                          ),
                          const SizedBox(width: 2),
                          Text("$likeCount",
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.white)),
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

  Widget _buildEmptyState(LanguageProvider lp) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.ghost,
              size: 60, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(
            lp.getString('no_posts_area'), // TRANSLATED EMPTY STATE
            style: const TextStyle(color: Colors.white60, fontSize: 16),
          ),
        ],
      ),
    );
  }
}