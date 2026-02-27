import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';


class UserChatDetailPage extends StatefulWidget {
  final Map<String, dynamic> userData;
  final Map<String, dynamic> businessData;

  const UserChatDetailPage({
    super.key,
    required this.userData,
    required this.businessData,
  });

  @override
  State<UserChatDetailPage> createState() => _UserChatDetailPageState();
}

class _UserChatDetailPageState extends State<UserChatDetailPage> {
  final _supabase = Supabase.instance.client;
  final _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String userId = widget.userData['id'].toString();
    final String businessId = widget.businessData['id'].toString();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.businessData['business_name'] ?? "Chat"),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              // Order by descending so newest is index 0 for reversed list
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
                  return (mSenderId == userId && mReceiverId == businessId) ||
                      (mSenderId == businessId && mReceiverId == userId);
                }).toList();

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true, // New messages stay at bottom
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final bool isMe = msg['is_from_business'] == false;

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
          _buildInput(userId, businessId),
        ],
      ),
    );
  }

  Widget _buildInput(String uIdStr, String bIdStr) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade200))),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: "Type message...",
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(LucideIcons.send, color: Colors.blueAccent),
              onPressed: () async {
                final text = _messageController.text.trim();
                if (text.isEmpty) return;
                _messageController.clear();

                try {
                  await _supabase.from('messages').insert({
                    'sender_id': int.parse(uIdStr),
                    'receiver_id': int.parse(bIdStr),
                    'content': text,
                    'is_from_business': false,
                  });
                } catch (e) {
                  debugPrint("User Send Error: $e");
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}