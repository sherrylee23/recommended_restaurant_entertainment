import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'nomi_chat_logic.dart';
import 'package:recommended_restaurant_entertainment/customer_service/report_business.dart';
import '../language_provider.dart';

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

  bool _isConnectingToAgent = false;
  bool _isWithAgent = false;
  bool _isTyping = false;

  final List<Map<String, dynamic>> _messages = [
    {"text": "Hi! I'm Nomi. How can I help you today?", "isUser": false},
  ];

  @override
  void initState() {
    super.initState();
    _logic = NomiChatLogic(userData: widget.userData);
    _checkExistingSession();
  }

  Future<void> _checkExistingSession() async {
    final response = await Supabase.instance.client
        .from('support_chats')
        .select('status')
        .eq('user_id', widget.userData['id'])
        .maybeSingle();

    if (response != null && (response['status'] == 'waiting_for_agent' || response['status'] == 'agent_active')) {
      if (mounted) {
        setState(() {
          _isWithAgent = true;
        });
      }
    }
  }

  Future<void> _handleSend() async {
    final rawText = _controller.text.trim();
    if (rawText.isEmpty) return;

    if (_isWithAgent) {
      _controller.clear();
      try {
        await Supabase.instance.client.from('support_messages').insert({
          'user_id': widget.userData['id'],
          'content': rawText,
          'is_admin': false,
        });

        await Supabase.instance.client
            .from('support_chats')
            .update({'last_message_at': DateTime.now().toIso8601String()})
            .eq('user_id', widget.userData['id']);

        _scrollToBottom();
      } catch (e) {
        debugPrint("Error sending message to DB: $e");
      }
    } else {
      if (_isTyping) return;
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

        if (result["text"].contains("[TRIGGER_AGENT]")) {
          _connectToAgent();
        }
      }
    }
  }

  Future<void> _connectToAgent() async {
    if (_isWithAgent || _isConnectingToAgent) return;
    setState(() => _isConnectingToAgent = true);

    await _logic.switchToHumanAgent();

    if (mounted) {
      setState(() {
        _isConnectingToAgent = false;
        _isWithAgent = true;
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
    final lp = Provider.of<LanguageProvider>(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF0F0C29),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
            _isWithAgent ? lp.getString('live_support') : lp.getString('chat_nomi_title'),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (!_isWithAgent)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: TextButton.icon(
                onPressed: _isConnectingToAgent ? null : _connectToAgent,
                icon: Icon(
                  _isConnectingToAgent ? LucideIcons.loader : LucideIcons.headphones,
                  size: 16,
                  color: Colors.cyanAccent,
                ),
                label: Text(
                  _isConnectingToAgent ? lp.getString('connecting') : lp.getString('live_support'),
                  style: const TextStyle(color: Colors.cyanAccent, fontSize: 12),
                ),
              ),
            ),
        ],
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
                child: !_isWithAgent
                    ? ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) => _buildMessageBubble(_messages[index], lp),
                )
                    : StreamBuilder<List<Map<String, dynamic>>>(
                  stream: Supabase.instance.client
                      .from('support_messages')
                      .stream(primaryKey: ['id'])
                      .eq('user_id', widget.userData['id'])
                      .order('created_at', ascending: true),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                    final messages = snapshot.data!;
                    _scrollToBottom();

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        return _buildMessageBubble({
                          "text": msg['content'],
                          "isUser": !msg['is_admin'],
                          "isAdminAction": msg['is_admin'] == true && msg['content'] == '[ACTION:REPORT_BUSINESS]',
                        }, lp);
                      },
                    );
                  },
                ),
              ),
              if (_isTyping) _buildTypingIndicator(),
              _buildInputArea(lp),
            ],
          ),
        ),
      ),
    );
  }

  // check is the admin send the report form
  Widget _buildMessageBubble(Map<String, dynamic> msg, LanguageProvider lp) {
    bool isUser = msg["isUser"] ?? false;
    bool showAction = msg["showAction"] ?? false;
    bool isAdminAction = msg["isAdminAction"] ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (isAdminAction)
            _buildAdminReportCard(lp)
          else
            Row(
              mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!isUser) _buildAvatar(isBot: !_isWithAgent),
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
                label: Text(lp.getString('fill_report_btn'), style: const TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.bold)),
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

  Widget _buildAdminReportCard(LanguageProvider lp) {
    return Container(
      margin: const EdgeInsets.only(left: 45, top: 5, bottom: 5),
      width: 250,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amberAccent.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amberAccent.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: const Row(
              children: [
                Icon(LucideIcons.megaphone, color: Colors.amberAccent, size: 20),
                SizedBox(width: 10),
                Text("Report Business", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  lp.getString('report_card_desc') ?? "Please fill in the form to report a business.",
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ReportBusinessPage(userData: widget.userData))),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amberAccent,
                      foregroundColor: const Color(0xFF0F0C29),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(lp.getString('fill_report_btn'), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
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

  Widget _buildInputArea(LanguageProvider lp) {
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
                      hintText: _isWithAgent ? lp.getString('support_input_hint') : lp.getString('nomi_input_hint'),
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
                      gradient: (_isTyping && !_isWithAgent)
                          ? null
                          : const LinearGradient(colors: [Colors.cyanAccent, Colors.blueAccent]),
                      color: (_isTyping && !_isWithAgent) ? Colors.white10 : null,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                        LucideIcons.navigation,
                        color: (_isTyping && !_isWithAgent) ? Colors.white24 : const Color(0xFF0F0C29),
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
}

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
      return Tween<double>(begin: 0, end: -5).animate(
          CurvedAnimation(parent: controller, curve: Curves.easeInOut)
      );
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