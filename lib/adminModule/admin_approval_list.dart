import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      // Print admin ID to console to verify it exists
      debugPrint("Processing ID: $id with Admin: ${widget.adminData['id']}");

      await Supabase.instance.client.from('business_profiles').update({
        'status': status,
        'approved_by': widget.adminData['id'], // Requires the SQL column added in Step 1
      }).eq('id', id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Business $status"), backgroundColor: Colors.green),
        );
      }

      // Refresh list to remove the card
      _fetchPending();
    } catch (e) {
      // This will now show you the error if the column is still missing
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
        return Card(
          child: ListTile(
            title: Text(item['business_name']),
            subtitle: Text("SSM: ${item['register_no']}"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () => _processRequest(item['id'].toString(), 'approved'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text("Approve", style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => _processRequest(item['id'].toString(), 'rejected'),
                  child: const Text("Reject", style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}