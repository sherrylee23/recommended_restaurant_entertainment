import 'package:flutter/material.dart';
// 确保路径指向你新写的 ReportBusinessPage
import 'package:recommended_restaurant_entertainment/customer_service/report_business.dart';
import 'package:image_picker/image_picker.dart';

class ChatNomiPage extends StatefulWidget {
  // 新增：接收用户数据
  final Map<String, dynamic> userData;
  const ChatNomiPage({super.key, required this.userData});

  @override
  State<ChatNomiPage> createState() => _ChatNomiPageState();
}

class _ChatNomiPageState extends State<ChatNomiPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> _messages = [
    {"text": "Hi! I'm Nomi. How can I help you today?", "isUser": false},
  ];

  void _handleSend() {
    if (_controller.text.trim().isEmpty) return;

    String userText = _controller.text.toLowerCase();
    setState(() {
      _messages.add({"text": _controller.text, "isUser": true});
    });

    // 逻辑触发器：识别举报关键词
    if (userText.contains("complaint") || userText.contains("report") || userText.contains("bad service")) {
      _botResponse("I'm sorry to hear that. Please fill out our official report form so we can investigate.", showAction: true);
    } else {
      _botResponse("I'm here to help! You can ask me about reporting a business or general assistance.");
    }

    _controller.clear();
    _scrollToBottom();
  }

  void _botResponse(String text, {bool showAction = false}) {
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() {
        _messages.add({
          "text": text,
          "isUser": false,
          "showAction": showAction
        });
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
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
            colors: [Colors.blue.shade100, Colors.purple.shade50], // 保持系统风格 [cite: 4, 82]
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
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    return _buildMessageBubble(msg);
                  },
                ),
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
                    color: isUser ? const Color(0xFF4A90E2) : Colors.white.withOpacity(0.9), // 用户气泡改用品牌蓝
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    msg["text"],
                    style: TextStyle(color: isUser ? Colors.white : Colors.black87),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (isUser) _buildAvatar(isBot: false),
            ],
          ),
          if (showAction)
            Padding(
              padding: const EdgeInsets.only(left: 48, top: 8),
              child: ElevatedButton(
                onPressed: () {
                  // 修改：跳转时传递必要的 userData
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReportBusinessPage(
                        userData: widget.userData,
                        businessName: "Plaza Restaurant", // 这里可以根据 AI 识别的结果传参
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 2,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.assignment_late_outlined, size: 18),
                    SizedBox(width: 8),
                    Text("Fill Report Form"),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_ios, size: 12),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar({required bool isBot}) {
    if (isBot) {
      return CircleAvatar(
        radius: 16,
        backgroundColor: Colors.purple.shade100,
        child: const Text("N", style: TextStyle(fontSize: 12, color: Colors.purple, fontWeight: FontWeight.bold)),
      );
    } else {
      // 优化：显示真实的用户头像
      final String? profileUrl = widget.userData['profile_url'];
      return CircleAvatar(
        radius: 16,
        backgroundImage: (profileUrl != null && profileUrl.isNotEmpty) ? NetworkImage(profileUrl) : null,
        child: (profileUrl == null || profileUrl.isEmpty) ? const Icon(Icons.person, size: 16) : null,
      );
    }
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: "Type a message...",
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _handleSend(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Color(0xFF4A90E2)), // 统一按钮颜色 [cite: 22]
            onPressed: _handleSend,
          ),
        ],
      ),
    );
  }
}