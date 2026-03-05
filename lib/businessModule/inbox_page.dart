import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'reply_page.dart';

class BusinessInboxPage extends StatefulWidget {
  final Map<String, dynamic> businessData;
  const BusinessInboxPage({super.key, required this.businessData});

  @override
  State<BusinessInboxPage> createState() => _BusinessInboxPageState();
}

class _BusinessInboxPageState extends State<BusinessInboxPage> {
  final _supabase = Supabase.instance.client;

  // --- LOGIC PRESERVED ---
  String _formatDateTime(String? dateStr) {
    if (dateStr == null) return "";
    final DateTime date = DateTime.parse(dateStr).toLocal();
    final now = DateTime.now();
    if (date.day == now.day && date.month == now.month && date.year == now.year) {
      return DateFormat.jm().format(date);
    } else {
      return DateFormat('MMM d').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dynamic businessId = widget.businessData['id'];

    return Scaffold(
      backgroundColor: const Color(0xFF0F0C29),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Inquiries", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F0C29), Color(0xFF302B63)],
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _supabase.from('messages').stream(primaryKey: ['id']).order('created_at', ascending: false),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.messageSquare, size: 60, color: Colors.white.withOpacity(0.1)),
                      const SizedBox(height: 15),
                      Text("No inquiries yet", style: TextStyle(color: Colors.white.withOpacity(0.3))),
                    ],
                  ),
                );
              }

              final allMessages = snapshot.data!;
              final customerIds = allMessages
                  .map((m) => m['sender_id'] == businessId ? m['receiver_id'] : m['sender_id'])
                  .toSet().where((id) => id != businessId).toList();

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                itemCount: customerIds.length,
                itemBuilder: (context, index) {
                  final customerId = customerIds[index];
                  final chat = allMessages.where((m) =>
                  (m['sender_id'] == businessId && m['receiver_id'] == customerId) ||
                      (m['sender_id'] == customerId && m['receiver_id'] == businessId)
                  ).toList();

                  if (chat.isEmpty) return const SizedBox.shrink();
                  final lastMsg = chat.first;
                  final bool hasUnread = lastMsg['receiver_id'] == businessId && lastMsg['is_read'] == false;

                  return FutureBuilder<Map<String, dynamic>>(
                    future: _supabase.from('profiles').select('username, profile_url').eq('id', customerId).single(),
                    builder: (context, profileSnapshot) {
                      final profile = profileSnapshot.data;
                      final username = profile?['username'] ?? "Customer";

                      return _buildGlassChatTile(
                        username: username,
                        profileUrl: profile?['profile_url'],
                        lastMsg: lastMsg['content'] ?? "",
                        time: _formatDateTime(lastMsg['created_at']),
                        hasUnread: hasUnread,
                        onTap: () async {
                          await _supabase.from('messages').update({'is_read': true}).eq('receiver_id', businessId).eq('sender_id', customerId);
                          if (mounted) {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => BusinessReplyPage(businessData: widget.businessData, targetUserId: customerId)));
                          }
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildGlassChatTile({
    required String username,
    String? profileUrl,
    required String lastMsg,
    required String time,
    required bool hasUnread,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: hasUnread ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: hasUnread ? Colors.cyanAccent.withOpacity(0.3) : Colors.white.withOpacity(0.05),
                  width: hasUnread ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: hasUnread ? Colors.cyanAccent : Colors.transparent, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.white10,
                          backgroundImage: profileUrl != null ? NetworkImage(profileUrl) : null,
                          child: profileUrl == null ? const Icon(LucideIcons.user, color: Colors.white24) : null,
                        ),
                      ),
                      if (hasUnread)
                        Positioned(
                          right: 4,
                          top: 4,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.cyanAccent,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Colors.cyanAccent.withOpacity(0.5), blurRadius: 8)],
                              border: Border.all(color: const Color(0xFF1A1A35), width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(username,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(lastMsg,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: hasUnread ? Colors.white70 : Colors.white38, fontSize: 13)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(time,
                          style: TextStyle(fontSize: 10, color: hasUnread ? Colors.cyanAccent : Colors.white24)),
                      const SizedBox(height: 8),
                      Icon(
                          hasUnread ? LucideIcons.mailWarning : LucideIcons.mail,
                          size: 16,
                          color: hasUnread ? Colors.cyanAccent : Colors.white10
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}