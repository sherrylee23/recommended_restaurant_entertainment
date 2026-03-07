import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'chat_detail.dart';
import 'view_business_profile.dart';
import 'package:recommended_restaurant_entertainment/reportModule/system_message.dart';
import 'user_booking_history.dart';
import 'comment_notification.dart';

class UserInboxPage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const UserInboxPage({super.key, required this.userData});

  @override
  State<UserInboxPage> createState() => _UserInboxPageState();
}

class _UserInboxPageState extends State<UserInboxPage> {
  final _supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController(); // Added for clearing
  String _searchQuery = "";
  Key _refreshKey = UniqueKey();

  Future<void> _handleRefresh() async {
    setState(() {
      _refreshKey = UniqueKey();
    });
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Widget _buildAvatar(String? imageUrl, {double radius = 20, double iconSize = 20}) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.blueAccent.withOpacity(0.1),
      backgroundImage: (imageUrl != null && imageUrl.isNotEmpty)
          ? NetworkImage(imageUrl)
          : null,
      child: (imageUrl == null || imageUrl.isEmpty)
          ? Icon(LucideIcons.store, color: Colors.blueAccent, size: iconSize)
          : null,
    );
  }

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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0C29),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF16162E),
        title: const Text("Messages", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        actions: [
          _buildBookingAction(),
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
        // MOVE SEARCH BAR HERE so it stays constant regardless of search state
        child: Column(
          children: [
            _buildSearchBar(), // The Search Bar is now ALWAYS here
            Expanded(
              child: RefreshIndicator(
                onRefresh: _handleRefresh,
                color: Colors.blueAccent,
                child: _searchQuery.isEmpty
                    ? CustomScrollView(
                  key: _refreshKey,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // REMOVE _buildSearchBar() from here
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _buildSystemNotificationTile(),
                          const SizedBox(height: 12),
                          _buildCommentNotificationTile(),
                        ]),
                      ),
                    ),
                    SliverToBoxAdapter(child: _buildRecentHeader()),
                    _buildChatHistorySliver(),
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                )
                    : _buildSearchResults(), // Display results here
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 30, bottom: 15, left: 25),
      child: Row(
        children: [
          Container(
            width: 4, height: 18,
            decoration: BoxDecoration(
              color: Colors.blueAccent,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: Colors.blueAccent.withOpacity(0.5), blurRadius: 8)],
            ),
          ),
          const SizedBox(width: 12),
          const Text("Recent Conversations", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildChatHistorySliver() {
    final userId = widget.userData['id'];

    return StreamBuilder<List<Map<String, dynamic>>>(
      key: ValueKey('chat_stream_${_refreshKey.toString()}'),
      stream: _supabase.from('messages').stream(primaryKey: ['id']).order('created_at', ascending: false),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const SliverToBoxAdapter(child: Center(child: Text("Error loading chats", style: TextStyle(color: Colors.white24))));
        if (!snapshot.hasData) return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.only(top: 20), child: CircularProgressIndicator(color: Colors.blueAccent))));

        final messages = snapshot.data!;
        final businessIds = messages
            .map((m) => m['is_from_business'] ? m['sender_id'] : m['receiver_id'])
            .toSet()
            .where((id) => id != userId)
            .toList();

        if (businessIds.isEmpty) return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.only(top: 50), child: Text("No conversations yet", style: TextStyle(color: Colors.white38)))));

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                if (index >= businessIds.length) return null;
                return _buildBusinessTile(businessIds[index], messages);
              },
              childCount: businessIds.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildBusinessTile(dynamic bId, List<Map<String, dynamic>> allMessages) {
    final userId = widget.userData['id'];

    // 1. Get the conversation messages
    final conversation = allMessages.where((m) =>
    (m['sender_id'] == userId && m['receiver_id'] == bId) ||
        (m['sender_id'] == bId && m['receiver_id'] == userId)
    ).toList();

    if (conversation.isEmpty) return const SizedBox.shrink();

    final lastMsg = conversation.first;

    // 2. Count ONLY messages sent FROM the business TO the user that are UNREAD
    final int unreadCount = conversation.where((m) =>
    m['sender_id'] == bId &&
        m['receiver_id'] == userId &&
        m['is_read'] == false
    ).length;

    final bool hasUnread = unreadCount > 0;

    return FutureBuilder<Map<String, dynamic>>(
      future: _supabase.from('business_profiles').select().eq('id', bId).single(),
      builder: (context, bSnapshot) {
        if (!bSnapshot.hasData) return const SizedBox.shrink();
        final business = bSnapshot.data!;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(hasUnread ? 0.08 : 0.03),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
                color: hasUnread ? Colors.blueAccent.withOpacity(0.3) : Colors.white.withOpacity(0.05)
            ),
          ),
          child: ListTile(
            leading: Stack(
              clipBehavior: Clip.none, // Allows the badge to sit slightly outside the avatar
              children: [
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => UserViewBusinessPage(userData: widget.userData, businessData: business)
                  )),
                  child: _buildAvatar(business['profile_url']),
                ),
                if (hasUnread)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF16162E), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.redAccent.withOpacity(0.4),
                            blurRadius: 6,
                            spreadRadius: 1,
                          )
                        ],
                      ),
                      child: Center(
                        child: Text(
                          unreadCount > 9 ? "9+" : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            title: Text(
                business['business_name'] ?? "Business",
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)
            ),
            subtitle: Text(
                lastMsg['content'] ?? "",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: hasUnread ? Colors.white : Colors.white38,
                  fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                )
            ),
            trailing: Text(
                _formatDateTime(lastMsg['created_at']),
                style: TextStyle(fontSize: 10, color: hasUnread ? Colors.blueAccent : Colors.white24)
            ),
            onTap: () async {
              // Mark ALL messages from this business as read
              await _supabase.from('messages')
                  .update({'is_read': true})
                  .eq('receiver_id', userId)
                  .eq('sender_id', bId);

              if (mounted) {
                Navigator.push(context, MaterialPageRoute(
                    builder: (context) => UserChatDetailPage(userData: widget.userData, businessData: business)
                ));
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: TextField(
        controller: _searchController, // Controller added
        onChanged: (value) => setState(() => _searchQuery = value),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: "Search businesses...",
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
          prefixIcon: const Icon(LucideIcons.search, color: Colors.blueAccent, size: 20),
          // FIXED: Added Clear Button
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
            icon: const Icon(LucideIcons.x, color: Colors.white38, size: 18),
            onPressed: () {
              _searchController.clear();
              setState(() => _searchQuery = "");
            },
          )
              : null,
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildNotificationTile({required IconData icon, required Color iconColor, required String title, required String subtitle, required VoidCallback onTap, required bool hasUnread}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.1))),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(backgroundColor: iconColor.withOpacity(0.2), child: Icon(icon, color: iconColor, size: 20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5))),
        trailing: hasUnread ? Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle)) : const Icon(LucideIcons.chevronRight, size: 16, color: Colors.white24),
      ),
    );
  }

  Widget _buildCommentNotificationTile() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase.from('notifications').stream(primaryKey: ['id']).eq('user_id', widget.userData['id']),
      builder: (context, snapshot) {
        final hasUnread = snapshot.hasData && snapshot.data!.any((msg) => msg['is_read'] == false);
        return _buildNotificationTile(icon: LucideIcons.messageCircle, iconColor: Colors.orangeAccent, title: "Post Comments", subtitle: "See who commented on your posts", hasUnread: hasUnread, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CommentNotificationPage(userData: widget.userData))));
      },
    );
  }


  Widget _buildSystemNotificationTile() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase
          .from('system_messages')
          .stream(primaryKey: ['id'])
          .eq('user_id', widget.userData['id']),
      builder: (context, snapshot) {
        // 1. Handle Error
        if (snapshot.hasError) return const SizedBox.shrink();

        // 2. Logic for unread status
        // We check if data exists and if any message has is_read == false
        final bool hasUnread = snapshot.hasData &&
            snapshot.data!.any((msg) => msg['is_read'] == false);

        // 3. Always return the tile (don't return a ProgressIndicator here)
        // This prevents the tile from flickering or disappearing when a new message arrives
        return _buildNotificationTile(
          icon: LucideIcons.bell,
          iconColor: Colors.redAccent,
          title: "System Notifications",
          subtitle: "Updates on reports",
          hasUnread: hasUnread, // This will reactively update
          onTap: () async {
            // Update database
            await _supabase
                .from('system_messages')
                .update({'is_read': true})
                .eq('user_id', widget.userData['id'])
                .eq('is_read', false);

            if (context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SystemMessagePage(userData: widget.userData),
                ),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildBookingAction() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase
          .from('bookings')
          .stream(primaryKey: ['id'])
          .eq('user_id', widget.userData['id'].toString()),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return _bookingIcon(false);

        final now = DateTime.now();
        final today = DateFormat('yyyy-MM-dd').format(now);

        bool showDot = snapshot.data!.any((b) {
          // 1. Reminder: Active booking happening TODAY
          bool isTodayActive = b['booking_date'] == today && b['status'] == 'confirmed';

          // 2. Notification: Business changed status and user hasn't opened history yet
          bool hasNewUpdate = b['user_viewed'] == false;

          return isTodayActive || hasNewUpdate;
        });

        return _bookingIcon(showDot);
      },
    );
  }

// Helper to keep UI clean
  Widget _bookingIcon(bool showDot) {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(LucideIcons.calendarClock, color: Colors.white),
          onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => UserBookingHistoryPage(userData: widget.userData))
          ),
        ),
        if (showDot)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              width: 8, height: 8,
              decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
            ),
          ),
      ],
    );
  }

  Widget _buildSearchResults() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _supabase.from('business_profiles').select().ilike('business_name', '%$_searchQuery%'),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("No businesses found", style: TextStyle(color: Colors.white38)));
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final business = snapshot.data![index];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserViewBusinessPage(userData: widget.userData, businessData: business))),
                  // NEW: Display image in search results
                  child: _buildAvatar(business['profile_url'], radius: 18, iconSize: 16),
                ),
                title: Text(business['business_name'] ?? "", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                trailing: const Icon(LucideIcons.chevronRight, color: Colors.white24, size: 18),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => UserChatDetailPage(userData: widget.userData, businessData: business))),
              ),
            );
          },
        );
      },
    );
  }
}