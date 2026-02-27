import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'chat_detail.dart';
import 'package:intl/intl.dart';

class UserInboxPage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const UserInboxPage({super.key, required this.userData});

  @override
  State<UserInboxPage> createState() => _UserInboxPageState();
}

class _UserInboxPageState extends State<UserInboxPage> {
  final _supabase = Supabase.instance.client;
  String _searchQuery = "";

  String _formatDateTime(String? dateStr) {
    if (dateStr == null) return "";
    final DateTime date = DateTime.parse(dateStr).toLocal();
    final now = DateTime.now();

    if (date.day == now.day && date.month == now.month && date.year == now.year) {
      return DateFormat.jm().format(date);
    } else if (now.difference(date).inDays < 7) {
      return DateFormat('E').format(date);
    } else {
      return DateFormat('MMM d').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Messages", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft, end: Alignment.centerRight,
            colors: [Colors.blue.shade100, Colors.purple.shade50],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: "Search businesses...",
                    prefixIcon: const Icon(LucideIcons.search, color: Colors.blueAccent, size: 20),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.9),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.blue.shade100),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(color: Colors.blueAccent),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _searchQuery.isEmpty ? _buildChatHistory() : _buildSearchResults(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatHistory() {
    final userId = widget.userData['id'];
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase.from('messages').stream(primaryKey: ['id']).order('created_at', ascending: false),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text("No conversations yet", style: TextStyle(color: Colors.blue.shade900)));
        }

        final allMessages = snapshot.data!;
        final businessIds = allMessages
            .map((m) => m['is_from_business'] ? m['sender_id'] : m['receiver_id'])
            .toSet().where((id) => id != userId).toList();

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: businessIds.length,
          itemBuilder: (context, index) => _buildBusinessTile(businessIds[index], allMessages),
        );
      },
    );
  }

  Widget _buildBusinessTile(dynamic bId, List<Map<String, dynamic>> allMessages) {
    final userId = widget.userData['id'];
    final conversation = allMessages.where((m) =>
    (m['sender_id'] == userId && m['receiver_id'] == bId) ||
        (m['sender_id'] == bId && m['receiver_id'] == userId)
    ).toList();

    if (conversation.isEmpty) return const SizedBox.shrink();
    final lastMsg = conversation.first;
    final bool hasUnread = lastMsg['receiver_id'] == userId && lastMsg['is_read'] == false;

    return FutureBuilder<Map<String, dynamic>>(
      future: _supabase.from('business_profiles').select().eq('id', bId).single(),
      builder: (context, bSnapshot) {
        if (!bSnapshot.hasData) return const SizedBox.shrink();
        final business = bSnapshot.data!;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Stack(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue.shade50,
                  child: const Icon(LucideIcons.store, color: Colors.blueAccent),
                ),
                if (hasUnread)
                  Positioned(
                    right: 0, top: 0,
                    child: Container(width: 12, height: 12, decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2))),
                  ),
              ],
            ),
            title: Text(business['business_name'] ?? "Business",
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
            subtitle: Text(lastMsg['content'] ?? "", maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_formatDateTime(lastMsg['created_at']),
                    style: TextStyle(fontSize: 11, color: hasUnread ? Colors.blueAccent : Colors.grey)),
                const SizedBox(height: 4),
                const Icon(LucideIcons.chevronRight, size: 14, color: Colors.grey),
              ],
            ),
            onTap: () async {
              await _supabase.from('messages').update({'is_read': true}).eq('receiver_id', userId).eq('sender_id', bId);
              if (mounted) {
                Navigator.push(context, MaterialPageRoute(builder: (context) => UserChatDetailPage(userData: widget.userData, businessData: business)));
              }
            },
          ),
        );
      },
    );
  }

  // Missing _buildSearchResults Logic
  Widget _buildSearchResults() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _supabase.from('business_profiles').select().ilike('business_name', '%$_searchQuery%'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text("No businesses found", style: TextStyle(color: Colors.blue.shade900)));
        }

        final results = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final business = results[index];
            return _buildBusinessTileFromData(business);
          },
        );
      },
    );
  }

  // Missing Helper to build a tile from search data
  Widget _buildBusinessTileFromData(Map<String, dynamic> business) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: Colors.white,
          child: const Icon(LucideIcons.plus, color: Colors.blueAccent, size: 20),
        ),
        title: Text(business['business_name'] ?? "Business", style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text("Start a new conversation", style: TextStyle(fontSize: 12)),
        trailing: const Icon(LucideIcons.chevronRight, size: 14, color: Colors.grey),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserChatDetailPage(
                userData: widget.userData,
                businessData: business,
              ),
            ),
          );
        },
      ),
    );
  }
}