import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AdminStatsPage extends StatefulWidget {
  const AdminStatsPage({super.key});

  @override
  State<AdminStatsPage> createState() => _AdminStatsPageState();
}

class _AdminStatsPageState extends State<AdminStatsPage> {
  int userCount = 0;
  int businessCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getStats();
  }

  Future<void> _getStats() async {
    final users = await Supabase.instance.client.from('profiles').select('id');
    final businesses = await Supabase.instance.client.from('business_profiles').select('id');
    setState(() {
      userCount = users.length;
      businessCount = businesses.length;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(30),
        child: GridView.count(
          crossAxisCount: isDesktop ? 2 : 1,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          children: [
            _statCard("Total Users", userCount.toString(), LucideIcons.users, Colors.blue),
            _statCard("Total Businesses", businessCount.toString(), LucideIcons.store, Colors.purple),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 50, color: color),
          Text(value, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
          Text(title),
        ],
      ),
    );
  }
}