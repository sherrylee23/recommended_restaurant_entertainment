import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserBookingHistoryPage extends StatelessWidget {
  final Map<String, dynamic> userData;
  const UserBookingHistoryPage({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

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
          if (bookings.isEmpty) return const Center(child: Text("No bookings yet."));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final b = bookings[index];

              return FutureBuilder<Map<String, dynamic>>(
                // Fetch the business AND its location details (specifically 'area')
                future: supabase
                    .from('business_profiles')
                    .select('*, locations!inner(area)')
                    .eq('id', b['business_id'])
                    .single(),
                builder: (context, bizSnapshot) {
                  if (!bizSnapshot.hasData) return const SizedBox(height: 100);

                  final bizData = bizSnapshot.data!;
                  final area = bizData['locations']['area']; // e.g., "Kuala Lumpur"

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: ExpansionTile(
                      leading: const Icon(Icons.event_available, color: Colors.blue),
                      title: Text(bizData['business_name'] ?? "Unknown",
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("${b['booking_date']} • ${area ?? 'Nearby'}"),
                      children: [
                        const Divider(),
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
          );
        },
      ),
    );
  }

  Widget _buildAreaSuggestions(dynamic currentBizId, String? area) {
    if (area == null) return const SizedBox.shrink();

    final supabase = Supabase.instance.client;

    return FutureBuilder<List<Map<String, dynamic>>>(
      // We search for business_profiles where the linked location's area matches
      future: supabase
          .from('business_profiles')
          .select('*, locations!inner(*)')
          .eq('locations.area', area)
          .neq('id', currentBizId) // Don't suggest the place they just booked
          .limit(5),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: LinearProgressIndicator());
        }

        final suggestions = snapshot.data ?? [];
        if (suggestions.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text("No other spots found in this area."),
          );
        }

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
                    Text(
                      item['business_name'] ?? "Shop",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['business_type'] ?? "Entertainment",
                      style: TextStyle(fontSize: 11, color: Colors.blue.shade700),
                    ),
                    const Spacer(),

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