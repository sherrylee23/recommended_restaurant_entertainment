import 'package:flutter/material.dart';
import 'nomi_chat_logic.dart'; // Ensure this matches your filename
import 'package:recommended_restaurant_entertainment/customer_service/report_business.dart';

class ChatNomiPage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const ChatNomiPage({super.key, required this.userData});

  @override
  State<ChatNomiPage> createState() => _ChatNomiPageState();
}

class _ChatNomiPageState extends State<ChatNomiPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late NomiChatLogic _logic;

  bool _isTyping = false;
  final List<Map<String, dynamic>> _messages = [
    {"text": "Hi! I'm Nomi. How can I help you today?", "isUser": false},
  ];

  @override
  void initState() {
    super.initState();
    _logic = NomiChatLogic(userData: widget.userData);
  }

  Future<void> _handleSend() async {
    final rawText = _controller.text.trim();
    if (rawText.isEmpty || _isTyping) return;

    _controller.clear();
    setState(() {
      _messages.add({"text": rawText, "isUser": true});
      _isTyping = true;
    });
    _scrollToBottom();

    final result = await _logic.sendMessage(rawText);

    if (mounted) {
      setState(() {
        _isTyping = false;
        _messages.add({
          "text": result["text"],
          "isUser": false,
          "showAction": result["showAction"] ?? false
        });
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Chat with Nomi", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Colors.blue.shade100, Colors.purple.shade50],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) => _buildMessageBubble(_messages[index]),
                ),
              ),
              if (_isTyping)
                const Padding(
                  padding: EdgeInsets.only(left: 20, bottom: 10),
                  child: Align(alignment: Alignment.centerLeft, child: Text("Nomi is typing...", style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic))),
                ),
              _buildInputArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg) {
    bool isUser = msg["isUser"] ?? false;
    bool showAction = msg["showAction"] ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) _buildAvatar(isBot: true),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isUser ? const Color(0xFF4A90E2) : Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(msg["text"], style: TextStyle(color: isUser ? Colors.white : Colors.black87, fontSize: 15)),
                ),
              ),
              const SizedBox(width: 8),
              if (isUser) _buildAvatar(isBot: false),
            ],
          ),
          if (showAction)
            Padding(
              padding: const EdgeInsets.only(left: 48, top: 8),
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ReportBusinessPage(userData: widget.userData, businessName: null))),
                icon: const Icon(Icons.assignment_late_outlined, size: 18),
                label: const Text("Fill Report Form"),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar({required bool isBot}) {
    if (isBot) {
      return CircleAvatar(radius: 16, backgroundColor: Colors.purple.shade200, child: const Text("N", style: TextStyle(fontSize: 12, color: Colors.white)));
    } else {
      final String? profileUrl = widget.userData['profile_url'];
      return CircleAvatar(radius: 16, backgroundImage: (profileUrl != null && profileUrl.isNotEmpty) ? NetworkImage(profileUrl) : null, child: (profileUrl == null || profileUrl.isEmpty) ? const Icon(Icons.person, size: 16) : null);
    }
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(child: TextField(controller: _controller, decoration: const InputDecoration(hintText: "Ask Nomi anything...", border: InputBorder.none), onSubmitted: (_) => _handleSend())),
          IconButton(icon: Icon(Icons.send, color: _isTyping ? Colors.grey : const Color(0xFF4A90E2)), onPressed: _handleSend),
        ],
      ),
    );
  }
}