import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AdminStatsPage extends StatefulWidget {
  const AdminStatsPage({super.key});

  @override
  State<AdminStatsPage> createState() => _AdminStatsPageState();
}

class _AdminStatsPageState extends State<AdminStatsPage> {
  List<Map<String, dynamic>> _userList = [];
  List<Map<String, dynamic>> _businessList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDetailedStats();
  }

  Future<void> _fetchDetailedStats() async {
    try {
      final users = await Supabase.instance.client.from('profiles').select();
      final businesses = await Supabase.instance.client.from('business_profiles').select();

      setState(() {
        _userList = List<Map<String, dynamic>>.from(users);
        _businessList = List<Map<String, dynamic>>.from(businesses);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching stats: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- NEW: Soft Delete / Deactivation Logic ---
  Future<void> _toggleBusinessStatus(String id, String name, String currentStatus) async {
    final bool isDeactivating = currentStatus != 'inactive';
    final String newStatus = isDeactivating ? 'inactive' : 'approved';

    bool confirm = await showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: const Color(0xFF1A1A35),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(isDeactivating ? "Deactivate Business?" : "Reactivate Business?",
              style: const TextStyle(color: Colors.white)),
          content: Text("Are you sure you want to make $name ${isDeactivating ? 'inactive' : 'active'}?",
              style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDeactivating ? Colors.redAccent : Colors.greenAccent,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: Text(isDeactivating ? "Deactivate" : "Activate",
                  style: const TextStyle(color: Color(0xFF1A1A35), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    ) ?? false;

    if (confirm) {
      try {
        await Supabase.instance.client
            .from('business_profiles')
            .update({'status': newStatus})
            .eq('id', id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("$name is now $newStatus"), backgroundColor: isDeactivating ? Colors.orange : Colors.green),
          );
          _fetchDetailedStats();
          Navigator.pop(context); // Close bottom sheet to refresh
        }
      } catch (e) {
        debugPrint("Status update error: $e");
      }
    }
  }

  void _showDetails(String title, List<Map<String, dynamic>> data, bool isUser) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A35).withOpacity(0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          padding: const EdgeInsets.all(25),
          child: Column(
            children: [
              Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 20),
              Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              const Divider(color: Colors.white10, height: 30),
              Expanded(
                child: ListView.builder(
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    final item = data[index];
                    final String status = item['status'] ?? 'approved';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isUser ? Colors.blueAccent.withOpacity(0.1) : Colors.purpleAccent.withOpacity(0.1),
                          child: Icon(isUser ? LucideIcons.user : LucideIcons.store,
                              size: 20, color: isUser ? Colors.lightBlueAccent : Colors.purpleAccent),
                        ),
                        title: Text(item[isUser ? 'username' : 'business_name'] ?? 'No Name',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['email'] ?? 'No Email', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                            if (!isUser) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: status == 'inactive' ? Colors.redAccent.withOpacity(0.2) : Colors.greenAccent.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(status.toUpperCase(),
                                    style: TextStyle(color: status == 'inactive' ? Colors.redAccent : Colors.greenAccent, fontSize: 9, fontWeight: FontWeight.bold)),
                              ),
                            ]
                          ],
                        ),
                        trailing: !isUser
                            ? IconButton(
                          icon: Icon(
                              status == 'inactive' ? LucideIcons.refreshCcw : LucideIcons.trash,
                              color: status == 'inactive' ? Colors.greenAccent : Colors.redAccent,
                              size: 20
                          ),
                          onPressed: () => _toggleBusinessStatus(item['id'].toString(), item['business_name'], status),
                        )
                            : null,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text("System Statistics", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
          : Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            Expanded(
              child: GridView.count(
                crossAxisCount: MediaQuery.of(context).size.width > 800 ? 2 : 1,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 1.4,
                children: [
                  _statCard("Total Users", _userList.length.toString(), LucideIcons.users, Colors.blueAccent,
                          () => _showDetails("User Directory", _userList, true)),
                  _statCard("Total Businesses", _businessList.length.toString(), LucideIcons.store, Colors.purpleAccent,
                          () => _showDetails("Business Directory", _businessList, false)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 40, color: color),
                const SizedBox(height: 10),
                Text(value, style: const TextStyle(fontSize: 38, fontWeight: FontWeight.bold, color: Colors.white)),
                Text(title, style: TextStyle(color: Colors.white.withOpacity(0.5), fontWeight: FontWeight.w500)),
                const SizedBox(height: 15),
                const Text("VIEW LIST", style: TextStyle(fontSize: 10, color: Colors.cyanAccent, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}