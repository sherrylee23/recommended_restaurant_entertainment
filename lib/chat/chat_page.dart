import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart'; // REQUIRED
import 'chat_detail.dart';
import 'view_business_profile.dart';
import 'package:recommended_restaurant_entertainment/reportModule/system_message.dart';
import 'user_booking_history.dart';
import 'comment_notification.dart';
import '../language_provider.dart'; // REQUIRED

class UserInboxPage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const UserInboxPage({super.key, required this.userData});

  @override
  State<UserInboxPage> createState() => _UserInboxPageState();
}

class _UserInboxPageState extends State<UserInboxPage> {
  final _supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();
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
    final lp = Provider.of<LanguageProvider>(context); // Access Provider

    return Scaffold(
      backgroundColor: const Color(0xFF0F0C29),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF16162E),
        title: Text(lp.getString('messages_title'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
        child: Column(
          children: [
            _buildSearchBar(lp),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _handleRefresh,
                color: Colors.blueAccent,
                child: _searchQuery.isEmpty
                    ? CustomScrollView(
                  key: _refreshKey,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _buildSystemNotificationTile(lp),
                          const SizedBox(height: 12),
                          _buildCommentNotificationTile(lp),
                        ]),
                      ),
                    ),
                    SliverToBoxAdapter(child: _buildRecentHeader(lp)),
                    _buildChatHistorySliver(lp),
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                )
                    : _buildSearchResults(lp),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentHeader(LanguageProvider lp) {
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
          Text(lp.getString('recent_chats'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildChatHistorySliver(LanguageProvider lp) {
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

        if (businessIds.isEmpty) return SliverToBoxAdapter(child: Center(child: Padding(padding: const EdgeInsets.only(top: 50), child: Text(lp.getString('no_conv_yet'), style: const TextStyle(color: Colors.white38)))));

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

    final conversation = allMessages.where((m) =>
    (m['sender_id'] == userId && m['receiver_id'] == bId) ||
        (m['sender_id'] == bId && m['receiver_id'] == userId)
    ).toList();

    if (conversation.isEmpty) return const SizedBox.shrink();

    final lastMsg = conversation.first;

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
              clipBehavior: Clip.none,
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

  Widget _buildSearchBar(LanguageProvider lp) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: lp.getString('search_businesses'), // TRANSLATED
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
          prefixIcon: const Icon(LucideIcons.search, color: Colors.blueAccent, size: 20),
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

  Widget _buildCommentNotificationTile(LanguageProvider lp) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase.from('notifications').stream(primaryKey: ['id']).eq('user_id', widget.userData['id']),
      builder: (context, snapshot) {
        final hasUnread = snapshot.hasData && snapshot.data!.any((msg) => msg['is_read'] == false);
        return _buildNotificationTile(
            icon: LucideIcons.messageCircle,
            iconColor: Colors.orangeAccent,
            title: lp.getString('post_comments_title'), // TRANSLATED
            subtitle: lp.getString('post_comments_sub'), // TRANSLATED
            hasUnread: hasUnread,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CommentNotificationPage(userData: widget.userData))));
      },
    );
  }


  Widget _buildSystemNotificationTile(LanguageProvider lp) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase
          .from('system_messages')
          .stream(primaryKey: ['id'])
          .eq('user_id', widget.userData['id']),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const SizedBox.shrink();

        final bool hasUnread = snapshot.hasData &&
            snapshot.data!.any((msg) => msg['is_read'] == false);

        return _buildNotificationTile(
          icon: LucideIcons.bell,
          iconColor: Colors.redAccent,
          title: lp.getString('system_notif_title'), // TRANSLATED
          subtitle: lp.getString('system_notif_sub'), // TRANSLATED
          hasUnread: hasUnread,
          onTap: () async {
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
          bool isTodayActive = b['booking_date'] == today && b['status'] == 'confirmed';
          bool hasNewUpdate = b['user_viewed'] == false;
          return isTodayActive || hasNewUpdate;
        });

        return _bookingIcon(showDot);
      },
    );
  }

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

  Widget _buildSearchResults(LanguageProvider lp) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _supabase.from('business_profiles').select().ilike('business_name', '%$_searchQuery%'),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) return Center(child: Text(lp.getString('no_biz_found'), style: const TextStyle(color: Colors.white38)));
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