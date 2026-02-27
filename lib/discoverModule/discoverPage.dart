import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:recommended_restaurant_entertainment/searchModule/search_entry.dart';
import '../postModule/post_detail.dart';

class DiscoverPage extends StatefulWidget {
  final Map<String, dynamic> currentUserData;

  const DiscoverPage({super.key, required this.currentUserData});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  List<Map<String, dynamic>> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPersonalizedAiFeed();
  }

  // Fallback feed if AI logic fails
  Future<void> _fetchStandardFeed() async {
    try {
      final supabase = Supabase.instance.client;
      // Fetching basic list with likes and comments counts
      final response = await supabase
          .from('posts')
          .select('*, profiles(username, profile_url), likes(count), comments(count)')
          .order('created_at', ascending: false)
          .limit(20);

      setState(() {
        _posts = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Standard Feed Error: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchPersonalizedAiFeed() async {
    if (_posts.isEmpty) {
      setState(() => _isLoading = true);
    }

    try {
      final supabase = Supabase.instance.client;
      final currentUserId = widget.currentUserData['id'];

      // Fetch user interests for sorting
      final profileResponse = await supabase
          .from('profiles')
          .select('interest_analysis')
          .eq('id', currentUserId)
          .single();

      final Map<String, dynamic> interests = profileResponse['interest_analysis'] ?? {};

      // Fetch all posts with engagement counts
      final postsResponse = await supabase
          .from('posts')
          .select('''
            *, 
            profiles(username, profile_url), 
            likes(count), 
            comments(count)
          ''');

      List<Map<String, dynamic>> allPosts = List<Map<String, dynamic>>.from(postsResponse);

      allPosts.sort((a, b) {
        double scoreA = 0;
        double scoreB = 0;

        // Interest Match Scoring
        final List<dynamic> categoriesA = a['category_names'] ?? [];
        for (var cat in categoriesA) {
          scoreA += (interests[cat.toString()] ?? 0).toDouble();
        }

        final List<dynamic> categoriesB = b['category_names'] ?? [];
        for (var cat in categoriesB) {
          scoreB += (interests[cat.toString()] ?? 0).toDouble();
        }

        // Engagement Scoring
        final int likesA = (a['likes'] as List?)?.isNotEmpty == true
            ? a['likes'][0]['count'] ?? 0 : 0;
        final int likesB = (b['likes'] as List?)?.isNotEmpty == true
            ? b['likes'][0]['count'] ?? 0 : 0;

        final int commentsA = (a['comments'] as List?)?.isNotEmpty == true
            ? a['comments'][0]['count'] ?? 0 : 0;
        final int commentsB = (b['comments'] as List?)?.isNotEmpty == true
            ? b['comments'][0]['count'] ?? 0 : 0;

        // AI Logic: Weighting comments (1.0) higher than likes (0.5)
        scoreA += (likesA * 0.5) + (commentsA * 1.0);
        scoreB += (likesB * 0.5) + (commentsB * 1.0);

        return scoreB.compareTo(scoreA);
      });

      setState(() {
        _posts = allPosts;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Hybrid AI Feed Error: $e");
      _fetchStandardFeed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Discover', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
          IconButton(
            icon: const Icon(LucideIcons.search, color: Colors.black),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SearchEntryPage(currentUserData: widget.currentUserData))),
          ),
        ],
      ),
      body: _isLoading && _posts.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _fetchPersonalizedAiFeed,
        color: Colors.blueAccent,
        child: _posts.isEmpty
            ? _buildEmptyState()
            : GridView.builder(
          padding: const EdgeInsets.all(12),
          physics: const AlwaysScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.68,
          ),
          itemCount: _posts.length,
          itemBuilder: (context, index) => _discoverCard(_posts[index]),
        ),
      ),
    );
  }

  Widget _discoverCard(Map<String, dynamic> post) {
    final profile = post['profiles'] ?? {};
    final media = post['media_urls'] as List? ?? [];

    // Engagement counts
    final int likeCount = (post['likes'] as List?)?.isNotEmpty == true
        ? post['likes'][0]['count'] ?? 0
        : 0;

    final int commentCount = (post['comments'] as List?)?.isNotEmpty == true
        ? post['comments'][0]['count'] ?? 0
        : 0;

    final int postIndex = _posts.indexOf(post);
    final bool isAiTopPick = postIndex < 4 && postIndex != -1;

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostDetailPage(
              post: post,
              userName: profile['username'] ?? 'User',
              viewerProfileId: widget.currentUserData['id'],
            ),
          ),
        );
        if (result == true) _fetchPersonalizedAiFeed();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Image.network(
                      media.isNotEmpty ? media[0] : "https://picsum.photos/400/500",
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            post['title'] ?? "Untitled",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 9,
                                backgroundImage: (profile['profile_url'] != null && profile['profile_url'].toString().isNotEmpty)
                                    ? NetworkImage(profile['profile_url']) : null,
                                child: (profile['profile_url'] == null || profile['profile_url'].toString().isEmpty)
                                    ? const Icon(Icons.person, size: 10) : null,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  profile['username'] ?? "User",
                                  style: const TextStyle(fontSize: 10, color: Colors.black54),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // Comment Count Display
                              const Icon(Icons.mode_comment_outlined, size: 12, color: Colors.grey),
                              const SizedBox(width: 2),
                              Text("$commentCount", style: const TextStyle(fontSize: 10)),
                              const SizedBox(width: 6),
                              // Like Count Display
                              const Icon(Icons.favorite_border, size: 12, color: Colors.grey),
                              const SizedBox(width: 2),
                              Text("$likeCount", style: const TextStyle(fontSize: 10)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (isAiTopPick)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.blueAccent, Colors.purpleAccent.shade100]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.auto_awesome, color: Colors.white, size: 10),
                        SizedBox(width: 4),
                        Text("FOR YOU", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.searchX, size: 50, color: Colors.grey),
          SizedBox(height: 10),
          Text("No posts found.", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}