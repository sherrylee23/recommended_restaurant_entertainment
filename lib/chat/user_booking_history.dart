import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class UserBookingHistoryPage extends StatelessWidget {
  final Map<String, dynamic> userData;
  const UserBookingHistoryPage({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final DateTime now = DateTime.now();
    final String today = DateFormat('yyyy-MM-dd').format(now);
    final String currentTimeString = DateFormat('HH:mm:ss').format(now);

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Bookings", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase
            .from('bookings')
            .stream(primaryKey: ['id'])
            .eq('user_id', userData['id'].toString())
            .order('booking_date', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final bookings = snapshot.data!;

          // --- LOGIC: Reminder Box Filter (Today + Future + Not Rejected) ---
          final upcomingToday = bookings.where((b) {
            bool isToday = b['booking_date'] == today;
            String bTime = b['booking_time'] ?? "00:00:00";
            if (bTime.length == 5) bTime += ":00";

            String status = (b['status'] ?? "").toLowerCase();
            bool isActive = status != "rejected" && status != "cancelled";

            return isToday && bTime.compareTo(currentTimeString) >= 0 && isActive;
          }).toList();

          if (bookings.isEmpty) return const Center(child: Text("No bookings yet."));

          return Column(
            children: [
              if (upcomingToday.isNotEmpty) _buildTodayReminder(upcomingToday),

              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    final b = bookings[index];
                    final String bookingTime = b['booking_time'] ?? "--:--:--";
                    final String status = (b['status'] ?? "").toLowerCase();

                    final bool isToday = b['booking_date'] == today;
                    String bTimeCompare = bookingTime.length == 5 ? "$bookingTime:00" : bookingTime;

                    final bool isPast = isToday && bTimeCompare.compareTo(currentTimeString) < 0;
                    final bool isInactive = status == "rejected" || status == "cancelled";

                    return FutureBuilder<Map<String, dynamic>>(
                      future: supabase
                          .from('business_profiles')
                          .select('*, locations!inner(area)')
                          .eq('id', b['business_id'])
                          .single(),
                      builder: (context, bizSnapshot) {
                        if (!bizSnapshot.hasData) return const SizedBox(height: 100);

                        final bizData = bizSnapshot.data!;
                        final area = bizData['locations']['area'];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                            side: isToday && !isPast && !isInactive
                                ? const BorderSide(color: Colors.orangeAccent, width: 2)
                                : BorderSide.none,
                          ),
                          child: Opacity(
                            opacity: (isPast || isInactive) ? 0.6 : 1.0,
                            child: ExpansionTile(
                              leading: Icon(
                                  Icons.event_available,
                                  color: (isToday && !isPast && !isInactive) ? Colors.orange : Colors.blue
                              ),
                              title: Text(bizData['business_name'] ?? "Unknown", style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                "${b['booking_date']} • $bookingTime • ${area ?? 'Nearby'}${isInactive ? ' ($status)' : ''}",
                                style: TextStyle(color: (isPast || isInactive) ? Colors.grey : Colors.black87),
                              ),
                              children: [
                                const Divider(),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      _buildInfoChip(Icons.access_time, bookingTime, Colors.blue),
                                      _buildInfoChip(Icons.people, "${b['pax']} Pax", Colors.purple),
                                      _buildInfoChip(
                                          status == "rejected" ? Icons.cancel : Icons.info_outline,
                                          b['status'] ?? "Pending",
                                          status == "rejected" ? Colors.red : Colors.orange
                                      ),
                                    ],
                                  ),
                                ),
                                _buildAreaSuggestions(bizData['id'], area),
                                const SizedBox(height: 15),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Row(children: [Icon(icon, size: 16, color: color), const SizedBox(width: 4), Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))]);
  }

  Widget _buildTodayReminder(List<Map<String, dynamic>> upcomingToday) {
    return Container(
      width: double.infinity, margin: const EdgeInsets.all(16), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.orange.shade400, Colors.orange.shade700]), borderRadius: BorderRadius.circular(12)),
      child: Row(children: [const Icon(Icons.notification_important, color: Colors.white, size: 28), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Upcoming Today!", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)), Text("Next at ${upcomingToday.first['booking_time']}. You have ${upcomingToday.length} active booking(s) left.", style: const TextStyle(color: Colors.white70, fontSize: 13))]))]),
    );
  }

  Widget _buildAreaSuggestions(dynamic currentBizId, String? area) {
    if (area == null) return const SizedBox.shrink();
    final supabase = Supabase.instance.client;
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: supabase.from('business_profiles').select('*, locations!inner(*)').eq('locations.area', area).neq('id', currentBizId).limit(5),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final suggestions = snapshot.data!;
        return SizedBox(
          height: 80,
          child: ListView.builder(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: suggestions.length, itemBuilder: (context, index) {
            final item = suggestions[index];
            return Container(width: 160, margin: const EdgeInsets.only(right: 12), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(item['business_name'] ?? "", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1), Text(item['business_type'] ?? "", style: TextStyle(fontSize: 11, color: Colors.blue.shade700))]));
          }),
        );
      },
    );
  }
}