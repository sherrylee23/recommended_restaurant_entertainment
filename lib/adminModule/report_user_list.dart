import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:recommended_restaurant_entertainment/postModule/post_detail.dart';

class AdminReportUserListPage extends StatefulWidget {
  const AdminReportUserListPage({super.key});

  @override
  State<AdminReportUserListPage> createState() => _AdminReportUserListPageState();
}

class _AdminReportUserListPageState extends State<AdminReportUserListPage> {
  final _supabase = Supabase.instance.client;

  void _navigateToPostDetail(Map<String, dynamic> postData) {
    final String authorName = postData['profiles'] != null
        ? postData['profiles']['username'] ?? "User"
        : "User";

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostDetailPage(
          post: postData,
          userName: authorName,
          viewerProfileId: null,
        ),
      ),
    );
  }

  Future<void> _handleResolution(Map<String, dynamic> report, String remark, bool shouldDelete) async {
    if (remark.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please provide an official remark")));
      return;
    }

    try {
      final String postIdStr = report['post_id'].toString();
      final postRes = await _supabase.from('posts').select('profile_id, title, description, media_urls').eq('id', postIdStr).maybeSingle();

      await _supabase.from('reports').update({
        'admin_feedback': remark,
        'status': 'resolved',
        'snapshot_title': postRes?['title'] ?? report['snapshot_title'],
        'snapshot_description': postRes?['description'] ?? report['snapshot_description'],
        'snapshot_media_urls': postRes?['media_urls'] ?? report['snapshot_media_urls'],
      }).eq('id', report['id']);

      await _supabase.from('system_messages').insert({
        'user_id': report['reporter_id'],
        'title': "Report Result: ${shouldDelete ? 'Content Removed' : 'Review Finished'}",
        'content': "Result: Success\nRemark: $remark",
        'report_id': report['id'],
      });

      if (postRes?['profile_id'] != null) {
        if (shouldDelete) {
          await _supabase.from('system_messages').insert({
            'user_id': postRes?['profile_id'],
            'title': "Official Notice: Content Removed",
            'content': "Result: Your post has been removed.\nRemark: $remark",
          });
          await _supabase.from('posts').delete().eq('id', postIdStr);
        } else {
          await _supabase.from('system_messages').insert({
            'user_id': postRes?['profile_id'],
            'title': "System Update: Content Review",
            'content': "Result: No action taken at this time.\nRemark: $remark",
          });
        }
      }

      if (mounted) {
        Navigator.pop(context);
        setState(() {});
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }

  void _showFeedbackDialog(Map<String, dynamic> report) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Review User Report"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Reason: ${report['reason']}", style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(hintText: "Enter your official remark...", border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
            onPressed: () => _handleResolution(report, controller.text.trim(), false),
            child: const Text("Keep Post"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => _handleResolution(report, controller.text.trim(), true),
            child: const Text("Delete Post"),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String? status) {
    final bool isResolved = status == 'resolved';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isResolved ? Colors.green.shade100 : Colors.orange.shade100,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text((status ?? 'pending').toUpperCase(),
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isResolved ? Colors.green : Colors.orange)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text("User Reports", style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.transparent, elevation: 0),
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.blue.shade100, Colors.purple.shade50])),
        child: SafeArea(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _supabase.from('reports').select('*, posts(*, profiles(*))').order('created_at', ascending: false),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              final reports = snapshot.data ?? [];
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: reports.length,
                itemBuilder: (context, index) {
                  final report = reports[index];
                  final postData = report['posts'] as Map<String, dynamic>?;
                  final bool isResolved = report['status'] == 'resolved';
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Reason: ${report['reason']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                              _buildStatusBadge(report['status']),
                            ],
                          ),
                          const Divider(),
                          if (postData != null)
                            TextButton.icon(onPressed: () => _navigateToPostDetail(postData), icon: const Icon(LucideIcons.externalLink, size: 14), label: const Text("View Post")),
                          Text(postData?['title'] ?? report['snapshot_title'] ?? "Deleted Content", style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          if (!isResolved)
                            SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () => _showFeedbackDialog(report), icon: const Icon(LucideIcons.gavel), label: const Text("Action")))
                          else
                            Text("Feedback: ${report['admin_feedback']}", style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.blueGrey)),
                        ],
                      ),
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