import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AdminApprovalList extends StatefulWidget {
  final Map<String, dynamic> adminData;

  const AdminApprovalList({super.key, required this.adminData});

  @override
  State<AdminApprovalList> createState() => _AdminApprovalListState();
}

class _AdminApprovalListState extends State<AdminApprovalList> {
  // Variables
  List<dynamic> _pendingList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPending();
  }

  // Logic Methods
  // Opens the SSM document URL in external browser
  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Could not open SSM document"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // find business profiles with pending status
  Future<void> _fetchPending() async {
    try {
      final data = await Supabase.instance.client
          .from('business_profiles')
          .select()
          .eq('status', 'pending');
      setState(() {
        _pendingList = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Fetch error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // updates business status to approved or rejected
  Future<void> _processRequest(String id, String status) async {
    try {
      await Supabase.instance.client
          .from('business_profiles')
          .update({'status': status, 'approved_by': widget.adminData['id']})
          .eq('id', id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Business $status successfully"),
            backgroundColor: status == 'approved'
                ? Colors.greenAccent
                : Colors.redAccent,
          ),
        );
      }
      // refresh list
      _fetchPending();
    } catch (e) {
      debugPrint("Update error: $e");
    }
  }

  // UI
  @override
  Widget build(BuildContext context) {
    // show loading spin
    if (_isLoading)
      return const Center(
        child: CircularProgressIndicator(color: Colors.cyanAccent),
      );

    // show empty state if blank
    if (_pendingList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.checkCircle,
              size: 60,
              color: Colors.white.withOpacity(0.2),
            ),
            const SizedBox(height: 16),
            const Text(
              "No pending registrations",
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _pendingList.length,
      itemBuilder: (context, index) {
        final item = _pendingList[index];
        final ssmUrl = item['ssm_url'];

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.cyanAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            LucideIcons.store,
                            color: Colors.cyanAccent,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['business_name'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "SSM: ${item['register_no']}",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Glassmorphic SSM Action Chip
                    if (ssmUrl != null && ssmUrl.toString().isNotEmpty)
                      InkWell(
                        onTap: () => _launchURL(ssmUrl),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.cyanAccent.withOpacity(0.3),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.fileText,
                                size: 16,
                                color: Colors.cyanAccent,
                              ),
                              SizedBox(width: 8),
                              Text(
                                "View SSM Document",
                                style: TextStyle(
                                  color: Colors.cyanAccent,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Text(
                        "No document uploaded",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.3),
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Divider(color: Colors.white10, height: 1),
                    ),

                    Row(
                      children: [
                        // Reject Button
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _processRequest(
                              item['id'].toString(),
                              'rejected',
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: Colors.redAccent.withOpacity(0.5),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                            child: const Text(
                              "Reject",
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        // Approve Button with Gradient
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Colors.greenAccent, Colors.tealAccent],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.greenAccent.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: () => _processRequest(
                                item['id'].toString(),
                                'approved',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                "Approve",
                                style: TextStyle(
                                  color: Color(0xFF0F0C29),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
