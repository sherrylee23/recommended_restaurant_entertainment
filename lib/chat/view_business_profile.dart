import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'chat_detail.dart';
import 'package:recommended_restaurant_entertainment/businessModule/booking_form.dart';
import 'package:intl/intl.dart';

class UserViewBusinessPage extends StatefulWidget {
  final Map<String, dynamic> businessData;
  final Map<String, dynamic> userData;

  const UserViewBusinessPage({
    super.key,
    required this.businessData,
    required this.userData,
  });

  @override
  State<UserViewBusinessPage> createState() => _UserViewBusinessPageState();
}

class _UserViewBusinessPageState extends State<UserViewBusinessPage> {
  final _supabase = Supabase.instance.client;
  Map<String, dynamic>? _currentBusinessData; // To hold fresh profile data
  List<Map<String, dynamic>> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentBusinessData = widget.businessData;
    _fetchBusinessProfile(); // Refresh profile to get the latest image/info
    _fetchPosts();
  }

  // Fetch fresh business profile to ensure the user sees the latest profile image
  Future<void> _fetchBusinessProfile() async {
    try {
      final data = await _supabase
          .from('business_profiles')
          .select()
          .eq('id', widget.businessData['id'])
          .single();
      if (mounted) {
        setState(() {
          _currentBusinessData = data;
        });
      }
    } catch (e) {
      debugPrint("Error fetching business profile: $e");
    }
  }

  Future<void> _fetchPosts() async {
    try {
      final data = await _supabase
          .from('business_posts')
          .select()
          .eq('business_id', widget.businessData['id'])
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _posts = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSSMDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AlertDialog(
            backgroundColor: const Color(0xFF16162E).withOpacity(0.9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
              side: const BorderSide(color: Colors.greenAccent, width: 0.5),
            ),
            title: const Row(
              children: [
                Icon(LucideIcons.shieldCheck, color: Colors.greenAccent),
                SizedBox(width: 10),
                Text("SSM Verified", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
            content: const Text(
              "This business is officially verified via Suruhanjaya Syarikat Malaysia (SSM).",
              style: TextStyle(fontSize: 14, color: Colors.white70, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("CLOSE", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0C29),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: () async {
            await _fetchBusinessProfile();
            await _fetchPosts();
          },
          color: Colors.blueAccent,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(child: _buildAboutSection()),
              _buildPostHeader(),
              _buildPostsList(),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildChatFAB(),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(15),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orangeAccent,
              minimumSize: const Size(double.infinity, 55),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookingFormPage(
                    businessId: widget.businessData['id'],
                    userId: widget.userData['id'],
                    businessName: _currentBusinessData?['business_name'] ?? "Business",
                  ),
                ),
              );
            },
            child: const Text("BOOK NOW", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F0C29))),
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    final String? profileImageUrl = _currentBusinessData?['profile_url'];

    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      backgroundColor: const Color(0xFF0F0C29),
      leading: IconButton(
        icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 50),
                // UPDATED: Profile Avatar with real image support
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: [Colors.blueAccent, Colors.purpleAccent]),
                    boxShadow: [BoxShadow(color: Colors.blueAccent.withOpacity(0.3), blurRadius: 15)],
                  ),
                  child: CircleAvatar(
                    radius: 45,
                    backgroundColor: const Color(0xFF16162E),
                    backgroundImage: (profileImageUrl != null && profileImageUrl.isNotEmpty)
                        ? NetworkImage(profileImageUrl)
                        : null,
                    child: (profileImageUrl == null || profileImageUrl.isEmpty)
                        ? const Icon(LucideIcons.store, size: 40, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        _currentBusinessData?['business_name'] ?? "Business",
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _showSSMDialog(context),
                      child: const Icon(LucideIcons.badgeCheck, color: Colors.greenAccent, size: 22),
                    ),
                  ],
                ),
                Text(
                  "ID: ${widget.businessData['id']}",
                  style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("ABOUT", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueAccent, letterSpacing: 1.5)),
          const SizedBox(height: 15),
          _buildInfoRow(LucideIcons.mapPin, "Address", _currentBusinessData?['address'] ?? "No address"),
          _buildInfoRow(LucideIcons.clock, "Hours", _currentBusinessData?['hours'] ?? "No hours set"),
          _buildInfoRow(LucideIcons.phone, "Phone", _currentBusinessData?['phone'] ?? "No contact"),
        ],
      ),
    );
  }

  Widget _buildPostHeader() {
    return const SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(25, 10, 25, 10),
        child: Text("Latest Updates", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  Widget _buildPostsList() {
    if (_isLoading) {
      return const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: Colors.blueAccent)));
    }
    if (_posts.isEmpty) {
      return const SliverFillRemaining(child: Center(child: Text("No posts yet", style: TextStyle(color: Colors.white38))));
    }

    final String? profileImageUrl = _currentBusinessData?['profile_url'];

    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          final post = _posts[index];
          final List<dynamic> imageUrls = post['image_urls'] ?? [];

          String formattedTime = "Recently";
          if (post['created_at'] != null) {
            try {
              DateTime dt = DateTime.parse(post['created_at']).toLocal();
              formattedTime = DateFormat('MMM d, h:mm a').format(dt);
            } catch (e) {
              formattedTime = "Recently";
            }
          }

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Small Avatar for the post
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.blueAccent,
                      backgroundImage: (profileImageUrl != null && profileImageUrl.isNotEmpty)
                          ? NetworkImage(profileImageUrl)
                          : null,
                      child: (profileImageUrl == null || profileImageUrl.isEmpty)
                          ? const Icon(LucideIcons.store, size: 16, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _currentBusinessData?['business_name'] ?? "Business",
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white70),
                    ),
                    const Spacer(),
                    Text(
                        formattedTime,
                        style: const TextStyle(color: Colors.white24, fontSize: 10)
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (post['text'] != null && post['text'].toString().isNotEmpty)
                  Text(post['text'] ?? "", style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4)),
                if (imageUrls.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 15),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.network(
                        imageUrls[0],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            height: 200,
                            color: Colors.white.withOpacity(0.05),
                            child: const Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
        childCount: _posts.length,
      ),
    );
  }

  Widget _buildChatFAB() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserChatDetailPage(
              userData: widget.userData,
              businessData: _currentBusinessData ?? widget.businessData,
            ),
          ),
        );
      },
      child: Container(
        width: 60, height: 60,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(colors: [Colors.blueAccent, Colors.purpleAccent]),
          boxShadow: [
            BoxShadow(color: Colors.blueAccent.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5)),
          ],
        ),
        child: const Icon(LucideIcons.messageSquare, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, dynamic content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.blueAccent),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(content?.toString() ?? "N/A", style: const TextStyle(color: Colors.white, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}