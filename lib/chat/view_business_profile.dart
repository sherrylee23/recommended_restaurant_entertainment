import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'chat_detail.dart';
import 'package:recommended_restaurant_entertainment/businessModule/booking_form.dart';
import 'package:intl/intl.dart';
import '../language_provider.dart';

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
  Map<String, dynamic>? _currentBusinessData;
  List<Map<String, dynamic>> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentBusinessData = widget.businessData;
    _fetchBusinessProfile();
    _fetchPosts();
  }

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

  void _showSSMDialog(BuildContext context, LanguageProvider lp) {
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
            title: Row(
              children: [
                const Icon(LucideIcons.shieldCheck, color: Colors.greenAccent),
                const SizedBox(width: 10),
                Text(lp.getString('ssm_verified'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
            content: Text(
              lp.getString('ssm_desc'),
              style: const TextStyle(fontSize: 14, color: Colors.white70, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(lp.getString('close'), style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final lp = Provider.of<LanguageProvider>(context);

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
              _buildSliverAppBar(lp),
              SliverToBoxAdapter(child: _buildAboutSection(lp)),
              _buildPostHeader(lp),
              _buildPostsList(lp),
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
            child: Text(lp.getString('book_now'), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F0C29))),
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(LanguageProvider lp) {
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
                      onTap: () => _showSSMDialog(context, lp),
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

  Widget _buildAboutSection(LanguageProvider lp) {
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
          Text(lp.getString('about'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueAccent, letterSpacing: 1.5)),
          const SizedBox(height: 15),
          _buildInfoRow(LucideIcons.mapPin, lp.getString('address'), _currentBusinessData?['address'] ?? lp.getString('no_description')),
          _buildInfoRow(LucideIcons.clock, lp.getString('hours'), _currentBusinessData?['hours'] ?? lp.getString('no_description')),
          _buildInfoRow(LucideIcons.phone, lp.getString('phone'), _currentBusinessData?['phone'] ?? lp.getString('no_description')),
        ],
      ),
    );
  }

  Widget _buildPostHeader(LanguageProvider lp) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(25, 10, 25, 10),
        child: Text(lp.getString('latest_updates'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  Widget _buildPostsList(LanguageProvider lp) {
    if (_isLoading) {
      return const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: Colors.blueAccent)));
    }
    if (_posts.isEmpty) {
      return SliverFillRemaining(child: Center(child: Text(lp.getString('no_posts_yet'), style: const TextStyle(color: Colors.white38))));
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