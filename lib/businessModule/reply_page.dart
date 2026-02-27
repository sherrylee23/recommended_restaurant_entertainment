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
    } catch (e) {
      debugPrint("Business Send Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Send failed: $e")),
        );
      }
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
      appBar: AppBar(
        title: const Text("Chat with Customer"),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _supabase
                  .from('messages')
                  .stream(primaryKey: ['id'])
                  .order('created_at', ascending: false),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final messages = snapshot.data!.where((m) {
                  final String mSenderId = m['sender_id'].toString();
                  final String mReceiverId = m['receiver_id'].toString();
                  return (mSenderId == businessId && mReceiverId == targetUserId) ||
                      (mSenderId == targetUserId && mReceiverId == businessId);
                }).toList();

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true, // Flips list so new items start at bottom
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final bool isMe = msg['is_from_business'] == true;

                    final DateTime? createdAt = DateTime.tryParse(msg['created_at'] ?? "");
                    final String timeString = createdAt != null
                        ? "${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}"
                        : "";

                    return Column(
                      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isMe ? Colors.blue.shade100 : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Text(msg['content'] ?? "", style: const TextStyle(fontSize: 16)),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0, left: 4, right: 4),
                          child: Text(timeString, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade200))),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: "Reply to customer...",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(LucideIcons.send, color: Colors.blueAccent),
              onPressed: _sendReply,
            ),
          ],
        ),
      ),
    );
  }
}