import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BusinessBookingHistory extends StatefulWidget {
  final dynamic businessId;
  const BusinessBookingHistory({super.key, required this.businessId});

  @override
  State<BusinessBookingHistory> createState() => _BusinessBookingHistoryState();
}

class _BusinessBookingHistoryState extends State<BusinessBookingHistory> {
  final _supabase = Supabase.instance.client;

  Future<void> _updateStatus(dynamic bookingId, String status) async {
    try {
      // Ensure the ID is being passed in the format Supabase expects.
      // Use .select() at the end to verify the update happened.
      final response = await _supabase
          .from('bookings')
          .update({'status': status})
          .eq('id', bookingId)
          .select();

      if (response.isEmpty) {
        debugPrint("Update failed: No booking found with ID $bookingId");
      } else {
        debugPrint("Booking $bookingId updated to $status");
      }
    } catch (e) {
      debugPrint("Error updating status: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Booking History", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _supabase
            .from('bookings')
            .stream(primaryKey: ['id'])
            .eq('business_id', widget.businessId)
            .order('booking_date', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final bookings = snapshot.data!;
          final int pendingCount = bookings.where((b) => b['status'] == 'pending').length;

          return Column(
            children: [
              _buildSummaryHeader(bookings.length, pendingCount),
              Expanded(
                child: bookings.isEmpty
                    ? const Center(child: Text("No bookings yet"))
                    : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: bookings.length,
                  itemBuilder: (context, index) => _buildBookingCard(bookings[index]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryHeader(int total, int pending) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Row(
        children: [
          _buildStatItem("Total", total.toString(), Colors.blue),
          const SizedBox(width: 20),
          _buildStatItem("Pending", pending.toString(), Colors.orange),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 12, color: color.withOpacity(0.8))),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> b) {
    final String status = b['status'] ?? 'pending';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(b['customer_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("${b['booking_date']} at ${b['booking_time']}"),
        trailing: _buildStatusBadge(status),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                _infoRow(Icons.people, "Pax: ${b['pax']}"),
                _infoRow(Icons.phone, "Contact: ${b['phone_number'] ?? 'N/A'}"),
                if (b['notes'] != null && b['notes'].isNotEmpty)
                  _infoRow(Icons.note, "Notes: ${b['notes']}"),
                const SizedBox(height: 15),
                if (status == 'pending')
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => _updateStatus(b['id'], 'cancelled'),
                          child: const Text("Reject", style: TextStyle(color: Colors.red)),
                        ),
                      ),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _updateStatus(b['id'], 'confirmed'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          child: const Text("Confirm"),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 10),
          Text(text),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = status == 'confirmed' ? Colors.green : (status == 'cancelled' ? Colors.red : Colors.orange);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}