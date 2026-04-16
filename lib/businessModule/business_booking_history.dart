import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

class BusinessBookingHistory extends StatefulWidget {
  final dynamic businessId;
  const BusinessBookingHistory({super.key, required this.businessId});

  @override
  State<BusinessBookingHistory> createState() => _BusinessBookingHistoryState();
}

class _BusinessBookingHistoryState extends State<BusinessBookingHistory> {
  // client and state
  final _supabase = Supabase.instance.client;
  String _selectedStatus = 'all';
  DateTimeRange? _selectedDateRange;

  // update the booking status
  Future<void> _updateStatus(dynamic bookingId, String status) async {
    try {
      await _supabase.from('bookings').update({'status': status}).eq('id', bookingId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  // open the date picker to filter
  Future<void> _pickDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: Colors.cyanAccent, onPrimary: Color(0xFF0F0C29), surface: Color(0xFF1B1838)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDateRange = picked);
  }

  // UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0C29),
      // Set to false to prevent the body from sliding under the status bar manually
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
          // background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
                ),
              ),
            ),
          ),

          // real-time content layer
          SafeArea(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _supabase
                  .from('bookings')
                  .stream(primaryKey: ['id'])
                  .eq('business_id', widget.businessId)
                  .order('booking_date', ascending: false),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text("Error", style: TextStyle(color: Colors.white)));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));

                final allBookings = snapshot.data!;
                final filteredBookings = allBookings.where((b) {
                  final bool statusMatch = _selectedStatus == 'all' || b['status'] == _selectedStatus;
                  bool dateMatch = true;
                  if (_selectedDateRange != null) {
                    final DateTime bookingDate = DateTime.parse(b['booking_date']);
                    dateMatch = bookingDate.isAfter(_selectedDateRange!.start.subtract(const Duration(days: 1))) &&
                        bookingDate.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
                  }
                  return statusMatch && dateMatch;
                }).toList();

                return Column(
                  children: [
                    // This creates a small buffer after the AppBar
                    const SizedBox(height: 10),
                    _buildSummaryHeader(allBookings.length, allBookings.where((b) => b['status'] == 'pending').length),
                    _buildFiltersSection(),
                    Expanded(
                      child: filteredBookings.isEmpty
                          ? const Center(child: Text("No bookings found", style: TextStyle(color: Colors.white54)))
                          : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                        itemCount: filteredBookings.length,
                        itemBuilder: (context, index) => _buildBookingCard(filteredBookings[index]),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }


  // displays quick stats at the top
  Widget _buildSummaryHeader(int total, int pending) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildStatItem("Total Bookings", total.toString(), Colors.blueAccent),
          const SizedBox(width: 12),
          _buildStatItem("Pending", pending.toString(), Colors.orangeAccent),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 10, color: color.withOpacity(0.8))),
          ],
        ),
      ),
    );
  }

  // interactive section for date and status filter
  Widget _buildFiltersSection() {
    final filters = ['all', 'pending', 'confirmed', 'cancelled'];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: InkWell(
            onTap: _pickDateRange,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.calendar, size: 16, color: Colors.cyanAccent),
                  const SizedBox(width: 8),
                  Text(
                    _selectedDateRange == null
                        ? "Filter by Date"
                        : "${DateFormat('MMM d').format(_selectedDateRange!.start)} - ${DateFormat('MMM d').format(_selectedDateRange!.end)}",
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const Spacer(),
                  if (_selectedDateRange != null)
                    GestureDetector(
                      onTap: () => setState(() => _selectedDateRange = null),
                      child: const Icon(LucideIcons.x, size: 14, color: Colors.redAccent),
                    ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filters.length,
            itemBuilder: (context, index) {
              final status = filters[index];
              final isSelected = _selectedStatus == status;
              return GestureDetector(
                onTap: () => setState(() => _selectedStatus = status),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.cyanAccent.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isSelected ? Colors.cyanAccent : Colors.white.withOpacity(0.1)),
                  ),
                  child: Center(child: Text(status.toUpperCase(), style: TextStyle(color: isSelected ? Colors.cyanAccent : Colors.white70, fontSize: 10, fontWeight: FontWeight.bold))),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // build a card with action button
  Widget _buildBookingCard(Map<String, dynamic> b) {
    final String status = b['status'] ?? 'pending';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: ExpansionTile(
        title: Text(b['customer_name'] ?? "Unknown", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        subtitle: Text("${b['booking_date']} • ${b['booking_time']}", style: TextStyle(color: Colors.white54, fontSize: 12)),
        trailing: _buildStatusBadge(status),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _infoRow(LucideIcons.users, "Pax: ${b['pax']}"),
                _infoRow(LucideIcons.phone, "Contact: ${b['phone_number'] ?? 'N/A'}"),
                if (status == 'pending')
                  Padding(
                    padding: const EdgeInsets.only(top: 15),
                    child: Row(
                      children: [
                        Expanded(child: TextButton(onPressed: () => _updateStatus(b['id'], 'cancelled'), child: const Text("Reject", style: TextStyle(color: Colors.redAccent)))),
                        Expanded(child: ElevatedButton(onPressed: () => _updateStatus(b['id'], 'confirmed'), style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent), child: const Text("Confirm", style: TextStyle(color: Color(0xFF0F0C29))))),
                      ],
                    ),
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
      child: Row(children: [Icon(icon, size: 14, color: Colors.cyanAccent), const SizedBox(width: 10), Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13))]),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = status == 'confirmed' ? Colors.greenAccent : (status == 'cancelled' ? Colors.redAccent : Colors.orangeAccent);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(0.5))),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }
}