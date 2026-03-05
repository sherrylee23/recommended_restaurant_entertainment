import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';

class MyReportListPage extends StatelessWidget {
  final Map<String, dynamic> userData;
  const MyReportListPage({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF0F0C29),
      appBar: AppBar(
        title: const Text(
          "My Reports Status",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
          ),
        ),
        child: SafeArea(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: supabase
                .from('business_reports')
                .select()
                .eq('profile_id', userData['id'])
                .order('created_at', ascending: false),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.clipboardList, size: 50, color: Colors.white.withOpacity(0.1)),
                      const SizedBox(height: 16),
                      Text("No reports found.", style: TextStyle(color: Colors.white.withOpacity(0.3))),
                    ],
                  ),
                );
              }

              final reports = snapshot.data!;
              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: reports.length,
                itemBuilder: (context, index) {
                  final report = reports[index];
                  final bool isResolved = report['status'] == 'resolved';
                  final Color statusColor = isResolved ? Colors.greenAccent : Colors.amberAccent;

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
                        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                        child: Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            iconColor: Colors.white,
                            collapsedIconColor: Colors.white54,
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isResolved ? LucideIcons.checkCircle : LucideIcons.clock,
                                color: statusColor,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              report['business_name'] ?? "Unknown Business",
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            subtitle: Text(
                              "Status: ${report['status'].toString().toUpperCase()}",
                              style: TextStyle(color: statusColor.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Divider(color: Colors.white10),
                                    const SizedBox(height: 10),
                                    const Text(
                                      "Your Description:",
                                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyanAccent, fontSize: 13),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      report['description'] ?? "No description provided.",
                                      style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
                                    ),
                                    if (isResolved && report['admin_feedback'] != null) ...[
                                      const SizedBox(height: 15),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: Colors.cyanAccent.withOpacity(0.05),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.cyanAccent.withOpacity(0.2)),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Row(
                                              children: [
                                                Icon(LucideIcons.messageSquare, size: 14, color: Colors.cyanAccent),
                                                SizedBox(width: 8),
                                                Text("Admin Reply", style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              report['admin_feedback'],
                                              style: const TextStyle(color: Colors.white, fontStyle: FontStyle.italic, fontSize: 13),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
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
      ),
    );
  }
}