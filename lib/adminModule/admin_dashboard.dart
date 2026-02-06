import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  List<dynamic> pendingBusinesses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPending();
  }

  Future<void> _fetchPending() async {
    final data = await Supabase.instance.client
        .from('business_profiles')
        .select()
        .eq('is_approved', false);
    setState(() { pendingBusinesses = data; _isLoading = false; });
  }

  Future<void> _approveBusiness(String id) async {
    await Supabase.instance.client
        .from('business_profiles')
        .update({'is_approved': true})
        .eq('id', id);
    _fetchPending();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Business Approved")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pending Approvals")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: pendingBusinesses.length,
        itemBuilder: (context, index) {
          final b = pendingBusinesses[index];
          return ListTile(
            title: Text(b['name']),
            subtitle: Text("Reg No: ${b['reg_no']}"),
            trailing: ElevatedButton(
              onPressed: () => _approveBusiness(b['id'].toString()),
              child: const Text("Approve"),
            ),
          );
        },
      ),
    );
  }
}