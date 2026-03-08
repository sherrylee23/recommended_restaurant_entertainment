import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AdminChatDetailScreen extends StatefulWidget {
  final Map<String, dynamic> chatData;
  const AdminChatDetailScreen({super.key, required this.chatData});

  @override
  State<AdminChatDetailScreen> createState() => _AdminChatDetailScreenState();
}

class _AdminChatDetailScreenState extends State<AdminChatDetailScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Future<void> _closeChat() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("End Support Session?"),
        content: const Text("This will return the user to the AI bot."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("End Chat", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await Supabase.instance.client
          .from('support_chats')
          .update({'status': 'bot'}) // Set status back to bot
          .eq('user_id', widget.chatData['user_id']);

      if (mounted) Navigator.pop(context); // Go back to the chat list
    }
  }

  @override
  Widget build(BuildContext context) {
    final String userId = widget.chatData['user_id'].toString();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0C29),
      appBar: AppBar(
        title: Text("Chat with ${widget.chatData['username'] ?? 'User'}", style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1A1A35),
        actions: [
          // ADD THE CLOSE BUTTON HERE
          IconButton(
            icon: const Icon(LucideIcons.xCircle, color: Colors.redAccent),
            tooltip: "Close Chat",
            onPressed: _closeChat,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              // Stream messages specifically for this chat
              stream: Supabase.instance.client
                  .from('support_messages')
                  .stream(primaryKey: ['id'])
                  .eq('user_id', userId)
                  .order('created_at', ascending: true),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();
                final messages = snapshot.data!;

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final bool isAdmin = msg['is_admin'] == true;
                    return _buildMessageBubble(msg['content'], isAdmin);
                  },
                );
              },
            ),
          ),
          _buildInputArea(userId),
        ],
      ),
    );
  }

  Future<void> _sendMessage(String userId) async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();

    // 1. Send the message
    await Supabase.instance.client.from('support_messages').insert({
      'user_id': userId,
      'content': text,
      'is_admin': true,
    });

    // 2. Mark the chat as active so the user knows an agent is here
    await Supabase.instance.client
        .from('support_chats')
        .update({'status': 'agent_active'})
        .eq('user_id', userId);

    _scrollController.animateTo(_scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  Widget _buildMessageBubble(String text, bool isAdmin) {
    return Align(
      alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isAdmin ? Colors.blueAccent.withOpacity(0.2) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isAdmin ? Colors.blueAccent : Colors.white10),
        ),
        child: Text(text, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildInputArea(String userId) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF1A1A35),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: "Type a reply...", hintStyle: TextStyle(color: Colors.white24), border: InputBorder.none),
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.send, color: Colors.cyanAccent),
            onPressed: () => _sendMessage(userId),
          ),
        ],
      ),
    );
  }
}