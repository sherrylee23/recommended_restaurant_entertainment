import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

class BookingFormPage extends StatefulWidget {
  final dynamic businessId;
  final dynamic userId;
  final String businessName;

  const BookingFormPage({
    super.key,
    required this.businessId,
    required this.userId,
    required this.businessName,
  });

  @override
  State<BookingFormPage> createState() => _BookingFormPageState();
}

class _BookingFormPageState extends State<BookingFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _paxController = TextEditingController();
  final _noteController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  // --- LOGIC PRESERVED ---
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) => _buildDateTimePickerTheme(child!),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 19, minute: 0),
      builder: (context, child) => _buildDateTimePickerTheme(child!),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select both date and time"), backgroundColor: Colors.orange),
      );
      return;
    }

    try {
      await Supabase.instance.client.from('bookings').insert({
        'business_id': widget.businessId,
        'user_id': widget.userId.toString(),
        'customer_name': _nameController.text,
        'phone_number': _phoneController.text,
        'pax': int.parse(_paxController.text),
        'booking_date': _selectedDate!.toIso8601String().split('T')[0],
        'booking_time': "${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}",
        'notes': _noteController.text,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Booking Request Sent!"), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0C29),
      appBar: AppBar(
        title: Text(widget.businessName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F0C29), Color(0xFF302B63)],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Reserve your spot",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.5)),
                Text("Fill in the details to request a booking.",
                    style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.5))),
                const SizedBox(height: 30),

                _buildGlassField(
                  controller: _nameController,
                  label: "Full Name",
                  icon: LucideIcons.user,
                  validator: (v) => v!.isEmpty ? "Required" : null,
                ),
                const SizedBox(height: 15),

                _buildGlassField(
                  controller: _phoneController,
                  label: "Phone Number",
                  icon: LucideIcons.phone,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 15),

                _buildGlassField(
                  controller: _paxController,
                  label: "Number of Pax",
                  icon: LucideIcons.users,
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty ? "Required" : null,
                ),
                const SizedBox(height: 25),

                // --- DATE & TIME SELECTION ---
                Row(
                  children: [
                    Expanded(child: _buildPickerTile(
                      label: _selectedDate == null ? "Select Date" : DateFormat('MMM d, yyyy').format(_selectedDate!),
                      icon: LucideIcons.calendar,
                      onTap: _pickDate,
                      isSelected: _selectedDate != null,
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _buildPickerTile(
                      label: _selectedTime == null ? "Select Time" : _selectedTime!.format(context),
                      icon: LucideIcons.clock,
                      onTap: _pickTime,
                      isSelected: _selectedTime != null,
                    )),
                  ],
                ),

                const SizedBox(height: 40),

                // --- NEON SUBMIT BUTTON ---
                InkWell(
                  onTap: _submitBooking,
                  child: Container(
                    width: double.infinity,
                    height: 55,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(colors: [Colors.cyanAccent, Colors.blueAccent, Colors.purpleAccent]),
                      boxShadow: [
                        BoxShadow(color: Colors.cyanAccent.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))
                      ],
                    ),
                    child: const Center(
                      child: Text("CONFIRM REQUEST",
                          style: TextStyle(color: Color(0xFF0F0C29), fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        prefixIcon: Icon(icon, color: Colors.cyanAccent, size: 20),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.cyanAccent),
        ),
        errorStyle: const TextStyle(color: Colors.redAccent),
      ),
    );
  }

  Widget _buildPickerTile({required String label, required IconData icon, required VoidCallback onTap, required bool isSelected}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.cyanAccent.withOpacity(0.1) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isSelected ? Colors.cyanAccent.withOpacity(0.5) : Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.cyanAccent : Colors.white38, size: 24),
            const SizedBox(height: 8),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(color: isSelected ? Colors.white : Colors.white38, fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  // Forces the native pickers to match the dark theme
  Widget _buildDateTimePickerTheme(Widget child) {
    return Theme(
      data: ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(
          primary: Colors.cyanAccent,
          onPrimary: Color(0xFF0F0C29),
          surface: Color(0xFF1A1A35),
          onSurface: Colors.white,
        ),
        dialogBackgroundColor: const Color(0xFF0F0C29),
      ),
      child: child,
    );
  }
}