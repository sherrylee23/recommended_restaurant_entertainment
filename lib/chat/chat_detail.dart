import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:recommended_restaurant_entertainment/businessModule/booking_form.dart';
import 'view_business_profile.dart';
import '../language_provider.dart';

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
    final lp = Provider.of<LanguageProvider>(context);
    // declare to string
    final String userId = widget.userData['id'].toString();
    final String businessId = widget.businessData['id'].toString();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0C29),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF16162E),
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => UserViewBusinessPage(
                  userData: widget.userData,
                  businessData: widget.businessData,
                ),
              ),
            );
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.blueAccent.withOpacity(0.1),
                backgroundImage: (widget.businessData['profile_url'] != null &&
                    widget.businessData['profile_url'].toString().isNotEmpty)
                    ? NetworkImage(widget.businessData['profile_url'])
                    : null,
                child: (widget.businessData['profile_url'] == null ||
                    widget.businessData['profile_url'].toString().isEmpty)
                    ? const Icon(LucideIcons.store, color: Colors.blueAccent, size: 16)
                    : null,
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.businessData['business_name'] ?? "Chat",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    Text(
                      lp.getString('view_profile'),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blueAccent.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            child: ElevatedButton.icon(
              onPressed: _navigateToBooking,
              icon: const Icon(LucideIcons.calendarDays, size: 14, color: Colors.white),
              label: Text(
                lp.getString('book_btn'),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
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
            Expanded(child: _buildMessageList(userId, businessId, lp)),
            _buildInput(userId, businessId, lp),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList(String userId, String businessId, LanguageProvider lp) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase
          .from('messages')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text(lp.getString('error_loading_msgs'), style: const TextStyle(color: Colors.white)));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));

        final messages = snapshot.data!.where((m) {
          final String mSenderId = m['sender_id'].toString();
          final String mReceiverId = m['receiver_id'].toString();

          return (mSenderId == userId && mReceiverId == businessId) ||
              (mSenderId == businessId && mReceiverId == userId);
        }).toList();

        return ListView.builder(
          controller: _scrollController,
          reverse: true, // show the latest detail at bottom
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
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      gradient: isMe
                          ? const LinearGradient(colors: [Colors.blueAccent, Color(0xFF6A11CB)])
                          : LinearGradient(colors: [
                        Colors.white.withOpacity(0.1),
                        Colors.white.withOpacity(0.05),
                      ]),
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

  Widget _buildInput(String uIdStr, String bIdStr, LanguageProvider lp) {
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
                  hintText: lp.getString('type_message'),
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

                  // scroll down after sent
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      0.0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
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