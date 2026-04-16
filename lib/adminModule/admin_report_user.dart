import 'dart:ui';
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

  // Logic Preserved
  // navigates to the detailed view of the reported post
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
          viewerProfileId: null, // Admin views as guest/neutral
        ),
      ),
    );
  }

  // Logic Preserved
  // updates report status
  // notifies reporter
  // deletes post if shouldDelete is true
  Future<void> _handleResolution(Map<String, dynamic> report, String remark, bool shouldDelete) async {
    if (remark.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please provide an official remark"), backgroundColor: Colors.orangeAccent)
      );
      return;
    }

    try {
      final String postIdStr = report['post_id'].toString();
      final postRes = await _supabase.from('posts').select('profile_id, title, description, media_urls').eq('id', postIdStr).maybeSingle();

      // 1. Update the report status
      await _supabase.from('reports').update({
        'admin_feedback': remark,
        'status': 'resolved',
        'snapshot_title': postRes?['title'] ?? report['snapshot_title'],
        'snapshot_description': postRes?['description'] ?? report['snapshot_description'],
        'snapshot_media_urls': postRes?['media_urls'] ?? report['snapshot_media_urls'],
      }).eq('id', report['id']);

      // 2. Notify the person who reported it
      await _supabase.from('system_messages').insert({
        'user_id': report['reporter_id'],
        'title': "Report Result: ${shouldDelete ? 'Content Removed' : 'Review Finished'}",
        'content': "Result: Success\nRemark: $remark",
        'report_id': report['id'],
      });

      if (postRes?['profile_id'] != null) {
        if (shouldDelete) {

          // Delete Likes
          await _supabase.from('likes').delete().eq('post_id', postIdStr);

          // Delete Comments
          await _supabase.from('comments').delete().eq('post_id', postIdStr);

          // Delete Notifications related to this post
          await _supabase.from('notifications').delete().eq('related_post_id', postIdStr);


          // Notify the owner of the post
          await _supabase.from('system_messages').insert({
            'user_id': postRes?['profile_id'],
            'title': "Official Notice: Content Removed",
            'content': "Result: Your post has been removed by Admin.\nRemark: $remark",
          });

          // 3. Finally, delete the post
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
      debugPrint("Admin Resolution Error: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent));
    }
  }

  // Designed Dialog
  void _showFeedbackDialog(Map<String, dynamic> report) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AlertDialog(
          backgroundColor: const Color(0xFF1A1A35),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.white.withOpacity(0.1))),
          title: const Text("Review User Report", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Reason: ${report['reason']}", style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              TextField(
                controller: controller,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Enter your official remark...",
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel", style: TextStyle(color: Colors.white.withOpacity(0.5)))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.1), foregroundColor: Colors.white),
              onPressed: () => _handleResolution(report, controller.text.trim(), false),
              child: const Text("Keep Post"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
              onPressed: () => _handleResolution(report, controller.text.trim(), true),
              child: const Text("Delete Post"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String? status) {
    final bool isResolved = status == 'resolved';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isResolved ? Colors.greenAccent.withOpacity(0.1) : Colors.orangeAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isResolved ? Colors.greenAccent.withOpacity(0.3) : Colors.orangeAccent.withOpacity(0.3)),
      ),
      child: Text((status ?? 'pending').toUpperCase(),
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isResolved ? Colors.greenAccent : Colors.orangeAccent)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Handled by AdminDashboard Stack
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("User Reports", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _supabase.from('reports').select('*, posts(*, profiles(*))').order('created_at', ascending: false),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
            final reports = snapshot.data ?? [];

            if (reports.isEmpty) return const Center(child: Text("No reports found.", style: TextStyle(color: Colors.white54)));

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: reports.length,
              itemBuilder: (context, index) {
                final report = reports[index];
                final postData = report['posts'] as Map<String, dynamic>?;
                final bool isResolved = report['status'] == 'resolved';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text("Reason: ${report['reason']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 14))),
                                _buildStatusBadge(report['status']),
                              ],
                            ),
                            const Divider(color: Colors.white10, height: 24),
                            if (postData != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: TextButton.icon(
                                  onPressed: () => _navigateToPostDetail(postData),
                                  icon: const Icon(LucideIcons.externalLink, size: 14, color: Colors.cyanAccent),
                                  label: const Text("View Original Post", style: TextStyle(color: Colors.cyanAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                                  style: TextButton.styleFrom(padding: EdgeInsets.zero, alignment: Alignment.centerLeft),
                                ),
                              ),
                            Text(
                                postData?['title'] ?? report['snapshot_title'] ?? "Deleted Content",
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)
                            ),
                            const SizedBox(height: 16),
                            if (!isResolved)
                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [Colors.cyanAccent, Colors.blueAccent]),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ElevatedButton.icon(
                                    onPressed: () => _showFeedbackDialog(report),
                                    icon: const Icon(LucideIcons.gavel, size: 16),
                                    label: const Text("Take Action", style: TextStyle(fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        foregroundColor: const Color(0xFF0F0C29),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                                    )
                                ),
                              )
                            else
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white.withOpacity(0.1))
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Official Feedback:", style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.4), fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text(report['admin_feedback'] ?? "No remark", style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.white70, fontSize: 13)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}