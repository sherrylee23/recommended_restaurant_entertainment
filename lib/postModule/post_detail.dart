import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:recommended_restaurant_entertainment/postModule/edit_post.dart';
import 'package:recommended_restaurant_entertainment/reportModule/report.dart';
import 'package:intl/intl.dart'; // Make sure this is in your pubspec.yaml

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

  final TextEditingController _commentController = TextEditingController();
  List<Map<String, dynamic>> _comments = [];
  bool _isLoadingComments = false;

  @override
  void initState() {
    super.initState();
    _currentPost = widget.post;
    _totalLikes = _currentPost['likes_count'] ?? 0;
    _fetchLikeData();
    _recordViewForAI();
    _fetchComments();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  // Helper to format the creation date
  String _formatDate(String? timestamp) {
    if (timestamp == null) return "";
    try {
      final DateTime dt = DateTime.parse(timestamp).toLocal();
      return DateFormat('MMM d, yyyy • hh:mm a').format(dt);
    } catch (e) {
      return "";
    }
  }

  // --- LOGIC: RESTRICT COMMENTS BASED ON USER STATUS ---
  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || widget.viewerProfileId == null) return;

    final supabase = Supabase.instance.client;

    try {
      final userResponse = await supabase
          .from('profiles')
          .select('created_at')
          .eq('id', widget.viewerProfileId)
          .single();

      final DateTime joinedDate = DateTime.parse(userResponse['created_at']);
      final int daysJoined = DateTime.now().difference(joinedDate).inDays;

      int limit;
      String statusLabel;

      if (daysJoined >= 365) {
        limit = -1;
        statusLabel = "Trusted User";
      } else if (daysJoined >= 14) {
        limit = 15;
        statusLabel = "Active User";
      } else {
        limit = 3;
        statusLabel = "New User";
      }

      if (limit != -1) {
        final now = DateTime.now().toUtc();
        final startOfToday = DateTime(now.year, now.month, now.day).toIso8601String();

        final response = await supabase
            .from('comments')
            .select('id')
            .eq('profile_id', widget.viewerProfileId)
            .gte('created_at', startOfToday)
            .count(CountOption.exact);

        final int currentCount = response.count;

        if (currentCount >= limit) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Limit reached! $statusLabel can only comment $limit times per day."),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
        }
      }

      await supabase.from('comments').insert({
        'post_id': _currentPost['id'],
        'profile_id': widget.viewerProfileId,
        'content': text,
      });

      _commentController.clear();
      FocusScope.of(context).unfocus();
      _fetchComments();

    } catch (e) {
      debugPrint("Comment Submit Error: $e");
    }
  }

  Future<void> _recordViewForAI() async {
    if (widget.viewerProfileId == null) return;

    final List<dynamic> categories = _currentPost['category_names'] ?? [];

    final normalizedCategories = categories.map((c) {
      String s = c.toString().trim();
      if (s.isEmpty) return s;
      return s[0].toUpperCase() + s.substring(1).toLowerCase();
    }).toList();

    try {
      await Supabase.instance.client.rpc('increment_interest_counts', params: {
        'p_user_id': widget.viewerProfileId,
        'categories': normalizedCategories,
      });
    } catch (e) {
      debugPrint("AI Record Error: $e");
    }
  }

  Future<void> _fetchComments() async {
    setState(() => _isLoadingComments = true);
    try {
      final data = await Supabase.instance.client
          .from('comments')
          .select('*, profiles(username, profile_url)')
          .eq('post_id', _currentPost['id'])
          .order('created_at', ascending: true);

      if (mounted) {
        setState(() {
          _comments = List<Map<String, dynamic>>.from(data);
          _isLoadingComments = false;
        });
      }
    } catch (e) {
      debugPrint("Comment Fetch Error: $e");
      if (mounted) setState(() => _isLoadingComments = false);
    }
  }

  Future<void> _fetchLikeData() async {
    try {
      final postId = _currentPost['id'];
      final countRes = await Supabase.instance.client.from('likes').select('*').eq('post_id', postId).count(CountOption.exact);

      bool userHasLiked = false;
      if (widget.viewerProfileId != null) {
        final existingLike = await Supabase.instance.client.from('likes').select().eq('post_id', postId).eq('profile_id', widget.viewerProfileId).maybeSingle();
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
    if (widget.viewerProfileId == null) return;
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

  // --- MODIFIED: Ensure owner data is preserved after editing ---
  Future<void> _navigateToEdit() async {
    final updatedData = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => EditPostPage(post: _currentPost))
    );

    if (updatedData != null && updatedData is Map<String, dynamic>) {
      setState(() {
        // We use the Spread Operator (...) to merge updatedData into _currentPost.
        // This keeps important fields like 'profile_id' and 'profiles' intact,
        // which ensures the 'isOwner' check remains true after the update.
        _currentPost = {
          ..._currentPost,
          ...updatedData,
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ownership check happens here
    final dynamic postOwnerId = _currentPost['profile_id'];
    final bool isOwner = widget.viewerProfileId != null &&
        postOwnerId != null &&
        widget.viewerProfileId.toString() == postOwnerId.toString();

    final List<dynamic> mediaUrls = _currentPost['media_urls'] ?? [];
    final List<dynamic> categories = _currentPost['category_names'] ?? [];
    final int rating = (_currentPost['rating'] ?? 0).toInt();
    final String? authorPicture = _currentPost['profiles'] != null ? _currentPost['profiles']['profile_url'] : _currentPost['profile_url'];

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
            CircleAvatar(radius: 18, backgroundColor: Colors.blue.shade50, backgroundImage: (authorPicture != null && authorPicture.isNotEmpty) ? NetworkImage(authorPicture) : null, child: (authorPicture == null || authorPicture.isEmpty) ? const Icon(Icons.person, size: 20, color: Colors.blueAccent) : null),
            const SizedBox(width: 10),
            Text(widget.userName, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        actions: [
          // If the merge failed previously, isOwner would be false and show the report icon.
          if (!isOwner) IconButton(icon: const Icon(Icons.report_problem_outlined, color: Colors.redAccent), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ReportPage(post: _currentPost, viewerProfileId: widget.viewerProfileId)))),
          if (isOwner) PopupMenuButton<String>(icon: const Icon(Icons.more_vert, color: Colors.black87), onSelected: (value) => value == 'edit' ? _navigateToEdit() : _showDeleteConfirmation(), itemBuilder: (context) => [const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 20), SizedBox(width: 10), Text("Edit Post")])), const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 20, color: Colors.redAccent), SizedBox(width: 10), Text("Delete Post", style: TextStyle(color: Colors.redAccent))]))]),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(height: MediaQuery.of(context).padding.top + kToolbarHeight, decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.blue.shade100, Colors.purple.shade50]))),
            if (mediaUrls.isNotEmpty) Stack(alignment: Alignment.bottomCenter, children: [SizedBox(height: 350, child: PageView.builder(controller: _pageController, onPageChanged: (i) => setState(() => _currentPage = i), itemCount: mediaUrls.length, itemBuilder: (context, i) => Image.network(mediaUrls[i], fit: BoxFit.cover))), if (mediaUrls.length > 1) Padding(padding: const EdgeInsets.only(bottom: 15), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(mediaUrls.length, (i) => AnimatedContainer(duration: const Duration(milliseconds: 300), margin: const EdgeInsets.symmetric(horizontal: 4), height: 6, width: _currentPage == i ? 10 : 6, decoration: BoxDecoration(color: _currentPage == i ? Colors.blueAccent : Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(4))))))]),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: Text(_currentPost['title'] ?? '', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))), Row(children: [IconButton(icon: Icon(_isLiked ? Icons.favorite : Icons.favorite_border, color: _isLiked ? Colors.red : Colors.grey), onPressed: _toggleLike), Text("$_totalLikes", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))])]),

                  // DATE DISPLAY
                  Text(
                    _formatDate(_currentPost['created_at']),
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const SizedBox(height: 8),

                  Row(children: List.generate(5, (i) => Icon(i < rating ? Icons.star : Icons.star_border, color: Colors.amber, size: 20))),
                  const SizedBox(height: 16),

                  // CATEGORY SECTION
                  if (categories.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: categories.map((cat) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.blue.shade100),
                          ),
                          child: Text(
                            cat.toString(),
                            style: TextStyle(color: Colors.blue.shade700, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        )).toList(),
                      ),
                    ),

                  Text(_currentPost['description'] ?? '', style: const TextStyle(fontSize: 15, height: 1.5)),
                  const Divider(height: 50),
                  _buildCommentSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Comments", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 16),
        _isLoadingComments
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _comments.length,
          itemBuilder: (context, index) {
            final comment = _comments[index];
            final profile = comment['profiles'] ?? {};
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  CircleAvatar(radius: 16, backgroundImage: (profile['profile_url'] != null) ? NetworkImage(profile['profile_url']) : null, child: (profile['profile_url'] == null) ? const Icon(Icons.person, size: 18) : null),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(profile['username'] ?? 'Anonymous', style: const TextStyle(fontWeight: FontWeight.bold)), Text(comment['content'] ?? '')])),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: TextField(controller: _commentController, decoration: InputDecoration(hintText: "Write a comment...", filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none)))),
            const SizedBox(width: 8),
            Container(decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Colors.blue.shade400, Colors.purple.shade400])), child: IconButton(icon: const Icon(Icons.send, color: Colors.white, size: 18), onPressed: _submitComment)),
          ],
        ),
      ],
    );
  }
}