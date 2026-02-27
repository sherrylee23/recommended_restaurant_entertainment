import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';

class PersonalizedPage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const PersonalizedPage({super.key, required this.userData});

  @override
  State<PersonalizedPage> createState() => _PersonalizedPageState();
}

class _PersonalizedPageState extends State<PersonalizedPage> {
  Map<String, int> _analysisData = {};
  bool _isInitialLoading = true;

  @override
  void initState() {
    super.initState();
    // Fetch fresh data from Supabase to ensure the AI analysis is accurate
    _loadFreshAnalysis();
  }

  Future<void> _loadFreshAnalysis() async {
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('interest_analysis')
          .eq('id', widget.userData['id'])
          .single();

      if (mounted) {
        setState(() {
          final rawAnalysis = response['interest_analysis'] as Map<String, dynamic>? ?? {};
          // Map raw JSON data to a typed integer map
          _analysisData = rawAnalysis.map((key, value) => MapEntry(key, value as int));
          _isInitialLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading fresh analysis: $e");
      if (mounted) setState(() => _isInitialLoading = false);
    }
  }

  Widget _buildPercentageAnalysis(List<MapEntry<String, int>> sortedData) {
    // Filter out items with 0 views to show meaningful AI insights
    final activeData = sortedData.where((e) => e.value > 0).toList();
    final int totalViews = activeData.fold(0, (sum, entry) => sum + entry.value);

    if (totalViews == 0) {
      return Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Center(
          child: Text(
            "No browsing history found yet.\nKeep exploring to build your AI profile!",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.shade50),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: activeData.take(8).map((entry) {
          final double percentage = (entry.value / totalViews) * 100;
          return _buildInterestRow(entry.key, percentage);
        }).toList(),
      ),
    );
  }

  Widget _buildInterestRow(String label, double percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text(
                "${percentage.toStringAsFixed(1)}%",
                style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey.shade100,
              color: Colors.blueAccent,
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Sort the list so the most frequent interests appear at the top
    final sortedAnalysis = _analysisData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Personalization",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isInitialLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader("Interest Profile",
                "This analysis is automatically generated based on your real-time browsing behavior."),
            const SizedBox(height: 20),
            _buildPercentageAnalysis(sortedAnalysis),
            const SizedBox(height: 30),
            const Center(
              child: Text(
                "The more you interact, the more accurate your feed becomes.",
                style: TextStyle(color: Colors.black38, fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String sub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 6),
        Text(sub, style: const TextStyle(fontSize: 14, color: Colors.black45, height: 1.4)),
      ],
    );
  }
}