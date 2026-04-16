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
  // controller and clients
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final _supabase = Supabase.instance.client;

  // logic
  // close chat return user to chatbot
  Future<void> _closeChat() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A35),
        title: const Text(
          "End Support Session?",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "This will return the user to the AI bot.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("End Chat", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _supabase
          .from('support_chats')
          .update({'status': 'bot'})
          .eq('user_id', widget.chatData['user_id']);

      if (mounted) Navigator.pop(context);
    }
  }

  // sends a message trigger for user to report business
  Future<void> _sendReportFormAction(String userId) async {
    try {
      await _supabase.from('support_messages').insert({
        'user_id': userId,
        'content':
            "If you wish to file a formal complaint, please click the card below to fill in the details.",
        'is_admin': true,
      });

      // send the action trigger
      await _supabase.from('support_messages').insert({
        'user_id': userId,
        'content': '[ACTION:REPORT_BUSINESS]',
        'is_admin': true,
      });

      // remains status in active
      await _supabase
          .from('support_chats')
          .update({'status': 'agent_active'})
          .eq('user_id', userId);

      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  // handles sending text messsages
  Future<void> _sendMessage(String userId) async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();

    await _supabase.from('support_messages').insert({
      'user_id': userId,
      'content': text,
      'is_admin': true,
    });

    await _supabase
        .from('support_chats')
        .update({'status': 'agent_active'})
        .eq('user_id', userId);

    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // UI
  @override
  Widget build(BuildContext context) {
    final String userId = widget.chatData['user_id'].toString();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0C29),
      appBar: AppBar(
        title: Text(
          "Chat with ${widget.chatData['username'] ?? 'User'}",
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1A1A35),
        actions: [
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
              stream: _supabase
                  .from('support_messages')
                  .stream(primaryKey: ['id'])
                  .eq('user_id', userId)
                  .order('created_at', ascending: true),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final messages = snapshot.data!;

                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _scrollToBottom(),
                );

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

  // sending the report form
  Widget _buildMessageBubble(String text, bool isAdmin) {
    bool isReportAction = text == '[ACTION:REPORT_BUSINESS]';

    return Align(
      alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isReportAction
              ? Colors.orangeAccent.withOpacity(0.1)
              : (isAdmin
                    ? Colors.blueAccent.withOpacity(0.2)
                    : Colors.white.withOpacity(0.05)),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isReportAction
                ? Colors.orangeAccent
                : (isAdmin ? Colors.blueAccent : Colors.white10),
          ),
        ),
        child: isReportAction
            ? const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.fileText,
                    size: 16,
                    color: Colors.orangeAccent,
                  ),
                  SizedBox(width: 8),
                  Text(
                    "Report Form Sent",
                    style: TextStyle(
                      color: Colors.orangeAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
            : Text(text, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildInputArea(String userId) {
    return Container(
      padding: const EdgeInsets.only(left: 8, right: 16, top: 12, bottom: 32),
      color: const Color(0xFF1A1A35),
      child: Row(
        children: [
          // report form button
          IconButton(
            icon: const Icon(
              LucideIcons.fileWarning,
              color: Colors.orangeAccent,
            ),
            tooltip: "Send Report Form",
            onPressed: () => _sendReportFormAction(userId),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "Type a reply...",
                  hintStyle: TextStyle(color: Colors.white24),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Colors.cyanAccent,
            child: IconButton(
              icon: const Icon(
                LucideIcons.send,
                color: Color(0xFF0F0C29),
                size: 18,
              ),
              onPressed: () => _sendMessage(userId),
            ),
          ),
        ],
      ),
    );
  }
}
