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

  Future<void> _sendReply() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final String rawBusId = widget.businessData['id'].toString();
    final String rawUserId = widget.targetUserId.toString();

    try {
      await _supabase.from('messages').insert({
        'sender_id': int.parse(rawBusId),
        'receiver_id': int.parse(rawUserId),
        'content': text,
        'is_from_business': true,
      });
      _messageController.clear();
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
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(
          0xFF16162E,
        ), // Solid color matching user side
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: FutureBuilder<Map<String, dynamic>>(
          future: _supabase
              .from('profiles')
              .select('username')
              .eq('id', widget.targetUserId)
              .single(),
          builder: (context, snapshot) {
            String displayName = snapshot.hasData
                ? (snapshot.data!['username'] ?? "Customer")
                : "Loading...";
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.cyanAccent.withOpacity(0.1),
                  child: const Icon(
                    LucideIcons.user,
                    color: Colors.cyanAccent,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            );
          },
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
          ),
        ),
        child: Column(
          children: [
            Expanded(child: _buildMessageList(businessId, targetUserId)),
            _buildInput(businessId, targetUserId),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList(String businessId, String targetUserId) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase
          .from('messages')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(
            child: CircularProgressIndicator(color: Colors.cyanAccent),
          );

        final messages = snapshot.data!.where((m) {
          final String mSenderId = m['sender_id'].toString();
          final String mReceiverId = m['receiver_id'].toString();
          return (mSenderId == businessId && mReceiverId == targetUserId) ||
              (mSenderId == targetUserId && mReceiverId == businessId);
        }).toList();

        return ListView.builder(
          controller: _scrollController,
          reverse: true,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final msg = messages[index];
            final bool isMe =
                msg['is_from_business'] == true; // Business is "Me" here

            final DateTime? createdAt = DateTime.tryParse(
              msg['created_at'] ?? "",
            );
            final String timeString = createdAt != null
                ? "${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}"
                : "";

            return Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: isMe
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      gradient: isMe
                          ? const LinearGradient(
                              colors: [Colors.cyanAccent, Colors.blueAccent],
                            )
                          : LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.1),
                                Colors.white.withOpacity(0.05),
                              ],
                            ),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: Radius.circular(isMe ? 20 : 5),
                        bottomRight: Radius.circular(isMe ? 5 : 20),
                      ),
                    ),
                    child: Text(
                      msg['content'] ?? "",
                      style: TextStyle(
                        fontSize: 15,
                        color: isMe ? const Color(0xFF0F0C29) : Colors.white,
                        fontWeight: isMe ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
                  child: Text(
                    timeString,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildInput(String bIdStr, String uIdStr) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      decoration: BoxDecoration(
        color: const Color(0xFF16162E),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Type a reply...",
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              onPressed: _sendReply,
              icon: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Colors.blueAccent, Colors.purpleAccent],
                  ),
                ),
                child: const Icon(
                  LucideIcons.send,
                  color: Color(0xFF0F0C29),
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
