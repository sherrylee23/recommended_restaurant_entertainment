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

  // --- COMBINED QUERY: Added comments(count) from teammate version ---
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

      setState(() {
        _posts = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Standard Feed Error: $e");
      setState(() => _isLoading = false);
    }
  }

  // --- MODIFIED AI FEED: Case-Insensitive Normalization logic ---
  Future<void> _fetchPersonalizedAiFeed() async {
    if (_posts.isEmpty) setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final currentUserId = widget.currentUserData['id'];

      // 1. Fetch user interests
      final profileResponse = await supabase
          .from('profiles')
          .select('interest_analysis')
          .eq('id', currentUserId)
          .single();

      final Map<String, dynamic> rawInterests = profileResponse['interest_analysis'] ?? {};

      // --- NORMALIZE INTERESTS TO LOWERCASE ---
      // This merges "Theme Park" and "Theme park" into one score for logic
      final Map<String, double> normalizedInterests = {};
      rawInterests.forEach((key, value) {
        final String lowerKey = key.toLowerCase().trim();
        final double score = (value as num).toDouble();
        normalizedInterests[lowerKey] = (normalizedInterests[lowerKey] ?? 0) + score;
      });

      // 2. Fetch posts
      final postsResponse = await supabase
          .from('posts')
          .select(_postSelectQuery)
          .eq('user_liked.profile_id', currentUserId);

      List<Map<String, dynamic>> allPosts = List<Map<String, dynamic>>.from(postsResponse);

      // 3. AI SORTING LOGIC
      allPosts.sort((a, b) {
        double scoreA = 0;
        double scoreB = 0;

        // --- Match Post A categories (Normalized Lowercase) ---
        final List<dynamic> catA = a['category_names'] ?? [];
        for (var cat in catA) {
          final String lowerCat = cat.toString().toLowerCase().trim();
          scoreA += normalizedInterests[lowerCat] ?? 0;
        }

        // --- Match Post B categories (Normalized Lowercase) ---
        final List<dynamic> catB = b['category_names'] ?? [];
        for (var cat in catB) {
          final String lowerCat = cat.toString().toLowerCase().trim();
          scoreB += normalizedInterests[lowerCat] ?? 0;
        }

        // Engagement weights (Included comments from teammate)
        final int likesA = (a['likes'] as List?)?.isNotEmpty == true ? a['likes'][0]['count'] ?? 0 : 0;
        final int likesB = (b['likes'] as List?)?.isNotEmpty == true ? b['likes'][0]['count'] ?? 0 : 0;
        final int commA = (a['comments'] as List?)?.isNotEmpty == true ? a['comments'][0]['count'] ?? 0 : 0;
        final int commB = (b['comments'] as List?)?.isNotEmpty == true ? b['comments'][0]['count'] ?? 0 : 0;

        scoreA += (likesA * 0.5) + (commA * 1.0);
        scoreB += (likesB * 0.5) + (commB * 1.0);

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
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SearchEntryPage(currentUserData: widget.currentUserData)),
            ),
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

    final int likeCount = (post['likes'] as List?)?.isNotEmpty == true ? post['likes'][0]['count'] ?? 0 : 0;
    final int commentCount = (post['comments'] as List?)?.isNotEmpty == true ? post['comments'][0]['count'] ?? 0 : 0;
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
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
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
                            backgroundImage: (profile['profile_url'] != null) ? NetworkImage(profile['profile_url']) : null,
                            child: (profile['profile_url'] == null) ? const Icon(Icons.person, size: 10) : null,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              profile['username'] ?? "User",
                              style: const TextStyle(fontSize: 10, color: Colors.black54),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.mode_comment_outlined, size: 12, color: Colors.grey),
                          const SizedBox(width: 2),
                          Text("$commentCount", style: const TextStyle(fontSize: 10)),
                          const SizedBox(width: 5),
                          Icon(
                            isLikedByMe ? Icons.favorite : Icons.favorite_border,
                            size: 12,
                            color: isLikedByMe ? Colors.redAccent : Colors.grey,
                          ),
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
          const SizedBox(height: 10),
          const Text("No posts found.", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}