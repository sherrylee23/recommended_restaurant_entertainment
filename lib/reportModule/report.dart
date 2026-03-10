import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart'; // REQUIRED
import '../language_provider.dart'; // REQUIRED

class ReportPage extends StatefulWidget {
  final Map<String, dynamic> post;
  final dynamic viewerProfileId;

  const ReportPage({super.key, required this.post, required this.viewerProfileId});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final _detailsController = TextEditingController();
  String _selectedReasonKey = 'reason_inappropriate'; // Store the translation key
  bool _isLoading = false;

  // Store keys instead of hardcoded strings
  final List<String> _reasonKeys = [
    'reason_inappropriate',
    'reason_fake',
    'reason_spam',
    'reason_harassment',
    'reason_suspicious',
    'reason_other'
  ];

  // --- LOGIC PRESERVED ---
  Future<void> _submitReport(LanguageProvider lp) async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;

      await supabase.from('reports').insert({
        'post_id': widget.post['id'],
        'reporter_id': widget.viewerProfileId,
        'reason': lp.getString(_selectedReasonKey), // Store the translated reason at time of submission
        'details': _detailsController.text.trim(),
        'status': 'pending',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(lp.getString('report_success')), // TRANSLATED
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
    final lp = Provider.of<LanguageProvider>(context); // Access language provider

    return Scaffold(
      backgroundColor: const Color(0xFF0F0C29),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(lp.getString('submit_report'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                Text(lp.getString('report_question'), // TRANSLATED
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(lp.getString('report_desc'), // TRANSLATED
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
                      value: _selectedReasonKey,
                      icon: const Icon(LucideIcons.chevronDown, color: Colors.redAccent, size: 20),
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      items: _reasonKeys.map((key) => DropdownMenuItem(
                          value: key,
                          child: Text(lp.getString(key)) // SHOW TRANSLATED REASON
                      )).toList(),
                      onChanged: (val) => setState(() => _selectedReasonKey = val!),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // --- STYLED DETAILS FIELD ---
                Text(lp.getString('details'), // TRANSLATED
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                TextField(
                  controller: _detailsController,
                  maxLines: 4,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: lp.getString('details_hint'), // TRANSLATED
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

                // --- SUBMIT BUTTON ---
                InkWell(
                  onTap: _isLoading ? null : () => _submitReport(lp),
                  child: Container(
                    width: double.infinity,
                    height: 55,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: _isLoading
                            ? [Colors.grey, Colors.grey]
                            : [Colors.cyanAccent, Colors.blueAccent, Colors.purpleAccent],
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
                          : Text(lp.getString('submit_report').toUpperCase(), // TRANSLATED
                          style: const TextStyle(color: Color(0xFF0F0C29), fontWeight: FontWeight.bold, letterSpacing: 1.2)),
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