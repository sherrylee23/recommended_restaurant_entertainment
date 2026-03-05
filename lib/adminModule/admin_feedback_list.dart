import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AdminFeedbackListPage extends StatefulWidget {
  const AdminFeedbackListPage({super.key});

  @override
  State<AdminFeedbackListPage> createState() => _AdminFeedbackListPageState();
}

class _AdminFeedbackListPageState extends State<AdminFeedbackListPage> {
  final _supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Background handled by Dashboard Stack
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "User Feedbacks",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _supabase.from('feedbacks').select('''
                  *,
                  profiles (
                    username,
                    email,
                    profile_url
                  )
                ''').order('created_at', ascending: false),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
            }

            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.white70)));
            }

            final feedbacks = snapshot.data ?? [];

            if (feedbacks.isEmpty) {
              return const Center(child: Text("No feedback received yet.", style: TextStyle(color: Colors.white54)));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: feedbacks.length,
              itemBuilder: (context, index) {
                final item = feedbacks[index];
                final profile = item['profiles'] as Map<String, dynamic>?;

                final String username = profile?['username'] ?? "Unknown User";
                final String email = profile?['email'] ?? "No email provided";
                final String? profileUrl = profile?['profile_url'];
                final int rating = item['rating'] ?? 0;

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
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.white.withOpacity(0.1),
                                  backgroundImage: (profileUrl != null && profileUrl.isNotEmpty)
                                      ? NetworkImage(profileUrl)
                                      : null,
                                  child: (profileUrl == null || profileUrl.isEmpty)
                                      ? const Icon(LucideIcons.user, color: Colors.cyanAccent)
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        username,
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                      Text(
                                        email,
                                        style: const TextStyle(fontSize: 12, color: Colors.cyanAccent),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: List.generate(
                                          5,
                                              (starIndex) => Icon(
                                            starIndex < rating ? Icons.star : Icons.star_border,
                                            color: Colors.amberAccent,
                                            size: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  _formatDate(item['created_at']),
                                  style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.5)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "Feedback:",
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.5)),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item['description'] ?? "No description provided.",
                              style: const TextStyle(color: Colors.white70, height: 1.4),
                            ),

                            // FIXED IMAGE SECTION
                            if (item['image_url'] != null && item['image_url'].toString().isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Text(
                                "Attached Image:",
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.4)),
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  constraints: const BoxConstraints(maxHeight: 300),
                                  width: double.infinity,
                                  color: Colors.black26,
                                  child: Image.network(
                                    item['image_url'],
                                    fit: BoxFit.contain,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return const Center(child: Padding(
                                        padding: EdgeInsets.all(20.0),
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyanAccent),
                                      ));
                                    },
                                    errorBuilder: (context, error, stackTrace) => const Padding(
                                      padding: EdgeInsets.all(20.0),
                                      child: Text("Could not load image", style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                                    ),
                                  ),
                                ),
                              ),
                            ],
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

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return "${date.day}/${date.month}/${date.year}";
    } catch (e) {
      return "N/A";
    }
  }
}