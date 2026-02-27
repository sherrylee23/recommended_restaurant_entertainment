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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Messages", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft, end: Alignment.centerRight,
            colors: [Colors.blue.shade100, Colors.purple.shade50],
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _supabase.from('messages').stream(primaryKey: ['id']).order('created_at', ascending: false),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text("No inquiries yet"));
              }

              final allMessages = snapshot.data!;
              final customerIds = allMessages
                  .map((m) => m['sender_id'] == businessId ? m['receiver_id'] : m['sender_id'])
                  .toSet().where((id) => id != businessId).toList();

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: Stack(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.purple.shade50,
                                backgroundImage: profile?['profile_url'] != null ? NetworkImage(profile!['profile_url']) : null,
                                child: profile?['profile_url'] == null ? const Icon(LucideIcons.user, color: Colors.purpleAccent) : null,
                              ),
                              if (hasUnread)
                                Positioned(right: 0, child: Container(width: 12, height: 12, decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)))),
                            ],
                          ),
                          title: Text(username, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(lastMsg['content'] ?? "", maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(_formatDateTime(lastMsg['created_at']),
                                  style: TextStyle(fontSize: 10, color: hasUnread ? Colors.blueAccent : Colors.grey)),
                              const SizedBox(height: 5),
                              Icon(hasUnread ? LucideIcons.mailWarning : LucideIcons.mailCheck,
                                  size: 16, color: hasUnread ? Colors.redAccent : Colors.blueAccent),
                            ],
                          ),
                          onTap: () async {
                            await _supabase.from('messages').update({'is_read': true}).eq('receiver_id', businessId).eq('sender_id', customerId);
                            if (mounted) {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => BusinessReplyPage(businessData: widget.businessData, targetUserId: customerId)));
                            }
                          },
                        ),
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
}