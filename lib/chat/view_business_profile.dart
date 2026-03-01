import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_detail.dart';

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
  List<Map<String, dynamic>> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPosts();
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
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.verified, color: Colors.green),
              SizedBox(width: 10),
              Text("Verified Business", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            "This business has been successfully verified via SSM (Suruhanjaya Syarikat Malaysia).",
            style: TextStyle(fontSize: 15, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Got it", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.blue.shade100, Colors.purple.shade50],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    const CircleAvatar(
                      radius: 45,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.storefront, size: 50, color: Colors.brown),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.businessData['business_name'] ?? "Business",
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 5),
                        GestureDetector(
                          onTap: () => _showSSMDialog(context),
                          child: const Icon(Icons.verified, color: Colors.green, size: 24),
                        ),
                      ],
                    ),
                    Text(
                      "ID: ${widget.businessData['id']}",
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // --- ADDED: ABOUT SECTION ---
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50.withOpacity(0.3),
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("About", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  _buildInfoRow(Icons.location_on_outlined, "Address:", widget.businessData['address']),
                  _buildInfoRow(Icons.access_time, "Hours:", widget.businessData['hours']),
                  _buildInfoRow(Icons.phone_outlined, "Phone:", widget.businessData['phone']),
                ],
              ),
            ),
          ),



          // Posts List
          _isLoading
              ? const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
              : SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                final post = _posts[index];
                final List<dynamic> imageUrls = post['image_urls'] ?? [];

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CircleAvatar(
                        radius: 20,
                        backgroundColor: Color(0xFFEBE0FF),
                        child: Icon(Icons.storefront, size: 20, color: Color(0xFF33196B)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.businessData['business_name'] ?? "Business",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF576B95),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(post['text'] ?? ""),
                            if (imageUrls.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(imageUrls[0], fit: BoxFit.cover),
                                ),
                              ),
                            const SizedBox(height: 8),
                            const Text(
                              "Just now",
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
              childCount: _posts.length,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserChatDetailPage(
                userData: widget.userData,
                businessData: widget.businessData,
              ),
            ),
          );
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: 60, height: 60,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [Color(0xFF80D8FF), Color(0xFFEA80FC)]),
          ),
          child: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  // Helper Widget for About rows
  Widget _buildInfoRow(IconData icon, String label, dynamic content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.blueGrey),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87, fontSize: 14),
                children: [
                  TextSpan(text: "$label ", style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: content?.toString() ?? "N/A"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}