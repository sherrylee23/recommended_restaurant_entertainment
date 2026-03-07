import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for Clipboard
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminStatsPage extends StatefulWidget {
  const AdminStatsPage({super.key});

  @override
  State<AdminStatsPage> createState() => _AdminStatsPageState();
}

class _AdminStatsPageState extends State<AdminStatsPage> {
  List<Map<String, dynamic>> _userList = [];
  List<Map<String, dynamic>> _businessList = [];
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDetailedStats();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- FILTER LOGIC ---
  List<Map<String, dynamic>> get _filteredBusinesses {
    if (_searchQuery.isEmpty) return _businessList;
    return _businessList.where((b) {
      final name = (b['business_name'] ?? "").toLowerCase();
      final ssm = (b['register_no'] ?? "").toLowerCase();
      return name.contains(_searchQuery.toLowerCase()) || ssm.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  List<Map<String, dynamic>> get _filteredUsers {
    if (_searchQuery.isEmpty) return _userList;
    return _userList.where((u) {
      final name = (u['username'] ?? "").toLowerCase();
      final email = (u['email'] ?? "").toLowerCase();
      return name.contains(_searchQuery.toLowerCase()) || email.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Future<void> _fetchDetailedStats() async {
    try {
      final users = await Supabase.instance.client.from('profiles').select();
      final businesses = await Supabase.instance.client
          .from('business_profiles')
          .select()
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _userList = List<Map<String, dynamic>>.from(users);
          _businessList = List<Map<String, dynamic>>.from(businesses);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- ACTIONS ---
  Future<void> _toggleBusinessStatus(String id, String name, String currentStatus) async {
    final bool isDeactivating = currentStatus == 'approved';
    final String newStatus = isDeactivating ? 'inactive' : 'approved';

    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A35),
        title: Text(isDeactivating ? "Deactivate Business?" : "Reactivate Business?", style: const TextStyle(color: Colors.white)),
        content: Text("Change $name to ${newStatus.toUpperCase()}?", style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: isDeactivating ? Colors.redAccent : Colors.greenAccent),
            onPressed: () => Navigator.pop(context, true),
            child: Text("Confirm", style: const TextStyle(color: Color(0xFF1A1A35), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      await Supabase.instance.client.from('business_profiles').update({'status': newStatus}).eq('id', id);
      _fetchDetailedStats();
      if (mounted) Navigator.pop(context);
    }
  }

  void _showDetails(String title, List<Map<String, dynamic>> data, bool isUser) {
    _searchQuery = "";
    _searchController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final currentList = isUser ? _filteredUsers : _filteredBusinesses;

          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A35).withOpacity(0.95),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              padding: const EdgeInsets.all(25),
              child: Column(
                children: [
                  Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10))),
                  const SizedBox(height: 20),
                  Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 15),

                  // Unified Search Bar
                  TextField(
                    controller: _searchController,
                    onChanged: (value) => setModalState(() => _searchQuery = value),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: isUser ? "Search username or email..." : "Search name or registration no...",
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                      prefixIcon: const Icon(LucideIcons.search, color: Colors.cyanAccent, size: 20),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                    ),
                  ),

                  const Divider(color: Colors.white10, height: 30),

                  Expanded(
                    child: currentList.isEmpty
                        ? Center(child: Text("No matches found", style: TextStyle(color: Colors.white.withOpacity(0.3))))
                        : ListView.builder(
                      itemCount: currentList.length,
                      itemBuilder: (context, index) {
                        final item = currentList[index];
                        final String status = item['status'] ?? 'pending';
                        Color accentColor = isUser ? Colors.lightBlueAccent :
                        (status == 'approved' ? Colors.greenAccent : (status == 'rejected' ? Colors.redAccent : Colors.orangeAccent));

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(15)),
                          child: ExpansionTile(
                            leading: CircleAvatar(
                              backgroundColor: accentColor.withOpacity(0.1),
                              child: Icon(isUser ? LucideIcons.user : LucideIcons.store, size: 20, color: accentColor),
                            ),
                            title: Text(item[isUser ? 'username' : 'business_name'] ?? 'No Name',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                            subtitle: Text(isUser ? (item['email'] ?? '') : status.toUpperCase(),
                                style: TextStyle(color: isUser ? Colors.white38 : accentColor, fontSize: 10, fontWeight: FontWeight.bold)),
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                                child: Column(
                                  children: [
                                    const Divider(color: Colors.white10),
                                    _detailRow("Email", item['email'] ?? 'N/A'),
                                    if (!isUser) ...[
                                      _detailRow("Reg No", item['register_no'] ?? 'Not Provided'),
                                      _detailRow("Joined", _formatDate(item['created_at'])),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(backgroundColor: Colors.white10),
                                              onPressed: () => _viewSSMDocument(item['ssm_url']),
                                              icon: const Icon(LucideIcons.fileText, size: 16, color: Colors.cyanAccent),
                                              label: const Text("SSM", style: TextStyle(color: Colors.white)),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          IconButton(
                                            onPressed: () => _toggleBusinessStatus(item['id'].toString(), item['business_name'], status),
                                            icon: Icon(status == 'approved' ? LucideIcons.trash : LucideIcons.checkCircle, color: status == 'approved' ? Colors.redAccent : Colors.greenAccent),
                                          )
                                        ],
                                      )
                                    ] else ...[
                                      _detailRow("Joined", _formatDate(item['created_at'])),
                                      const SizedBox(height: 10),
                                      TextButton.icon(
                                        onPressed: () {
                                          Clipboard.setData(ClipboardData(text: item['id'].toString()));
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User ID copied")));
                                        },
                                        icon: const Icon(LucideIcons.copy, size: 14),
                                        label: const Text("Copy User ID"),
                                      )
                                    ],
                                  ],
                                ),
                              )
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
          Flexible(child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 12), textAlign: TextAlign.end)),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return "N/A";
    final date = DateTime.parse(dateStr);
    return "${date.day}/${date.month}/${date.year}";
  }

  Future<void> _viewSSMDocument(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text("System Statistics", style: TextStyle(color: Colors.white)), backgroundColor: Colors.transparent, elevation: 0),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
          : Padding(
        padding: const EdgeInsets.all(25),
        child: GridView.count(
          crossAxisCount: MediaQuery.of(context).size.width > 800 ? 2 : 1,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          childAspectRatio: 1.4,
          children: [
            _statCard("Total Users", _userList.length.toString(), LucideIcons.users, Colors.blueAccent, () => _showDetails("User Directory", _userList, true)),
            _statCard("Total Businesses", _businessList.length.toString(), LucideIcons.store, Colors.purpleAccent, () => _showDetails("Business History", _businessList, false)),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.white.withOpacity(0.1))),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 10),
            Text(value, style: const TextStyle(fontSize: 38, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(title, style: TextStyle(color: Colors.white.withOpacity(0.5))),
          ],
        ),
      ),
    );
  }
}