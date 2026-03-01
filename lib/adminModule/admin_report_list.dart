import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
// Ensure this path matches your project structure
import 'package:recommended_restaurant_entertainment/postModule/post_detail.dart';

class AdminReportListPage extends StatefulWidget {
  const AdminReportListPage({super.key});

  @override
  State<AdminReportListPage> createState() => _AdminReportListPageState();
}

class _AdminReportListPageState extends State<AdminReportListPage> {
  final _supabase = Supabase.instance.client;
  bool _showUserReports = true;

  // --- NAVIGATION LOGIC ---

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

  // --- CORE RESOLUTION LOGIC (FIXED ORDER) ---

  Future<void> _handleResolution(
      Map<String, dynamic> report, String remark, bool shouldDelete) async {
    if (remark.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please provide an official remark")),
      );
      return;
    }

    try {
      final String postIdStr = report['post_id'].toString();

      // 1. Fetch live data first while it still exists
      final postRes = await _supabase
          .from('posts')
          .select('profile_id, title, description, media_urls')
          .eq('id', postIdStr)
          .maybeSingle();

      String postTitle = postRes?['title'] ?? "Untitled Post";
      dynamic postOwnerId = postRes?['profile_id'];

      // 2. SAVE SNAPSHOT AND RESOLVE REPORT FIRST
      // This saves the "Evidence" into the reports table permanently before the post is gone.
      await _supabase.from('reports').update({
        'admin_feedback': remark,
        'status': 'resolved',
        'snapshot_title': postRes?['title'] ?? report['snapshot_title'],
        'snapshot_description': postRes?['description'] ?? report['snapshot_description'],
        'snapshot_media_urls': postRes?['media_urls'] ?? report['snapshot_media_urls'],
      }).eq('id', report['id']);

      // 3. NOTIFY THE REPORTER
      await _supabase.from('system_messages').insert({
        'user_id': report['reporter_id'],
        'title': "Report Result: ${shouldDelete ? 'Content Removed' : 'Review Finished'}",
        'content': "Result: Success\nRemark: $remark",
        'report_id': report['id'],
      });

      // 4. PROCESS POST OWNER ACTIONS
      if (postOwnerId != null) {
        if (shouldDelete) {
          // Notify owner first
          await _supabase.from('system_messages').insert({
            'user_id': postOwnerId,
            'title': "Official Notice: Content Removed",
            'content': "Result: Your post '$postTitle' has been removed.\nRemark: $remark",
          });

          // FINALLY, delete the live post
          // Because of CASCADE, this would try to delete the report, but our SET NULL rule
          // on system_messages now allows this to happen without the 23503 error.
          await _supabase.from('posts').delete().eq('id', postIdStr);
        } else {
          await _supabase.from('system_messages').insert({
            'user_id': postOwnerId,
            'title': "System Update: Content Review",
            'content': "Result: No action taken at this time.\nRemark: $remark",
          });
        }
      }

      if (mounted) {
        Navigator.pop(context);
        setState(() {}); // Refresh the admin list to show the new 'Resolved' status
      }
    } catch (e) {
      debugPrint("Final Resolve Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- UI COMPONENTS ---

  void _showFeedbackDialog(Map<String, dynamic> report, bool isUserReport) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isUserReport ? "Review User Report" : "Reply to Complaint"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isUserReport ? "Reason: ${report['reason']}" : "Business: ${report['business_name']}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: "Enter your official remark/reason...",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
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
      child: Text(
        (status ?? 'pending').toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isResolved ? Colors.green : Colors.orange,
        ),
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report, Map<String, dynamic>? postData) {
    final bool isResolved = report['status'] == 'resolved';

    // Choose between live data or snapshot data
    final String displayTitle = postData?['title'] ?? report['snapshot_title'] ?? "Deleted Content";
    final String displayDesc = postData?['description'] ?? report['snapshot_description'] ?? "No description available.";

    // Check if the post is actually deleted from the posts table
    final bool isDeletedSnapshot = postData == null && report['snapshot_title'] != null;

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
                Expanded(
                  child: Text("Reason: ${report['reason'] ?? 'Other'}",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.redAccent)),
                ),
                _buildStatusBadge(report['status']),
              ],
            ),
            const Divider(),
            if (_showUserReports) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(isDeletedSnapshot ? "Evidence (Deleted Post):" : "Reported Content Preview:",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13,
                          color: isDeletedSnapshot ? Colors.red : Colors.grey)),
                  if (postData != null)
                    TextButton.icon(
                      onPressed: () => _navigateToPostDetail(postData),
                      icon: const Icon(LucideIcons.externalLink, size: 14),
                      label: const Text("View Full Post", style: TextStyle(fontSize: 12)),
                    )
                  else if (isDeletedSnapshot)
                    const Text("[POST DELETED]", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11)),
                ],
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: postData != null ? () => _navigateToPostDetail(postData) : null,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDeletedSnapshot ? Colors.red.shade50 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isDeletedSnapshot ? Colors.red.shade200 : Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(displayTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(displayDesc, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Text("Business: ${report['business_name']}", style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
            const SizedBox(height: 12),
            Text("Reporter's Remarks: ${report['details'] ?? 'No additional details'}", style: const TextStyle(fontSize: 13)),
            if (isResolved) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                child: Text("Admin Feedback: ${report['admin_feedback']}", style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
              ),
            ] else
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showFeedbackDialog(report, _showUserReports),
                    icon: const Icon(LucideIcons.gavel),
                    label: const Text("Review & Take Action"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(_showUserReports ? "User Reports" : "Business Reports", style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: TextButton.icon(
              onPressed: () => setState(() => _showUserReports = !_showUserReports),
              icon: Icon(_showUserReports ? LucideIcons.user : LucideIcons.store, size: 18),
              label: Text(_showUserReports ? "Switch to Business" : "Switch to User"),
              style: TextButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.2), foregroundColor: Colors.black87),
            ),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.blue.shade100, Colors.purple.shade50])),
        child: SafeArea(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _showUserReports
                ? _supabase.from('reports').select('*, posts(*, profiles(*))').order('created_at', ascending: false)
                : _supabase.from('business_reports').select().order('created_at', ascending: false),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("No reports found."));

              final reports = snapshot.data!;
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: reports.length,
                itemBuilder: (context, index) {
                  final report = reports[index];
                  final postData = report['posts'] as Map<String, dynamic>?;
                  return _buildReportCard(report, postData);
                },
              );
            },
          ),
        ),
      ),
    );
  }
}