import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart'; // Add this package to pubspec.yaml

class AdminApprovalList extends StatefulWidget {
  final Map<String, dynamic> adminData;
  const AdminApprovalList({super.key, required this.adminData});

  @override
  State<AdminApprovalList> createState() => _AdminApprovalListState();
}

class _AdminApprovalListState extends State<AdminApprovalList> {
  List<dynamic> _pendingList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPending();
  }

  // Function to open the SSM URL in a browser
  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open SSM document")),
        );
      }
    }
  }

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
    }
  }

  Future<void> _processRequest(String id, String status) async {
    try {
      await Supabase.instance.client.from('business_profiles').update({
        'status': status,
        'approved_by': widget.adminData['id'],
      }).eq('id', id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Business $status"), backgroundColor: Colors.green),
        );
      }
      _fetchPending();
    } catch (e) {
      debugPrint("Update error detail: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_pendingList.isEmpty) return const Center(child: Text("No pending registrations."));

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _pendingList.length,
      itemBuilder: (context, index) {
        final item = _pendingList[index];
        final ssmUrl = item['ssm_url']; // Assuming column name is 'ssm_url'

        return Card(
          margin: const EdgeInsets.only(bottom: 15),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item['business_name'],
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("SSM No: ${item['register_no']}"),
                      const SizedBox(height: 8),
                      // VIEW SSM BUTTON
                      if (ssmUrl != null && ssmUrl.toString().isNotEmpty)
                        ActionChip(
                          avatar: const Icon(Icons.description, size: 16),
                          label: const Text("View SSM Document"),
                          onPressed: () => _launchURL(ssmUrl),
                        )
                      else
                        const Text("No SSM document uploaded",
                            style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => _processRequest(item['id'].toString(), 'rejected'),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                      child: const Text("Reject", style: TextStyle(color: Colors.red)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () => _processRequest(item['id'].toString(), 'approved'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: const Text("Approve", style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}