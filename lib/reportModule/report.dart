import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ReportPage extends StatefulWidget {
  final Map<String, dynamic> post;
  final dynamic viewerProfileId;

  const ReportPage({super.key, required this.post, required this.viewerProfileId});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final _detailsController = TextEditingController();
  String _selectedReason = 'Inappropriate Content';
  bool _isLoading = false;

  final List<String> _reasons = [
    'Inappropriate Content',
    'Fake Review / Misleading',
    'Spam',
    'Harassment',
    'Suspicious Behavior',
    'Other'
  ];

  // --- LOGIC PRESERVED ---
  Future<void> _submitReport() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;

      await supabase.from('reports').insert({
        'post_id': widget.post['id'],
        'reporter_id': widget.viewerProfileId,
        'reason': _selectedReason,
        'details': _detailsController.text.trim(),
        'status': 'pending',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Report submitted. Admin will review this shortly."),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Submission failed: $e"), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0C29),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Submit Report", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F0C29), Color(0xFF24243E)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Why are you reporting this post?",
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text("Your report will be reviewed by our moderation team.",
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),
                const SizedBox(height: 30),

                // --- STYLED DROPDOWN ---
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      dropdownColor: const Color(0xFF1A1A35),
                      value: _selectedReason,
                      icon: const Icon(LucideIcons.chevronDown, color: Colors.redAccent, size: 20),
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      items: _reasons.map((r) => DropdownMenuItem(
                          value: r,
                          child: Text(r)
                      )).toList(),
                      onChanged: (val) => setState(() => _selectedReason = val!),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // --- STYLED DETAILS FIELD ---
                const Text("Details",
                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                TextField(
                  controller: _detailsController,
                  maxLines: 4,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Tell us more about the issue (optional)...",
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                    ),
                  ),
                ),

                const Spacer(),

                // --- NEON RED SUBMIT BUTTON ---
                // --- NEON CYAN/BLUE SUBMIT BUTTON ---
                InkWell(
                  onTap: _isLoading ? null : _submitReport,
                  child: Container(
                    width: double.infinity,
                    height: 55,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: _isLoading
                            ? [Colors.grey, Colors.grey]
                            : [Colors.cyanAccent, Colors.blueAccent, Colors.purpleAccent], // Back to your brand colors
                      ),
                      boxShadow: [
                        if (!_isLoading) BoxShadow(
                          color: Colors.cyanAccent.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Center(
                      child: _isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Color(0xFF0F0C29), strokeWidth: 2))
                          : const Text("SUBMIT REPORT",
                          style: TextStyle(color: Color(0xFF0F0C29), fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}