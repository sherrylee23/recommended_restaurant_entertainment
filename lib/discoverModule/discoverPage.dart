import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
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

  Future<void> _fetchPersonalizedAiFeed() async {
    try {
      final supabase = Supabase.instance.client;
      final currentUserId = widget.currentUserData['id']; // Get current user ID

      final List<String> interests = List<String>.from(widget.currentUserData['interests'] ?? []);

      // MODIFIED Query: Added user_liked check to see if current user liked the post
      final response = await supabase
          .from('posts')
          .select('''
            *, 
            profiles(username, profile_url), 
            likes(count),
            user_liked:likes(profile_id)
          ''')
          .eq('user_liked.profile_id', currentUserId) // Filters the user_liked subquery
          .order('created_at', ascending: false)
          .limit(50);

      List<Map<String, dynamic>> pool = List<Map<String, dynamic>>.from(response);

      if (pool.isEmpty) {
        if (mounted) setState(() { _posts = []; _isLoading = false; });
        return;
      }

      // AI Logic (Gemini re-ranking)
      if (interests.isNotEmpty) {
        try {
          final model = GenerativeModel(
            model: 'gemini-1.5-flash',
            apiKey: 'YOUR_GEMINI_API_KEY',
          );

          String postMetaData = pool.take(20).map((p) =>
          "ID:${p['id']} | Title:${p['title']} | Categories:${(p['category_names'] as List?)?.join(', ')}"
          ).join("\n");

          final prompt = """
          User Profile Interests: ${interests.join(', ')}.
          From the list below, pick the top 15 post IDs that match the user's vibe.
          Return ONLY a comma-separated list of IDs.
          
          Posts:
          $postMetaData
          """;

          final content = [Content.text(prompt)];
          final aiResponse = await model.generateContent(content);

          final recommendedIds = aiResponse.text?.split(',')
              .map((e) => e.trim())
              .toList() ?? [];

          pool.sort((a, b) {
            int indexA = recommendedIds.indexOf(a['id'].toString());
            int indexB = recommendedIds.indexOf(b['id'].toString());
            int weightA = indexA == -1 ? 100 : indexA;
            int weightB = indexB == -1 ? 100 : indexB;
            return weightA.compareTo(weightB);
          });
        } catch (aiError) {
          debugPrint("Gemini failed: $aiError");
          pool.shuffle();
        }
      } else {
        pool.shuffle();
      }

      if (mounted) {
        setState(() {
          _posts = pool;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Global Feed Error: $e");
      if (mounted) setState(() => _isLoading = false);
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
      body: RefreshIndicator(
        onRefresh: _fetchPersonalizedAiFeed,
        color: Colors.blueAccent,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _posts.isEmpty
            ? _buildEmptyState()
            : GridView.builder(
          padding: const EdgeInsets.all(12),
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
    final int likeCount = (post['likes'] as List?)?.isNotEmpty == true
        ? post['likes'][0]['count'] ?? 0
        : 0;

    // MATCHED: Logic from UserProfilePage to check if current user liked the post
    final bool isLikedByMe = (post['user_liked'] as List?)?.isNotEmpty ?? false;

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
        if (result == true) _fetchPersonalizedAiFeed(); // Refresh on return
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                child: Image.network(
                  media.isNotEmpty ? media[0] : "https://picsum.photos/400/500",
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey.shade100, child: const Icon(LucideIcons.image, color: Colors.grey)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(post['title'] ?? "Untitled", maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 10,
                        backgroundImage: profile['profile_url'] != null ? NetworkImage(profile['profile_url']) : null,
                        child: profile['profile_url'] == null ? const Icon(Icons.person, size: 10) : null,
                      ),
                      const SizedBox(width: 6),
                      Expanded(child: Text(profile['username'] ?? "User", style: const TextStyle(fontSize: 11, color: Colors.black54), overflow: TextOverflow.ellipsis)),
                      // MATCHED: Heart icon now changes style based on isLikedByMe
                      Icon(
                          isLikedByMe ? Icons.favorite : Icons.favorite_border,
                          size: 14,
                          color: isLikedByMe ? Colors.redAccent : Colors.grey
                      ),
                      const SizedBox(width: 2),
                      Text("$likeCount", style: const TextStyle(fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(LucideIcons.searchX, size: 50, color: Colors.grey),
          SizedBox(height: 10),
          Text("No posts found in database.", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}