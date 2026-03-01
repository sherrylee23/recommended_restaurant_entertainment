import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../postModule/post_detail.dart';

class SearchResultsPage extends StatefulWidget {
  final String query;
  final Map<String, dynamic> currentUserData;

  const SearchResultsPage({
    super.key,
    required this.query,
    required this.currentUserData,
  });

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  bool _isLoading = true;
  bool _showFilterBar = true;
  List<Map<String, dynamic>> _results = [];
  String _selectedSort = 'All';

  @override
  void initState() {
    super.initState();
    _performSearch();
  }

  // --- MODIFIED SEARCH LOGIC: Enhanced Category Array Overlap ---
  Future<void> _performSearch() async {
    try {
      final supabase = Supabase.instance.client;
      final String q = widget.query.trim();
      final profileId = widget.currentUserData['id'];

      // 1. FORMATTING LOGIC: Prepare variants for the category array
      // Postgres array search is case-sensitive. We generate variants to ensure
      // multi-word categories like "Theme Park" or "Street Food" are caught.
      final String lowerQ = q.toLowerCase();

      // Title Case every word: "theme park" -> "Theme Park"
      final String titleCaseQ = q.isNotEmpty
          ? q.split(' ').map((word) => word.isNotEmpty
          ? word[0].toUpperCase() + word.substring(1).toLowerCase()
          : '').join(' ')
          : q;

      // 2. OMNI-SEARCH QUERY
      // We use .ov (overlap) instead of .cs (contains) to check against multiple variants.
      dynamic queryBuilder = supabase
          .from('posts')
          .select('''
            *, 
            profiles(username, profile_url),
            likes(count),
            comments(count),
            user_liked:likes(profile_id)
          ''')
          .eq('user_liked.profile_id', profileId)
      // SEARCH LOGIC: Title OR Location OR Category Overlap (ov)
          .or('title.ilike.%$q%,location_name.ilike.%$q%,category_names.ov.{"$titleCaseQ","$q","$lowerQ"}');

      // Handle Sorting Logic
      if (_selectedSort == 'Top Rated') {
        queryBuilder = queryBuilder.order('rating', ascending: false);
      } else {
        queryBuilder = queryBuilder.order('created_at', ascending: false);
      }

      final data = await queryBuilder;
      List<Map<String, dynamic>> fetchedResults = List<Map<String, dynamic>>.from(data);

      // Client-side sort for 'Most Liked' as complex joins can be slow to sort on DB
      if (_selectedSort == 'Most Liked') {
        fetchedResults.sort((a, b) {
          final int countA = (a['likes'] as List).isNotEmpty ? a['likes'][0]['count'] ?? 0 : 0;
          final int countB = (b['likes'] as List).isNotEmpty ? b['likes'][0]['count'] ?? 0 : 0;
          return countB.compareTo(countA);
        });
      }

      if (mounted) {
        setState(() {
          _results = fetchedResults;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Search error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Results for '${widget.query}'",
            style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: Icon(_showFilterBar ? LucideIcons.filterX : LucideIcons.filter),
              onPressed: () => setState(() => _showFilterBar = !_showFilterBar),
            ),
        ],
      ),
      body: Column(
        children: [
          if (_showFilterBar && !_isLoading) _buildTopCategoryBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                ? _buildNoResults()
                : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.68,
              ),
              itemCount: _results.length,
              itemBuilder: (context, index) => _buildResultCard(_results[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopCategoryBar() {
    final options = ['All', 'Latest', 'Top Rated', 'Most Liked'];
    return Container(
      height: 55,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: options.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedSort == options[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            child: ChoiceChip(
              label: Text(options[index]),
              selected: isSelected,
              onSelected: (val) {
                if (val) {
                  setState(() {
                    _selectedSort = options[index];
                    _isLoading = true;
                  });
                  _performSearch();
                }
              },
              selectedColor: Colors.red.shade50,
              labelStyle: TextStyle(
                color: isSelected ? Colors.red : Colors.black87,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              backgroundColor: Colors.grey.shade100,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              side: BorderSide(color: isSelected ? Colors.red.shade200 : Colors.transparent),
              showCheckmark: false,
            ),
          );
        },
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.searchX, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text("No related posts found.", style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildResultCard(Map<String, dynamic> post) {
    final profile = post['profiles'] ?? {};
    final String authorName = profile['username'] ?? 'User';
    final List media = post['media_urls'] ?? [];
    final String? profileUrl = profile['profile_url']?.toString();

    final int postLikeCount = (post['likes'] as List).isNotEmpty
        ? (post['likes'] as List).first['count'] ?? 0 : 0;

    final int postCommentCount = (post['comments'] as List).isNotEmpty
        ? (post['comments'] as List).first['count'] ?? 0 : 0;

    final bool isLikedByMe = (post['user_liked'] as List).isNotEmpty;

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PostDetailPage(
              post: post,
              userName: authorName,
              viewerProfileId: widget.currentUserData['id'],
            ),
          ),
        );
        _performSearch();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                child: media.isNotEmpty
                    ? Image.network(media[0], width: double.infinity, fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey.shade100, child: const Icon(LucideIcons.image, color: Colors.grey)))
                    : Container(color: Colors.grey.shade100, child: const Icon(LucideIcons.image, color: Colors.grey)),
              ),
            ),
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
                        backgroundImage: profileUrl != null && profileUrl.isNotEmpty
                            ? NetworkImage(profileUrl) : null,
                        child: (profileUrl == null || profileUrl.isEmpty)
                            ? const Icon(Icons.person, size: 10) : null,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          authorName,
                          style: const TextStyle(fontSize: 11, color: Colors.black54),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.mode_comment_outlined, size: 12, color: Colors.grey),
                      const SizedBox(width: 2),
                      Text("$postCommentCount", style: const TextStyle(fontSize: 10)),
                      const SizedBox(width: 5),
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
  }
}