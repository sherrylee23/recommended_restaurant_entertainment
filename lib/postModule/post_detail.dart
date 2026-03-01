import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:recommended_restaurant_entertainment/postModule/edit_post.dart';
import 'package:recommended_restaurant_entertainment/reportModule/report.dart';

class PostDetailPage extends StatefulWidget {
  final Map<String, dynamic> post;
  final String userName;
  final dynamic viewerProfileId;

  const PostDetailPage({
    super.key,
    required this.post,
    required this.userName,
    this.viewerProfileId,
  });

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  late Map<String, dynamic> _currentPost;
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLiked = false;
  int _totalLikes = 0;

  @override
  void initState() {
    super.initState();
    _currentPost = widget.post;
    _totalLikes = _currentPost['likes_count'] ?? 0;
    _fetchLikeData();
    _recordViewForAI();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // --- AI ANALYSIS LOGIC ---
  Future<void> _recordViewForAI() async {
    if (widget.viewerProfileId == null) return;

    final List<dynamic> categories = _currentPost['category_names'] ?? [];

    // Normalize strings before sending to RPC
    final normalizedCategories = categories.map((c) {
      String s = c.toString();
      return s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();
    }).toList();

    try {
      final supabase = Supabase.instance.client;
      await supabase.rpc('increment_interest_counts', params: {
        'p_user_id': widget.viewerProfileId,
        'categories': normalizedCategories,
      });
    } catch (e) {
      debugPrint("AI Record Error: $e");
    }
  }

  // --- LIKE LOGIC ---
  Future<void> _fetchLikeData() async {
    try {
      final supabase = Supabase.instance.client;
      final postId = _currentPost['id'];
      final countRes = await supabase.from('likes').select('*').eq('post_id', postId).count(CountOption.exact);

      bool userHasLiked = false;
      if (widget.viewerProfileId != null) {
        final existingLike = await supabase.from('likes').select().eq('post_id', postId).eq('profile_id', widget.viewerProfileId).maybeSingle();
        userHasLiked = existingLike != null;
      }
      if (mounted) {
        setState(() {
          _totalLikes = countRes.count;
          _isLiked = userHasLiked;
        });
      }
    } catch (e) {
      debugPrint("Error fetching likes: $e");
    }
  }

  Future<void> _toggleLike() async {
    if (widget.viewerProfileId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please log in to like posts")));
      return;
    }
    final supabase = Supabase.instance.client;
    final postId = _currentPost['id'];
    setState(() {
      _isLiked = !_isLiked;
      _isLiked ? _totalLikes++ : _totalLikes--;
    });
    try {
      if (_isLiked) {
        await supabase.from('likes').insert({'post_id': postId, 'profile_id': widget.viewerProfileId});
      } else {
        await supabase.from('likes').delete().eq('post_id', postId).eq('profile_id', widget.viewerProfileId);
      }
    } catch (e) {
      _fetchLikeData();
    }
  }

  // --- SUPABASE DELETE LOGIC ---
  Future<void> _deletePost() async {
    try {
      await Supabase.instance.client.from('posts').delete().eq('id', _currentPost['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Post deleted successfully"), backgroundColor: Colors.green));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error deleting: $e"), backgroundColor: Colors.red));
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Post"),
        content: const Text("Are you sure you want to permanently remove this post?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(onPressed: () { Navigator.pop(context); _deletePost(); }, child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  Future<void> _navigateToEdit() async {
    final updatedData = await Navigator.push(context, MaterialPageRoute(builder: (context) => EditPostPage(post: _currentPost)));
    if (updatedData != null && updatedData is Map<String, dynamic>) setState(() { _currentPost = updatedData; });
  }

  @override
  Widget build(BuildContext context) {
    // Determine if the viewer is the owner of the post
    final dynamic postOwnerId = _currentPost['profile_id'];
    final bool isOwner = widget.viewerProfileId != null &&
        postOwnerId != null &&
        widget.viewerProfileId.toString() == postOwnerId.toString();

    final List<dynamic> mediaUrls = _currentPost['media_urls'] ?? [];
    final int rating = (_currentPost['rating'] ?? 0).toInt();

    final String? authorPicture = _currentPost['profiles'] != null
        ? _currentPost['profiles']['profile_url']
        : _currentPost['profile_url'];

    final String createdAtRaw = _currentPost['created_at'] ?? '';
    String formattedDate = 'Unknown date';
    if (createdAtRaw.isNotEmpty) {
      try {
        final DateTime dateTime = DateTime.parse(createdAtRaw).toLocal();
        formattedDate = "${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}  ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
      } catch (e) {
        debugPrint("Error parsing date: $e");
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87, size: 22),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.blue.shade50,
              backgroundImage: (authorPicture != null && authorPicture.isNotEmpty)
                  ? NetworkImage(authorPicture)
                  : null,
              child: (authorPicture == null || authorPicture.isEmpty)
                  ? const Icon(Icons.person, size: 20, color: Colors.blueAccent)
                  : null,
            ),
            const SizedBox(width: 10),
            Text(
              widget.userName,
              style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        actions: [
          // MODIFIED: Report Button - Only shows if the user is NOT the owner
          if (!isOwner)
            IconButton(
              icon: const Icon(Icons.report_problem_outlined, color: Colors.redAccent),
              tooltip: 'Report Post',
              onPressed: () {
                if (widget.viewerProfileId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please log in to report content")),
                  );
                  return;
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReportPage(
                      post: _currentPost,
                      viewerProfileId: widget.viewerProfileId,
                    ),
                  ),
                );
              },
            ),

          // Three-dot menu for Edit/Delete - Only shows for the owner
          if (isOwner)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.black87),
              onSelected: (value) {
                if (value == 'edit') _navigateToEdit();
                else if (value == 'delete') _showDeleteConfirmation();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                    value: 'edit',
                    child: Row(children: [Icon(Icons.edit_outlined, size: 20), SizedBox(width: 10), Text("Edit Post")])
                ),
                const PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [Icon(Icons.delete_outline, size: 20, color: Colors.redAccent), SizedBox(width: 10), Text("Delete Post", style: TextStyle(color: Colors.redAccent))])
                ),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: MediaQuery.of(context).padding.top + kToolbarHeight,
              decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [Colors.blue.shade100, Colors.purple.shade50])),
            ),
            if (mediaUrls.isNotEmpty)
              Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  SizedBox(
                    height: 350,
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) => setState(() => _currentPage = index),
                      itemCount: mediaUrls.length,
                      itemBuilder: (context, index) => Image.network(mediaUrls[index], fit: BoxFit.cover),
                    ),
                  ),
                  if (mediaUrls.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(mediaUrls.length, (index) {
                          return AnimatedContainer(duration: const Duration(milliseconds: 300), margin: const EdgeInsets.symmetric(horizontal: 4), height: 6, width: _currentPage == index ? 10 : 6, decoration: BoxDecoration(color: _currentPage == index ? Colors.blueAccent : Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(4)));
                        }),
                      ),
                    ),
                ],
              ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(_currentPost['title'] ?? '', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
                      Row(
                        children: [
                          IconButton(icon: Icon(_isLiked ? Icons.favorite : Icons.favorite_border, color: _isLiked ? Colors.red : Colors.grey), onPressed: _toggleLike),
                          Text("$_totalLikes", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ],
                  ),
                  Row(children: List.generate(5, (index) => Icon(index < rating ? Icons.star : Icons.star_border, color: Colors.amber, size: 20))),
                  const SizedBox(height: 12),
                  Text(_currentPost['description'] ?? 'No description provided.', style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.5)),
                  const SizedBox(height: 18),
                  if (_currentPost['location_name'] != null)
                    Row(children: [const Icon(Icons.location_on, color: Colors.blueAccent, size: 18), const SizedBox(width: 6), Text(_currentPost['location_name'], style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.w600, fontSize: 14))]),
                  const Divider(height: 35, thickness: 0.8),
                  const Text("Categories", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: (_currentPost['category_names'] as List? ?? []).map((cat) => Chip(label: Text(cat.toString()), backgroundColor: Colors.blue.shade50, side: BorderSide.none, padding: const EdgeInsets.symmetric(horizontal: 4), labelStyle: const TextStyle(color: Colors.blueAccent, fontSize: 12))).toList(),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text("Posted on $formattedDate", style: const TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic)),
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