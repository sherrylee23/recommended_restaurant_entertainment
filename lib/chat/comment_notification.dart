import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:recommended_restaurant_entertainment/postModule/post_detail.dart';

class CommentNotificationPage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const CommentNotificationPage({super.key, required this.userData});

  @override
  State<CommentNotificationPage> createState() => _CommentNotificationPageState();
}

class _CommentNotificationPageState extends State<CommentNotificationPage> {
  final _supabase = Supabase.instance.client;
  Key _refreshKey = UniqueKey(); // [cite: 73]

  Future<void> _handleRefresh() async { // [cite: 74]
    setState(() {
      _refreshKey = UniqueKey(); // [cite: 74]
    });
    await Future.delayed(const Duration(milliseconds: 500)); // [cite: 75]
  }

  String _formatDate(String? timestamp) {
    if (timestamp == null) return ""; // [cite: 76]
    try {
      final DateTime dt = DateTime.parse(timestamp).toLocal(); // [cite: 77]
      return DateFormat('MMM d, h:mm a').format(dt); // [cite: 77]
    } catch (e) {
      return ""; // [cite: 78]
    }
  }

  @override
  Widget build(BuildContext context) {
    final dynamic userId = widget.userData['id']; // [cite: 79]

    return Scaffold(
      appBar: AppBar(
        title: const Text("Post Comments", style: TextStyle(fontWeight: FontWeight.bold)), // [cite: 80]
        backgroundColor: Colors.blue.shade100, // [cite: 80]
        centerTitle: true, // [cite: 80]
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient( // [cite: 81]
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Colors.blue.shade100, Colors.purple.shade50],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: _handleRefresh, // [cite: 81]
          color: Colors.blueAccent, // [cite: 82]
          child: userId == null
              ? ListView(children: const [Center(child: Padding(padding: EdgeInsets.only(top: 20), child: Text("Error: User ID not found.")))]) // [cite: 83]
              : StreamBuilder<List<Map<String, dynamic>>>(
            key: _refreshKey, // [cite: 84]
            // CRITICAL: Stop stream if user logs out to prevent crash [cite: 85]
            stream: _supabase.auth.currentUser == null
                ? Stream.value([]) // [cite: 86]
                : _supabase
                .from('notifications')
                .stream(primaryKey: ['id'])
                .eq('user_id', userId), // [cite: 87]
            builder: (context, snapshot) {
              if (_supabase.auth.currentUser == null) return const SizedBox.shrink(); // [cite: 88]

              if (snapshot.hasError) return const Center(child: Text("Session ended.")); // [cite: 89]

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator()); // [cite: 90]
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(), // [cite: 92]
                  children: const [
                    SizedBox(height: 100),
                    Center(child: Text("No new comments yet.")), // [cite: 92]
                  ],
                );
              }

              final notifications = snapshot.data!;
              notifications.sort((a, b) => b['created_at'].compareTo(a['created_at'])); // [cite: 95]

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(), // [cite: 96]
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final item = notifications[index];
                  final bool isRead = item['is_read'] ?? false;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), // [cite: 98]
                    elevation: isRead ? 0 : 2, // [cite: 99]
                    color: isRead ? Colors.white.withOpacity(0.7) : Colors.white, // [cite: 100]
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isRead ? Colors.grey.shade300 : Colors.orangeAccent, // [cite: 102]
                        child: const Icon(Icons.comment, color: Colors.white, size: 20), // [cite: 103]
                      ),
                      title: Text(item['content'] ?? "New comment on your post", style: TextStyle(fontSize: 14, fontWeight: isRead ? FontWeight.normal : FontWeight.bold)), // [cite: 106]
                      subtitle: Text(_formatDate(item['created_at']), style: const TextStyle(fontSize: 11)), // [cite: 108]
                      trailing: !isRead ? Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle)) : null, // [cite: 111]
                      onTap: () async {
                        await _supabase.from('notifications').update({'is_read': true}).eq('id', item['id']); // [cite: 113]

                        if (item['related_post_id'] != null) {
                          try {
                            final postData = await _supabase
                                .from('posts')
                                .select('*, profiles(username, profile_url)') // [cite: 115]
                                .eq('id', item['related_post_id'])
                                .single(); // [cite: 117]

                            if (mounted) {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => PostDetailPage(post: postData, userName: postData['profiles']['username'] ?? 'User', viewerProfileId: userId)), // [cite: 120]
                              );
                              _handleRefresh(); // [cite: 122]
                            }
                          } catch (e) {
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Could not find post: $e"))); // [cite: 125]
                          }
                        }
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}