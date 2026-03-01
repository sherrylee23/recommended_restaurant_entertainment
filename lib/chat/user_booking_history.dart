import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class UserBookingHistoryPage extends StatelessWidget {
  final Map<String, dynamic> userData;
  const UserBookingHistoryPage({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

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
          final todayBookings = bookings.where((b) => b['booking_date'] == today).toList();

          if (bookings.isEmpty) return const Center(child: Text("No bookings yet."));

          return Column(
            children: [
              if (todayBookings.isNotEmpty) _buildTodayReminder(todayBookings),

              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    final b = bookings[index];
                    final String bookingTime = b['booking_time'] ?? "--:--";

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
                            side: b['booking_date'] == today
                                ? const BorderSide(color: Colors.orangeAccent, width: 2)
                                : BorderSide.none,
                          ),
                          child: ExpansionTile(
                            leading: Icon(
                                Icons.event_available,
                                color: b['booking_date'] == today ? Colors.orange : Colors.blue
                            ),
                            title: Text(bizData['business_name'] ?? "Unknown",
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text("${b['booking_date']} • $bookingTime • ${area ?? 'Nearby'}"),
                            children: [
                              const Divider(),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildInfoChip(Icons.access_time, bookingTime, Colors.blue),
                                    _buildInfoChip(Icons.people, "${b['pax']} Pax", Colors.purple),
                                    _buildInfoChip(Icons.info_outline, b['status'] ?? "Pending", Colors.orange),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Row(
                                  children: [
                                    const Icon(Icons.explore, size: 16, color: Colors.blueAccent),
                                    const SizedBox(width: 8),
                                    Text("Also in $area:",
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  ],
                                ),
                              ),
                              _buildAreaSuggestions(bizData['id'], area),
                              const SizedBox(height: 15),
                            ],
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
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildTodayReminder(List<Map<String, dynamic>> todayBookings) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.orange.shade400, Colors.orange.shade700]),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          const Icon(Icons.notification_important, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Upcoming Today!",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  "Next at ${todayBookings.first['booking_time']}. You have ${todayBookings.length} booking(s) total.",
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAreaSuggestions(dynamic currentBizId, String? area) {
    if (area == null) return const SizedBox.shrink();
    final supabase = Supabase.instance.client;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: supabase
          .from('business_profiles')
          .select('*, locations!inner(*)')
          .eq('locations.area', area)
          .neq('id', currentBizId)
          .limit(5),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: LinearProgressIndicator());
        }
        final suggestions = snapshot.data ?? [];
        if (suggestions.isEmpty) return const SizedBox.shrink();

        return SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: suggestions.length,
            itemBuilder: (context, index) {
              final item = suggestions[index];
              return Container(
                width: 160,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(item['business_name'] ?? "Shop",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(item['business_type'] ?? "Entertainment",
                        style: TextStyle(fontSize: 11, color: Colors.blue.shade700)),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}