import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AdminReportBusinessListPage extends StatefulWidget {
  const AdminReportBusinessListPage({super.key});

  @override
  State<AdminReportBusinessListPage> createState() => _AdminReportBusinessListPageState();
}

class _AdminReportBusinessListPageState extends State<AdminReportBusinessListPage> {
  final _supabase = Supabase.instance.client;

  // --- DESIGNED DIALOG ---
  void _showFeedbackDialog(Map<String, dynamic> report) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: const Color(0xFF1A1A35),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.white.withOpacity(0.1))),
          title: const Text("Reply to Complaint", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Business: ${report['business_name']}", style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              TextField(
                controller: controller,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Enter resolution or feedback...",
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel", style: TextStyle(color: Colors.white.withOpacity(0.6)))),
            ElevatedButton(
              onPressed: () async {
                await _supabase.from('business_reports').update({
                  'admin_feedback': controller.text.trim(),
                  'status': 'resolved',
                }).eq('id', report['id']);
                if (mounted) {
                  Navigator.pop(context);
                  setState(() {});
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: const Color(0xFF0F0C29), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: const Text("Send Feedback", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Background handled by Dashboard Stack
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Business Complaints", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _supabase.from('business_reports').select().order('created_at', ascending: false),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
            final reports = snapshot.data ?? [];

            if (reports.isEmpty) return const Center(child: Text("No complaints found.", style: TextStyle(color: Colors.white54)));

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: reports.length,
              itemBuilder: (context, index) {
                final report = reports[index];
                final bool isResolved = report['status'] == 'resolved';

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
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
                                Expanded(child: Text(report['business_name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white))),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isResolved ? Colors.greenAccent.withOpacity(0.1) : Colors.orangeAccent.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: isResolved ? Colors.greenAccent.withOpacity(0.3) : Colors.orangeAccent.withOpacity(0.3)),
                                  ),
                                  child: Text(report['status'].toString().toUpperCase(),
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isResolved ? Colors.greenAccent : Colors.orangeAccent)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text("From: ${report['user_email']}", style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.4))),
                            const Divider(color: Colors.white10, height: 24),
                            Text(report['description'] ?? "No description provided.", style: const TextStyle(color: Colors.white70, height: 1.4)),

                            // EVIDENCE IMAGE SECTION
                            if (report['media_url'] != null && report['media_url'].toString().isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Text("Evidence:", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.4))),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  constraints: const BoxConstraints(maxHeight: 300),
                                  width: double.infinity,
                                  color: Colors.black26,
                                  child: Image.network(
                                    report['media_url'],
                                    fit: BoxFit.contain,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return const Center(child: Padding(padding: EdgeInsets.all(20.0), child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyanAccent)));
                                    },
                                    errorBuilder: (context, error, stackTrace) => const Padding(padding: EdgeInsets.all(20.0), child: Text("Could not load evidence", style: TextStyle(color: Colors.redAccent, fontSize: 11))),
                                  ),
                                ),
                              ),
                            ],

                            if (isResolved)
                              Container(
                                margin: const EdgeInsets.only(top: 16),
                                padding: const EdgeInsets.all(12),
                                width: double.infinity,
                                decoration: BoxDecoration(color: Colors.cyanAccent.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.cyanAccent.withOpacity(0.1))),
                                child: Text("Admin Feedback: ${report['admin_feedback']}", style: const TextStyle(fontSize: 13, color: Colors.cyanAccent, fontStyle: FontStyle.italic)),
                              )
                            else
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(colors: [Colors.cyanAccent, Colors.blueAccent]),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ElevatedButton.icon(
                                      onPressed: () => _showFeedbackDialog(report),
                                      icon: const Icon(LucideIcons.reply, size: 16),
                                      label: const Text("Provide Feedback", style: TextStyle(fontWeight: FontWeight.bold)),
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          foregroundColor: const Color(0xFF0F0C29),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                                      )
                                  ),
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