import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:recommended_restaurant_entertainment/businessModule/booking_form.dart';

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

  void _navigateToBooking() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingFormPage(
          businessId: widget.businessData['id'],
          userId: widget.userData['id'],
          businessName: widget.businessData['business_name'] ?? "Business",
        ),
      ),
    );
  }

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
      // 1. CHANGED: Removed extendBodyBehindAppBar to prevent content disappearing
      backgroundColor: const Color(0xFF0F0C29),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF16162E), // Solid dark color for stability
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.businessData['business_name'] ?? "Chat",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            child: ElevatedButton.icon(
              onPressed: _navigateToBooking,
              icon: const Icon(LucideIcons.calendarDays, size: 14, color: Colors.white),
              label: const Text("BOOK", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent.withOpacity(0.3),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: const BorderSide(color: Colors.blueAccent),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(width: 8),
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
        child: Column(
          children: [
            // 2. Wrap StreamBuilder in Expanded
            Expanded(child: _buildMessageList(userId, businessId)),
            _buildInput(userId, businessId),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList(String userId, String businessId) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase.from('messages').stream(primaryKey: ['id']).order('created_at', ascending: false),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Error loading messages", style: TextStyle(color: Colors.white)));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));

        final messages = snapshot.data!.where((m) {
          final String mSenderId = m['sender_id'].toString();
          final String mReceiverId = m['receiver_id'].toString();
          return (mSenderId == userId && mReceiverId == businessId) ||
              (mSenderId == businessId && mReceiverId == userId);
        }).toList();

        return ListView.builder(
          controller: _scrollController,
          reverse: true, // Newest messages at the bottom
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      gradient: isMe
                          ? const LinearGradient(colors: [Colors.blueAccent, Color(0xFF6A11CB)])
                          : LinearGradient(colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)]),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: Radius.circular(isMe ? 20 : 5),
                        bottomRight: Radius.circular(isMe ? 5 : 20),
                      ),
                    ),
                    child: Text(
                      msg['content'] ?? "",
                      style: const TextStyle(fontSize: 15, color: Colors.white),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
                  child: Text(timeString, style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.3))),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildInput(String uIdStr, String bIdStr) {
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
                  hintText: "Type a message...",
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
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
                  debugPrint("Send Error: $e");
                }
              },
              icon: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [Colors.blueAccent, Colors.purpleAccent]),
                ),
                child: const Icon(LucideIcons.send, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}