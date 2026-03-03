import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
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

  // AI Configuration
  late final GenerativeModel _model;
  late ChatSession _chatSession;
  bool _isTyping = false;

  // Initial message list
  final List<Map<String, dynamic>> _messages = [
    {"text": "Hi! I'm Nomi. How can I help you today?", "isUser": false},
  ];

  @override
  void initState() {
    super.initState();
    // 1. Initialize the Model (Replace with your actual Gemini API Key)
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: 'YOUR_GEMINI_API_KEY_HERE',
    );

    // 2. Start session with detailed instructions about user levels & restrictions
    _chatSession = _model.startChat(
      history: [
        Content.text(
            "User's name is ${widget.userData['username'] ?? 'Guest'}. "
                "You are Nomi, a helpful assistant for a restaurant app. "
                "Explain user levels and COMMENT RESTRICTIONS if asked: "
                "1. New User (Joined < 14 days): Restricted to 3 comments per day. "
                "2. Active User (Joined 14-365 days): Restricted to 10 comments per day. "
                "3. Trusted User (Joined > 365 days): No restriction (Unlimited comments). "
                "If a user mentions a complaint, bad service, or reporting, tell them you can provide a report form."
        ),
      ],
    );
  }

  Future<void> _handleSend() async {
    final rawText = _controller.text.trim();
    final lowercaseText = rawText.toLowerCase();

    if (rawText.isEmpty || _isTyping) return;

    _controller.clear();
    setState(() {
      _messages.add({"text": rawText, "isUser": true});
      _isTyping = true;
    });
    _scrollToBottom();

    try {
      // 1. Try to get a real answer from Gemini AI
      final response = await _chatSession.sendMessage(Content.text(rawText));
      final botText = response.text ?? "";

      // Check for report-related keywords to show the action button
      bool needsReport =
          botText.toLowerCase().contains("report form") ||
              lowercaseText.contains("report") ||
              lowercaseText.contains("complaint");

      _addBotMessage(botText, showAction: needsReport);

    } catch (e) {
      debugPrint("AI Error: $e");

      // 2. FALLBACK LOGIC: If AI fails or is offline
      if (lowercaseText.contains("comment") && (lowercaseText.contains("limit") || lowercaseText.contains("restrict"))) {
        _addBotMessage(
            "To maintain quality reviews, we have daily limits: \n"
                "• New Users: 3 comments/day\n"
                "• Active Users: 10 comments/day\n"
                "• Trusted Users: Unlimited"
        );
      }
      else if (lowercaseText.contains("new user")) {
        _addBotMessage(
            "New Users (joined < 14 days) are restricted to 3 review comments per day to prevent spam."
        );
      }
      else if (lowercaseText.contains("active user")) {
        _addBotMessage(
            "Active Users (joined > 14 days) have an increased limit of 10 review comments per day!"
        );
      }
      else if (lowercaseText.contains("report") || lowercaseText.contains("complaint")) {
        _addBotMessage(
          "I'm sorry you're having trouble. Please fill out our official report form so we can help.",
          showAction: true,
        );
      }
      else if (lowercaseText.contains("hello") || lowercaseText.contains("hi")) {
        _addBotMessage("Hi! I'm Nomi. How can I help you today?");
      }
      else {
        _addBotMessage(
          "I'm currently having trouble reaching my AI brain, but you can ask me about 'comment limits' or 'reporting' a business!",
        );
      }
    } finally {
      if (mounted) setState(() => _isTyping = false);
    }
  }

  void _addBotMessage(String text, {bool showAction = false}) {
    if (!mounted) return;
    setState(() {
      _messages.add({"text": text, "isUser": false, "showAction": showAction});
    });
    _scrollToBottom();
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
        title: const Text(
          "Chat with Nomi",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
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
                  itemBuilder: (context, index) =>
                      _buildMessageBubble(_messages[index]),
                ),
              ),
              if (_isTyping)
                const Padding(
                  padding: EdgeInsets.only(left: 20, bottom: 10),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Nomi is typing...",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
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
                    color: isUser ? const Color(0xFF4A90E2) : Colors.white.withOpacity(0.9),
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
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReportBusinessPage(
                        userData: widget.userData,
                        businessName: null,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.assignment_late_outlined, size: 18),
                label: const Text("Fill Report Form"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(hintText: "Ask Nomi anything...", border: InputBorder.none),
              onSubmitted: (_) => _handleSend(),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send, color: _isTyping ? Colors.grey : const Color(0xFF4A90E2)),
            onPressed: _handleSend,
          ),
        ],
      ),
    );
  }
}