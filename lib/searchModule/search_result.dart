import 'dart:async';
import 'dart:ui'; // Required for Glassmorphism
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart'; // REQUIRED
import '../postModule/post_detail.dart';
import '../language_provider.dart'; // REQUIRED

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

  // --- REALTIME STATE ---
  RealtimeChannel? _searchSyncChannel;

  @override
  void initState() {
    super.initState();
    _performSearch();
    _setupRealtime(); // Initialize real-time listener
  }

  @override
  void dispose() {
    if (_searchSyncChannel != null) {
      Supabase.instance.client.removeChannel(_searchSyncChannel!);
    }
    super.dispose();
  }

  // --- REALTIME LOGIC ---
  void _setupRealtime() {
    _searchSyncChannel = Supabase.instance.client
        .channel('search_results_sync')
        .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'likes',
        callback: (payload) => _performSearch())
        .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'comments',
        callback: (payload) => _performSearch());

    _searchSyncChannel!.subscribe();
  }

  // --- LOGIC PRESERVED ---
  Future<void> _performSearch() async {
    try {
      final supabase = Supabase.instance.client;
      final String q = widget.query.trim();
      final profileId = widget.currentUserData['id'];

      final String lowerQ = q.toLowerCase();
      final String titleCaseQ = q.isNotEmpty
          ? q.split(' ').map((word) => word.isNotEmpty
          ? word[0].toUpperCase() + word.substring(1).toLowerCase()
          : '').join(' ')
          : q;

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
          .or('title.ilike.%$q%,location_name.ilike.%$q%,category_names.ov.{"$titleCaseQ","$q","$lowerQ"}');

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
    // Access language provider
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
        child: SafeArea(
          child: Column(
            children: [
              _buildGlassHeader(lp),
              if (_showFilterBar && !_isLoading) _buildTopCategoryBar(lp),
              Expanded(
                child: _isLoading && _results.isEmpty
                    ? const Center(child: CircularProgressIndicator(color: Colors.white24))
                    : _results.isEmpty
                    ? _buildNoResults(lp)
                    : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    childAspectRatio: 0.7,
                  ),
                  itemCount: _results.length,
                  itemBuilder: (context, index) => _buildResultCard(_results[index]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassHeader(LanguageProvider lp) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              // Using translated "Results for" prefix
              "${lp.getString('results_for')} '${widget.query}'",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: Icon(
              _showFilterBar ? LucideIcons.filterX : LucideIcons.filter,
              color: Colors.white,
            ),
            onPressed: () => setState(() => _showFilterBar = !_showFilterBar),
          ),
        ],
      ),
    );
  }

  Widget _buildTopCategoryBar(LanguageProvider lp) {
    // Map keys to translations
    final Map<String, String> optionMap = {
      'All': lp.getString('all'),
      'Latest': lp.getString('latest'),
      'Top Rated': lp.getString('top_rated'),
      'Most Liked': lp.getString('most_liked'),
    };
    final options = optionMap.keys.toList();

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 60,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
          ),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: options.length,
            itemBuilder: (context, index) {
              final String internalKey = options[index];
              final String displayLabel = optionMap[internalKey]!;
              final isSelected = _selectedSort == internalKey;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 12),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedSort = internalKey;
                      _isLoading = true;
                    });
                    _performSearch();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blueAccent : Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? Colors.blueAccent : Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: Text(
                      displayLabel,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildNoResults(LanguageProvider lp) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.ghost, size: 70, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(
            lp.getString('no_results'), // TRANSLATED EMPTY STATE
            style: const TextStyle(color: Colors.white60, fontSize: 16),
          ),
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
                  child: Container(
                    margin: const EdgeInsets.all(6),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: media.isNotEmpty
                          ? Image.network(media[0], width: double.infinity, fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(color: Colors.white10, child: const Icon(LucideIcons.image, color: Colors.white24)))
                          : Container(color: Colors.white10, child: const Icon(LucideIcons.image, color: Colors.white24)),
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
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 10,
                            backgroundColor: Colors.white12,
                            backgroundImage: profileUrl != null && profileUrl.isNotEmpty
                                ? NetworkImage(profileUrl) : null,
                            child: (profileUrl == null || profileUrl.isEmpty)
                                ? const Icon(Icons.person, size: 10, color: Colors.white) : null,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              authorName,
                              style: const TextStyle(fontSize: 10, color: Colors.white70),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(LucideIcons.messageCircle, size: 12, color: Colors.white54),
                          const SizedBox(width: 2),
                          Text("$postCommentCount", style: const TextStyle(fontSize: 10, color: Colors.white)),
                          const SizedBox(width: 6),
                          Icon(
                            isLikedByMe ? Icons.favorite : Icons.favorite_border,
                            size: 13,
                            color: isLikedByMe ? Colors.redAccent : Colors.white54,
                          ),
                          const SizedBox(width: 2),
                          Text("$postLikeCount", style: const TextStyle(fontSize: 10, color: Colors.white)),
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
}