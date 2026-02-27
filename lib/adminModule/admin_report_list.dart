import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AdminReportListPage extends StatefulWidget {
  const AdminReportListPage({super.key});

  @override
  State<AdminReportListPage> createState() => _AdminReportListPageState();
}

class _AdminReportListPageState extends State<AdminReportListPage> {
  final _supabase = Supabase.instance.client;

  // Function for Admin to provide feedback and resolve the report
  // Inside _AdminReportListPageState
  void _showFeedbackDialog(Map<String, dynamic> report) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Reply to Complaint"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Business: ${report['business_name']}", style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
                controller: controller,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: "Enter resolution or feedback...",
                  border: OutlineInputBorder(),
                )
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              // Updates the report status and adds admin feedback [cite: 37]
              await _supabase.from('business_reports').update({
                'admin_feedback': controller.text.trim(),
                'status': 'resolved',
              }).eq('id', report['id']);

              if (mounted) {
                Navigator.pop(context);
                setState(() {}); // Refresh the list to show the resolved status [cite: 38]
              }
            },
            child: const Text("Send Feedback"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Business Reports", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade100, Colors.purple.shade50], // Match system style
          ),
        ),
        child: SafeArea(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _supabase.from('business_reports').select().order('created_at', ascending: false),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("No reports found."));

              final reports = snapshot.data!;
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: reports.length,
                itemBuilder: (context, index) {
                  final report = reports[index];
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
                              Text(report['business_name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isResolved ? Colors.green.shade100 : Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  report['status'].toString().toUpperCase(),
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isResolved ? Colors.green : Colors.orange),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text("From: ${report['user_email']}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          const Divider(),
                          Text(report['description']),
                          if (report['media_url'] != null) ...[
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(report['media_url'], height: 150, width: double.infinity, fit: BoxFit.cover),
                            ),
                          ],
                          if (isResolved) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(10),
                              width: double.infinity,
                              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                              child: Text("Admin Feedback: ${report['admin_feedback']}", style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
                            ),
                          ],
                          if (!isResolved) ...[
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _showFeedbackDialog(report),
                                icon: const Icon(LucideIcons.reply, size: 16),
                                label: const Text("Provide Feedback"),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
                              ),
                            ),
                          ],
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