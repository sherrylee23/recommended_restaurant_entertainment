import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'view_business_profile.dart';
import '../language_provider.dart';

class UserBookingHistoryPage extends StatelessWidget {
  final Map<String, dynamic> userData;
  const UserBookingHistoryPage({super.key, required this.userData});

  Future<void> _markAsViewed(SupabaseClient supabase) async {
    try {
      await supabase
          .from('bookings')
          .update({'user_viewed': true})
          .eq('user_id', userData['id'].toString())
          .eq('user_viewed', false);
    } catch (e) {
      debugPrint("Error updating viewed status: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final lp = Provider.of<LanguageProvider>(context); // Access Provider
    final supabase = Supabase.instance.client;
    final DateTime now = DateTime.now();
    final String today = DateFormat('yyyy-MM-dd').format(now);
    final String currentTimeString = DateFormat('HH:mm:ss').format(now);

    _markAsViewed(supabase);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF0F0C29),
      appBar: AppBar(
        title: Text(lp.getString('booking_history'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
          ),
        ),
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: supabase
              .from('bookings')
              .stream(primaryKey: ['id'])
              .eq('user_id', userData['id'].toString())
              .order('booking_date', ascending: false),
          builder: (context, snapshot) {
            if (snapshot.hasError) return _buildStatusText("Error: ${snapshot.error}");
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));

            final bookings = snapshot.data!;
            if (bookings.isEmpty) return _buildStatusText(lp.getString('no_bookings'));

            // filter today booking
            final upcomingToday = bookings.where((b) {
              bool isToday = b['booking_date'] == today;
              String bTime = b['booking_time'] ?? "00:00:00";
              if (bTime.length == 5) bTime += ":00";
              String status = (b['status'] ?? "").toLowerCase();
              return isToday && bTime.compareTo(currentTimeString) >= 0 && status != "rejected" && status != "cancelled";
            }).toList();

            return SafeArea(
              child: Column(
                children: [
                  if (upcomingToday.isNotEmpty) _buildTodayReminder(upcomingToday, lp),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: bookings.length,
                      itemBuilder: (context, index) {
                        final b = bookings[index];
                        return _buildBookingCard(context, b, today, currentTimeString, supabase, lp);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBookingCard(BuildContext context, Map<String, dynamic> b, String today, String currentTime, SupabaseClient supabase, LanguageProvider lp) {
    final String bookingTime = b['booking_time'] ?? "--:--";
    final String status = (b['status'] ?? "").toLowerCase();
    final bool isToday = b['booking_date'] == today;
    String bTimeCompare = bookingTime.length == 5 ? "$bookingTime:00" : bookingTime;

    final bool isPast = isToday && bTimeCompare.compareTo(currentTime) < 0;
    final bool isInactive = status == "rejected" || status == "cancelled";
    final bool isHighlyActive = isToday && !isPast && !isInactive;

    return FutureBuilder<Map<String, dynamic>>(
      future: supabase.from('business_profiles').select('*, locations!inner(area)').eq('id', b['business_id']).single(),
      builder: (context, bizSnapshot) {
        if (!bizSnapshot.hasData) return const SizedBox(height: 100);

        final bizData = bizSnapshot.data!;
        final area = bizData['locations']['area'];

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Opacity(
            opacity: (isPast || isInactive) ? 0.4 : 1.0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(isHighlyActive ? 0.1 : 0.03),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isHighlyActive ? Colors.orangeAccent.withOpacity(0.5) : Colors.white.withOpacity(0.1),
                      width: isHighlyActive ? 2 : 1,
                    ),
                  ),
                  child: ExpansionTile(
                    iconColor: Colors.white,
                    collapsedIconColor: Colors.white38,
                    tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isHighlyActive ? Colors.orangeAccent.withOpacity(0.2) : Colors.blueAccent.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isHighlyActive ? LucideIcons.zap : LucideIcons.calendar,
                        color: isHighlyActive ? Colors.orangeAccent : Colors.blueAccent,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      bizData['business_name'] ?? "Unknown",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "${b['booking_date']} • $bookingTime • ${area ?? 'Nearby'}",
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                    ),
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Divider(color: Colors.white10),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildInfoChip(LucideIcons.clock, bookingTime, Colors.blueAccent),
                                _buildInfoChip(LucideIcons.users, "${b['pax']} ${lp.getString('pax')}", Colors.purpleAccent),
                                _buildInfoChip(
                                  isInactive ? LucideIcons.xCircle : LucideIcons.checkCircle,
                                  status.toUpperCase(),
                                  isInactive ? Colors.redAccent : Colors.greenAccent,
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildAreaSuggestions(bizData['id'], area, supabase, lp),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTodayReminder(List<Map<String, dynamic>> upcomingToday, LanguageProvider lp) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFF512F), Color(0xFFDD2476)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: const Color(0xFFDD2476).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.partyPopper, color: Colors.white, size: 30),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lp.getString('upcoming_today'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 2),
                Text(
                  lp.getString('next_at').replaceFirst('{}', upcomingToday.first['booking_time']),
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAreaSuggestions(dynamic currentBizId, String? area, SupabaseClient supabase, LanguageProvider lp) {
    if (area == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(lp.getString('also_in').replaceFirst('{}', area.toUpperCase()), style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: supabase.from('business_profiles').select('*, locations!inner(*)').eq('locations.area', area).neq('id', currentBizId).limit(5),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();
            final suggestions = snapshot.data!;
            if (suggestions.isEmpty) return const SizedBox.shrink();

            return SizedBox(
              height: 75,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: suggestions.length,
                itemBuilder: (context, index) {
                  final item = suggestions[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserViewBusinessPage(
                            businessData: item,
                            userData: userData,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: 160,
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                    item['business_name'] ?? "",
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis
                                ),
                              ),
                              const Icon(LucideIcons.chevronRight, color: Colors.cyanAccent, size: 14),
                            ],
                          ),
                          Text(
                              lp.getString(item['business_type']?.toString().toLowerCase() ?? 'place'),
                              style: const TextStyle(fontSize: 10, color: Colors.cyanAccent)
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildStatusText(String text) {
    return Center(child: Text(text, style: const TextStyle(color: Colors.white38)));
  }
}