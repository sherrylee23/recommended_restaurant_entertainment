import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class chatbot extends StatefulWidget {
  const chatbot({super.key});

  @override
  State<chatbot> createState() => _chatbotState();
}

class _chatbotState extends State<chatbot> {
  final TextEditingController _messageController = TextEditingController();
  bool _showAttachment = false;

  // Mock chat data based on your screenshot
  final List<Map<String, dynamic>> _messages = [
    {"text": "Hello!", "isUser": true},
    {"text": "Hi.", "isUser": false},
    {"text": "I want to compliant against a restaurant. Plaza Restaurant", "isUser": true},
    {"text": "Report Business Attitude >", "isUser": false, "isAction": true},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Chat with Nomi', style: TextStyle(color: Colors.black, fontSize: 18)),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildChatBubble(msg);
              },
            ),
          ),
          _buildInputArea(),
          if (_showAttachment) _buildAttachmentDrawer(),
        ],
      ),
    );
  }

  Widget _buildChatBubble(Map<String, dynamic> msg) {
    bool isUser = msg['isUser'];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const CircleAvatar(radius: 15, backgroundColor: Color(0xFFE1D5FF), child: Text('N', style: TextStyle(fontSize: 12))),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: msg['isAction'] == true
                    ? Colors.white
                    : (isUser ? const Color(0xFFC4C4C4) : const Color(0xFFF0F0F0)),
                borderRadius: BorderRadius.circular(8),
                border: msg['isAction'] == true ? Border.all(color: Colors.grey.shade300) : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(msg['text'], style: const TextStyle(fontSize: 14)),
                  if (msg['isAction'] == true) const Icon(Icons.chevron_right, size: 16),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 15,
              backgroundImage: NetworkImage('https://api.dicebear.com/7.x/avataaars/png?seed=windy'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFFD9D9D9),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(hintText: "Message...", border: InputBorder.none),
            ),
          ),
          IconButton(icon: const Icon(LucideIcons.smile), onPressed: () {}),
          IconButton(
            icon: const Icon(LucideIcons.plus),
            onPressed: () => setState(() => _showAttachment = !_showAttachment),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentDrawer() {
    return Container(
      height: 120,
      color: const Color(0xFFD9D9D9),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildAttachBtn(LucideIcons.image, "Gallery"),
          _buildAttachBtn(LucideIcons.camera, "Camera"),
        ],
      ),
    );
  }

  Widget _buildAttachBtn(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, size: 30),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}