import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:recommended_restaurant_entertainment/postModule/edit_post.dart';
import 'package:recommended_restaurant_entertainment/reportModule/report.dart';
import 'package:intl/intl.dart';
import 'dart:ui';

class PostDetailPage extends StatefulWidget {
  final Map<String, dynamic> post;
  final String userName; // The name of the post creator
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

  // Helper for the main post date
  String _formatDate(String? timestamp) {
    if (timestamp == null) return "";
    try {
      final DateTime dt = DateTime.parse(timestamp).toLocal();
      return DateFormat('MMM d, yyyy • hh:mm a').format(dt);
    } catch (e) {
      return "";
    }
  }

  // --- NEW: Helper for individual comments (Time Ago format) ---
  String _formatCommentDate(dynamic timestamp) {
    if (timestamp == null) return "";
    try {
      final DateTime dt = DateTime.parse(timestamp.toString()).toLocal();
      final now = DateTime.now();
      final difference = now.difference(dt);

      if (difference.inMinutes < 1) {
        return "Just now";
      } else if (difference.inMinutes < 60) {
        return "${difference.inMinutes}m ago";
      } else if (difference.inHours < 24) {
        return "${difference.inHours}h ago";
      } else if (difference.inDays < 7) {
        return "${difference.inDays}d ago";
      } else {
        return DateFormat('MMM d').format(dt);
      }
    } catch (e) {
      return "";
    }
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || widget.viewerProfileId == null) return;

    final supabase = Supabase.instance.client;

    try {
      final userResponse = await supabase
          .from('profiles')
          .select('created_at, username')
          .eq('id', widget.viewerProfileId)
          .single();

      final DateTime joinedDate = DateTime.parse(userResponse['created_at']);
      final String viewerUsername = userResponse['username'] ?? "Someone";
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

        if (response.count >= limit) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Limit reached! $statusLabel can only comment $limit times per day."),
                backgroundColor: Colors.orange,
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

      final dynamic postOwnerId = _currentPost['profile_id'];
      if (postOwnerId != null && postOwnerId.toString() != widget.viewerProfileId.toString()) {
        await supabase.from('notifications').insert({
          'user_id': postOwnerId,
          'content': '$viewerUsername commented: "$text"',
          'related_post_id': _currentPost['id'],
          'is_read': false,
          'created_at': DateTime.now().toUtc().toIso8601String(),
        });
      }

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
      final supabase = Supabase.instance.client;
      final postId = _currentPost['id'];

      // 1. Delete all likes associated with this post
      await supabase.from('likes').delete().eq('post_id', postId);

      // 2. Delete all comments associated with this post
      await supabase.from('comments').delete().eq('post_id', postId);

      // 3. Delete notifications related to this post
      await supabase.from('notifications').delete().eq('related_post_id', postId);

      // 4. Finally, delete the post
      await supabase.from('posts').delete().eq('id', postId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Post and associated data deleted"), backgroundColor: Colors.green)
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error deleting: $e"), backgroundColor: Colors.red)
        );
      }
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
    final updatedData = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => EditPostPage(post: _currentPost))
    );
    if (updatedData != null && updatedData is Map<String, dynamic>) {
      setState(() {
        _currentPost = { ..._currentPost, ...updatedData };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dynamic postOwnerId = _currentPost['profile_id'];
    final bool isOwner = widget.viewerProfileId != null && postOwnerId != null && widget.viewerProfileId.toString() == postOwnerId.toString();
    final List<dynamic> mediaUrls = _currentPost['media_urls'] ?? [];
    final List<dynamic> categories = _currentPost['category_names'] ?? [];
    final int rating = (_currentPost['rating'] ?? 0).toInt();
    final String? authorPicture = _currentPost['profiles'] != null ? _currentPost['profiles']['profile_url'] : _currentPost['profile_url'];

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF0F0C29),
      appBar: _buildGlassAppBar(isOwner, authorPicture),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildMediaHeader(mediaUrls),
            _buildContentBody(categories, rating),
            _buildCommentList(),
            const SizedBox(height: 120),
          ],
        ),
      ),
      bottomSheet: _buildCommentInput(),
    );
  }

  PreferredSizeWidget _buildGlassAppBar(bool isOwner, String? authorPicture) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leadingWidth: 56,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: IconButton(
          icon: ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(8),
                color: Colors.black.withOpacity(0.3),
                child: const Icon(LucideIcons.chevronLeft, color: Colors.white, size: 20),
              ),
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      title: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A35).withOpacity(0.6),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.black26,
                    backgroundImage: (authorPicture != null) ? NetworkImage(authorPicture) : null,
                    child: (authorPicture == null) ? const Icon(Icons.person, size: 10, color: Colors.white) : null
                ),
                const SizedBox(width: 10),
                Text(
                    widget.userName,
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        if (!isOwner) _buildCircularAction(
            icon: LucideIcons.flag,
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ReportPage(post: _currentPost, viewerProfileId: widget.viewerProfileId)))
        ),
        if (isOwner) _buildCircularAction(
          icon: LucideIcons.moreVertical,
          isPopup: true,
          onSelected: (val) => val == 'edit' ? _navigateToEdit() : _showDeleteConfirmation(),
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _buildCircularAction({required IconData icon, VoidCallback? onPressed, Function(String)? onSelected, bool isPopup = false}) {
    final decoration = BoxDecoration(shape: BoxShape.circle, color: Colors.black.withOpacity(0.3));

    if (isPopup) {
      return PopupMenuButton<String>(
        color: const Color(0xFF1A1A35),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.white.withOpacity(0.1))),
        icon: Container(padding: const EdgeInsets.all(8), decoration: decoration, child: Icon(icon, color: Colors.white, size: 20)),
        onSelected: onSelected,
        itemBuilder: (ctx) => [
          const PopupMenuItem(value: 'edit', child: Row(children: [Icon(LucideIcons.edit, color: Colors.cyanAccent, size: 18), SizedBox(width: 10), Text("Edit Post", style: TextStyle(color: Colors.white))])),
          const PopupMenuItem(value: 'delete', child: Row(children: [Icon(LucideIcons.trash2, color: Colors.redAccent, size: 18), SizedBox(width: 10), Text("Delete Post", style: TextStyle(color: Colors.redAccent))])),
        ],
      );
    }

    return IconButton(
      icon: Container(padding: const EdgeInsets.all(8), decoration: decoration, child: Icon(icon, color: Colors.white, size: 20)),
      onPressed: onPressed,
    );
  }

  Widget _buildMediaHeader(List<dynamic> mediaUrls) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        SizedBox(
          height: 400,
          width: double.infinity,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemCount: mediaUrls.length,
            itemBuilder: (context, i) => Image.network(mediaUrls[i], fit: BoxFit.cover),
          ),
        ),
        Container(
          height: 120,
          decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Color(0xFF0F0C29)]),
          ),
        ),
        if (mediaUrls.length > 1)
          Positioned(
            bottom: 20,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(mediaUrls.length, (i) => AnimatedContainer(duration: const Duration(milliseconds: 300), margin: const EdgeInsets.symmetric(horizontal: 4), height: 4, width: _currentPage == i ? 12 : 4, decoration: BoxDecoration(color: _currentPage == i ? Colors.blueAccent : Colors.white54, borderRadius: BorderRadius.circular(2))))),
          ),
      ],
    );
  }

  Widget _buildContentBody(List<dynamic> categories, int rating) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(_currentPost['title'] ?? '', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white))),
              GestureDetector(
                onTap: _toggleLike,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white.withOpacity(0.1))),
                  child: Row(
                    children: [
                      Icon(_isLiked ? Icons.favorite : Icons.favorite_border, color: _isLiked ? Colors.redAccent : Colors.white70, size: 20),
                      const SizedBox(width: 6),
                      Text("$_totalLikes", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(_formatDate(_currentPost['created_at']), style: const TextStyle(color: Colors.white38, fontSize: 13)),
          const SizedBox(height: 12),
          Row(children: List.generate(5, (i) => Icon(i < rating ? Icons.star_rounded : Icons.star_outline_rounded, color: Colors.amber, size: 22))),
          const SizedBox(height: 16),
          if (categories.isNotEmpty)
            Wrap(
              spacing: 8, runSpacing: 8,
              children: categories.map((cat) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blueAccent.withOpacity(0.2))),
                child: Text(cat.toString(), style: const TextStyle(color: Colors.blueAccent, fontSize: 11, fontWeight: FontWeight.bold)),
              )).toList(),
            ),
          const SizedBox(height: 20),
          Text(_currentPost['description'] ?? '', style: TextStyle(fontSize: 15, height: 1.6, color: Colors.white.withOpacity(0.9))),
          const Padding(padding: EdgeInsets.symmetric(vertical: 25), child: Divider(color: Colors.white10)),
        ],
      ),
    );
  }

  Widget _buildCommentList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Comments", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
          const SizedBox(height: 20),
          _isLoadingComments
              ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
              : ListView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _comments.length,
            itemBuilder: (context, index) {
              final comment = _comments[index];
              final profile = comment['profiles'] ?? {};
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(15)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(radius: 16, backgroundImage: (profile['profile_url'] != null) ? NetworkImage(profile['profile_url']) : null, child: (profile['profile_url'] == null) ? const Icon(Icons.person, size: 18) : null),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                  profile['username'] ?? 'Anonymous',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white70)
                              ),
                              Text(
                                  _formatCommentDate(comment['created_at']),
                                  style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10)
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(comment['content'] ?? '', style: const TextStyle(fontSize: 14, color: Colors.white)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      color: const Color(0xFF0F0C29),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, left: 20, right: 20, top: 10),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: TextField(
                  controller: _commentController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Add a comment...",
                    hintStyle: const TextStyle(color: Colors.white30),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _submitComment,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Colors.blueAccent, Colors.purpleAccent])),
              child: const Icon(LucideIcons.send, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}