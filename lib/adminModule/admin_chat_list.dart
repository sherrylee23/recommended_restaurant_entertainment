import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'admin_chat_detail.dart';

class AdminChatPage extends StatefulWidget {
  const AdminChatPage({super.key});

  @override
  State<AdminChatPage> createState() => _AdminChatPageState();
}

class _AdminChatPageState extends State<AdminChatPage> {
  // stream to listen for real-time updates
  // ordered by most recent
  final _chatStream = Supabase.instance.client
      .from('support_chats')
      .stream(primaryKey: ['id'])
      .order('last_message_at', ascending: false);


  // UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0C29),
      appBar: AppBar(
        title: const Text("Support Tickets", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _chatStream,
        builder: (context, snapshot) {
          // handle loading state
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));

          final chats = snapshot.data!;
          // handle empty state
          if (chats.isEmpty) {
            return const Center(child: Text("No active support requests.", style: TextStyle(color: Colors.white38)));
          }
          // build list of chat ticket
          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final bool isWaiting = chat['status'] == 'waiting_for_agent';

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: isWaiting ? Colors.redAccent.withOpacity(0.3) : Colors.white10),
                ),
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: Color(0xFF302B63), child: Icon(LucideIcons.user, color: Colors.cyanAccent)),
                  title: Text(chat['username'] ?? "User #${chat['user_id'].toString().substring(0,5)}", style: const TextStyle(color: Colors.white)),
                  subtitle: Text(isWaiting ? "User is waiting for help..." : "Chat Active",
                      style: TextStyle(color: isWaiting ? Colors.redAccent : Colors.white38, fontSize: 12)),
                  trailing: const Icon(LucideIcons.chevronRight, color: Colors.white24),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AdminChatDetailScreen(chatData: chat)),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}