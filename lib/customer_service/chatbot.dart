import 'package:flutter/material.dart';
import 'package:recommended_restaurant_entertainment/customer_service/report_business.dart';
import 'package:recommended_restaurant_entertainment/userModule/feedback.dart';
import 'package:image_picker/image_picker.dart';

class ChatNomiPage extends StatefulWidget {
  const ChatNomiPage({super.key});

  @override
  State<ChatNomiPage> createState() => _ChatNomiPageState();
}

class _ChatNomiPageState extends State<ChatNomiPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Initial message from Nomi
  final List<Map<String, dynamic>> _messages = [
    {"text": "Hi.", "isUser": false},
  ];

  void _handleSend() {
    if (_controller.text.trim().isEmpty) return;

    String userText = _controller.text.toLowerCase();
    setState(() {
      _messages.add({"text": _controller.text, "isUser": true});
    });

    // Simple logic to trigger the complaint button
    if (userText.contains("complaint") || userText.contains("report") || userText.contains("restaurant")) {
      _botResponse("I understand. To help our team investigate, please use our official form.", showAction: true);
    } else {
      _botResponse("Hello! I'm Nomi. I can help guide you to the complaint form if you need assistance.");
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

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);

    if (image != null) {
      setState(() {
        // For now, we just add a text message saying an image was sent
        // In a real app, you'd display the image in the bubble
        _messages.add({"text": "Sent an image: ${image.name}", "isUser": true});
      });
      _scrollToBottom();
    }
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Gallery'),
                  onTap: () {
                    _pickImage(ImageSource.gallery);
                    Navigator.of(context).pop();
                  }),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
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
        title: const Text("Chat with Nomi", style: TextStyle(color: Colors.black87)),
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
              if (!isUser) _buildAvatar("N"), // Bot Avatar
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isUser ? Colors.grey[400] : Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    msg["text"],
                    style: TextStyle(color: isUser ? Colors.white : Colors.black87),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (isUser) _buildAvatar("U"), // User Avatar placeholder
            ],
          ),
          if (showAction)
            Padding(
              padding: const EdgeInsets.only(left: 48, top: 8),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ReportBusinessPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 1,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Report Business Attitude"),
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

  Widget _buildAvatar(String label) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: Colors.purple.shade100,
      child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.purple)),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.grey.shade200.withOpacity(0.8),
      child: Row(
        children: [
          const Icon(Icons.grid_view_rounded, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: "Message...",
                border: InputBorder.none,
              ),
            ),
          ),
          const Icon(Icons.emoji_emotions_outlined, color: Colors.grey),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.grey),
            onPressed: _handleSend, // Modified to act as the send button
          ),
        ],
      ),
    );
  }
}