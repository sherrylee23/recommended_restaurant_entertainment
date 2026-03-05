import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'nomi_chat_logic.dart';
import 'package:recommended_restaurant_entertainment/customer_service/report_business.dart';

class ChatNomiPage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const ChatNomiPage({super.key, required this.userData});

  @override
  State<ChatNomiPage> createState() => _ChatNomiPageState();
}

class _ChatNomiPageState extends State<ChatNomiPage> with TickerProviderStateMixin {
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
      backgroundColor: const Color(0xFF0F0C29),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Chat with Nomi", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) => _buildMessageBubble(_messages[index]),
                ),
              ),
              if (_isTyping) _buildTypingIndicator(),
              _buildInputArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 20, bottom: 15),
      child: Row(
        children: [
          _buildAvatar(isBot: true),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: const _BouncingDots(),
          ),
        ],
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
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) _buildAvatar(isBot: true),
              const SizedBox(width: 10),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isUser
                        ? Colors.cyanAccent.withOpacity(0.15)
                        : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 0),
                      bottomRight: Radius.circular(isUser ? 0 : 18),
                    ),
                    border: Border.all(
                        color: isUser ? Colors.cyanAccent.withOpacity(0.2) : Colors.white.withOpacity(0.1)
                    ),
                  ),
                  child: Text(
                      msg["text"],
                      style: TextStyle(color: isUser ? Colors.white : Colors.white.withOpacity(0.9), fontSize: 14, height: 1.4)
                  ),
                ),
              ),
              const SizedBox(width: 10),
              if (isUser) _buildAvatar(isBot: false),
            ],
          ),
          if (showAction)
            Padding(
              padding: const EdgeInsets.only(left: 45, top: 12),
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ReportBusinessPage(userData: widget.userData, businessName: null))),
                icon: const Icon(LucideIcons.fileWarning, size: 16, color: Colors.amberAccent),
                label: const Text("Fill Report Form", style: TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.amberAccent.withOpacity(0.5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  backgroundColor: Colors.amberAccent.withOpacity(0.05),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar({required bool isBot}) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: isBot ? Colors.purpleAccent.withOpacity(0.4) : Colors.cyanAccent.withOpacity(0.2),
            blurRadius: 10,
          )
        ],
      ),
      child: CircleAvatar(
        radius: 18,
        backgroundColor: isBot ? const Color(0xFF1A1A35) : Colors.white.withOpacity(0.1),
        backgroundImage: !isBot && widget.userData['profile_url'] != null
            ? NetworkImage(widget.userData['profile_url'])
            : null,
        child: isBot
            ? const Text("👻", style: TextStyle(fontSize: 18))
            : (!isBot && widget.userData['profile_url'] == null
            ? const Icon(LucideIcons.user, size: 14, color: Colors.white70)
            : null),
      ),
    );
  }

  Widget _buildInputArea() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 25),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: "Ask Nomi anything...",
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _handleSend(),
                  ),
                ),
                GestureDetector(
                  onTap: _handleSend,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: _isTyping
                          ? null
                          : const LinearGradient(colors: [Colors.cyanAccent, Colors.blueAccent]),
                      color: _isTyping ? Colors.white10 : null,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                        LucideIcons.navigation, // Looks very clean and high-tech
                        color: _isTyping ? Colors.white24 : const Color(0xFF0F0C29),
                        size: 18
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Helper Widget for the Bouncing Dots Animation
class _BouncingDots extends StatefulWidget {
  const _BouncingDots();
  @override
  _BouncingDotsState createState() => _BouncingDotsState();
}

class _BouncingDotsState extends State<_BouncingDots> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (index) {
      return AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    });

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0, end: -5).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
    }).toList();

    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) _controllers[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              transform: Matrix4.translationValues(0, _animations[index].value, 0),
              height: 6,
              width: 6,
              decoration: const BoxDecoration(color: Colors.cyanAccent, shape: BoxShape.circle),
            );
          },
        );
      }),
    );
  }
}