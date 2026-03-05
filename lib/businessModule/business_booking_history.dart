import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';

class BusinessBookingHistory extends StatefulWidget {
  final dynamic businessId;
  const BusinessBookingHistory({super.key, required this.businessId});

  @override
  State<BusinessBookingHistory> createState() => _BusinessBookingHistoryState();
}

class _BusinessBookingHistoryState extends State<BusinessBookingHistory> {
  final _supabase = Supabase.instance.client;

  // --- LOGIC PRESERVED ---
  Future<void> _updateStatus(dynamic bookingId, String status) async {
    try {
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
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0C29),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Booking History",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // 1. FIXED BACKGROUND WALLPAPER
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
              ),
            ),
          ),

          // 2. CONTENT
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _supabase
                .from('bookings')
                .stream(primaryKey: ['id'])
                .eq('business_id', widget.businessId)
                .order('booking_date', ascending: false),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.white)));
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));

              final bookings = snapshot.data!;
              final int pendingCount = bookings.where((b) => b['status'] == 'pending').length;

              return Column(
                children: [
                  SizedBox(height: MediaQuery.of(context).padding.top + 60),
                  _buildSummaryHeader(bookings.length, pendingCount),
                  Expanded(
                    child: bookings.isEmpty
                        ? const Center(child: Text("No bookings yet", style: TextStyle(color: Colors.white54)))
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
        ],
      ),
    );
  }

  Widget _buildSummaryHeader(int total, int pending) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _buildStatItem("Total Bookings", total.toString(), Colors.blueAccent),
          const SizedBox(width: 15),
          _buildStatItem("Pending Review", pending.toString(), Colors.orangeAccent),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
                const SizedBox(height: 4),
                Text(label, style: TextStyle(fontSize: 11, color: color.withOpacity(0.8), fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> b) {
    final String status = b['status'] ?? 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: Colors.white70,
          collapsedIconColor: Colors.white70,
          title: Text(b['customer_name'] ?? "Unknown",
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          subtitle: Text("${b['booking_date']} • ${b['booking_time']}",
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
          trailing: _buildStatusBadge(status),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(color: Colors.white.withOpacity(0.1)),
                  const SizedBox(height: 10),
                  _infoRow(LucideIcons.users, "Pax: ${b['pax']}"),
                  _infoRow(LucideIcons.phone, "Contact: ${b['phone_number'] ?? 'N/A'}"),
                  if (b['notes'] != null && b['notes'].isNotEmpty)
                    _infoRow(LucideIcons.fileText, "Notes: ${b['notes']}"),
                  const SizedBox(height: 20),
                  if (status == 'pending')
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => _updateStatus(b['id'], 'cancelled'),
                            child: const Text("Reject", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Colors.cyanAccent, Colors.blueAccent]),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ElevatedButton(
                              onPressed: () => _updateStatus(b['id'], 'confirmed'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text("Confirm", style: TextStyle(color: Color(0xFF0F0C29), fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.cyanAccent.withOpacity(0.7)),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = status == 'confirmed' ? Colors.greenAccent : (status == 'cancelled' ? Colors.redAccent : Colors.orangeAccent);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(status.toUpperCase(),
          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
    );
  }
}