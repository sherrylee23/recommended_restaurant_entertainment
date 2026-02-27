import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  Future<void> _submitReport() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;

      // Inserting into a 'reports' table for the Admin Submodule
      await supabase.from('reports').insert({
        'post_id': widget.post['id'],
        'reporter_id': widget.viewerProfileId,
        'reason': _selectedReason,
        'details': _detailsController.text.trim(),
        'status': 'pending', // Default status for Admin review
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Report submitted. Admin will review this shortly.")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Submission failed: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Submit Report")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Why are you reporting this post?", style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButton<String>(
              isExpanded: true,
              value: _selectedReason,
              items: _reasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
              onChanged: (val) => setState(() => _selectedReason = val!),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _detailsController,
              decoration: const InputDecoration(labelText: "Details", hintText: "Optional details..."),
              maxLines: 3,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitReport,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                child: _isLoading ? const CircularProgressIndicator() : const Text("SUBMIT"),
              ),
            )
          ],
        ),
      ),
    );
  }
}