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

  Future<void> _performSearch() async {
    try {
      final supabase = Supabase.instance.client;
      final q = widget.query.trim();
      final profileId = widget.currentUserData['id'];
      final formattedQ = q.isNotEmpty ? q[0].toUpperCase() + q.substring(1).toLowerCase() : q;

      dynamic queryBuilder = supabase
          .from('posts')
          .select('''
            *, 
            profiles(username, profile_url),
            likes(count),
            user_liked:likes(profile_id)
          ''')
          .eq('user_liked.profile_id', profileId)
          .or('title.ilike.%$q%,location_name.ilike.%$q%,category_names.cs.{"$formattedQ"}');

      if (_selectedSort == 'Top Rated') {
        queryBuilder = queryBuilder.order('rating', ascending: false);
      } else {
        queryBuilder = queryBuilder.order('created_at', ascending: false);
      }

      final data = await queryBuilder;
      List<Map<String, dynamic>> fetchedResults = List<Map<String, dynamic>>.from(data);

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
                childAspectRatio: 0.68, // MATCHED
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
        ? (post['likes'] as List).first['count'] ?? 0
        : 0;
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
          borderRadius: BorderRadius.circular(15), // MATCHED
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05), // MATCHED
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // MATCHED: Image Section using Expanded to mirror Discover/Profile
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                child: Image.network(
                  media.isNotEmpty ? media[0] : "https://picsum.photos/400/500",
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey.shade100,
                    child: const Icon(LucideIcons.image, color: Colors.grey),
                  ),
                ),
              ),
            ),
            // MATCHED: Text and Metadata Section
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
                            ? NetworkImage(profileUrl)
                            : null,
                        child: (profileUrl == null || profileUrl.isEmpty)
                            ? const Icon(Icons.person, size: 10)
                            : null,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          authorName,
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
  }
}