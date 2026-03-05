import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';

class BusinessReplyPage extends StatefulWidget {
  final Map<String, dynamic> businessData;
  final dynamic targetUserId;

  const BusinessReplyPage({
    super.key,
    required this.businessData,
    required this.targetUserId,
  });

  @override
  State<BusinessReplyPage> createState() => _BusinessReplyPageState();
}

class _BusinessReplyPageState extends State<BusinessReplyPage> {
  final _supabase = Supabase.instance.client;
  final _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // --- Logic for Business sending messages ---
  Future<void> _sendReply() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final String rawBusId = widget.businessData['id'].toString();
    final String rawUserId = widget.targetUserId.toString();

    try {
      final int bId = int.parse(rawBusId);
      final int uId = int.parse(rawUserId);

      await _supabase.from('messages').insert({
        'sender_id': bId,
        'receiver_id': uId,
        'content': text,
        'is_from_business': true,
      });

      _messageController.clear();
      if (_scrollController.hasClients) {
        _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    } catch (e) {
      debugPrint("Business Send Error: $e");
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String businessId = widget.businessData['id'].toString();
    final String targetUserId = widget.targetUserId.toString();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0C29),
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        // --- UPDATED TITLE: Now fetches the Username ---
        title: FutureBuilder<Map<String, dynamic>>(
          future: _supabase
              .from('profiles')
              .select('username')
              .eq('id', widget.targetUserId)
              .single(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Text(
                snapshot.data!['username'] ?? "Customer",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              );
            }
            return Text(
              "Inquiry: ${widget.targetUserId}", // Fallback to ID while loading
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            );
          },
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
              ),
            ),
          ),
          Column(
            children: [
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _supabase
                      .from('messages')
                      .stream(primaryKey: ['id'])
                      .order('created_at', ascending: false),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));

                    final messages = snapshot.data!.where((m) {
                      final String mSenderId = m['sender_id'].toString();
                      final String mReceiverId = m['receiver_id'].toString();
                      return (mSenderId == businessId && mReceiverId == targetUserId) ||
                          (mSenderId == targetUserId && mReceiverId == businessId);
                    }).toList();

                    return ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: EdgeInsets.only(
                          top: MediaQuery.of(context).padding.top + 70,
                          left: 16, right: 16, bottom: 20
                      ),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final bool isMe = msg['is_from_business'] == true;

                        final DateTime? createdAt = DateTime.tryParse(msg['created_at'] ?? "");
                        final String timeString = createdAt != null
                            ? "${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}"
                            : "";

                        return _buildChatBubble(msg['content'] ?? "", timeString, isMe);
                      },
                    );
                  },
                ),
              ),
              _buildInputArea(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(String text, String time, bool isMe) {
    return Column(
      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            decoration: BoxDecoration(
              gradient: isMe
                  ? const LinearGradient(colors: [Colors.cyanAccent, Colors.blueAccent])
                  : LinearGradient(colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)]),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isMe ? 20 : 5),
                bottomRight: Radius.circular(isMe ? 5 : 20),
              ),
            ),
            child: Text(
              text,
              style: TextStyle(
                  color: isMe ? const Color(0xFF0F0C29) : Colors.white,
                  fontSize: 15,
                  fontWeight: isMe ? FontWeight.w600 : FontWeight.normal
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0, left: 8, right: 8),
          child: Text(time, style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.3))),
        ),
      ],
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextField(
                  controller: _messageController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Type a reply...",
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _sendReply,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [Colors.cyanAccent, Colors.blueAccent]),
                ),
                child: const Icon(LucideIcons.send, color: Color(0xFF0F0C29), size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}