import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../language_provider.dart';

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
          _analysisData = rawAnalysis.map((key, value) => MapEntry(key, value as int));
          _isInitialLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading fresh analysis: $e");
      if (mounted) setState(() => _isInitialLoading = false);
    }
  }

  Widget _buildPercentageAnalysis(List<MapEntry<String, int>> sortedData, LanguageProvider lp) {
    final activeData = sortedData.where((e) => e.value > 0).toList();
    final int totalViews = activeData.fold(0, (sum, entry) => sum + entry.value);

    if (totalViews == 0) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(LucideIcons.barChart2, color: Colors.white.withOpacity(0.2), size: 40),
              const SizedBox(height: 16),
              Text(
                lp.getString('no_history_yet'), // TRANSLATED
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white38, fontSize: 13, height: 1.5),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Column(
            children: activeData.take(8).map((entry) {
              final double percentage = (entry.value / totalViews) * 100;
              return _buildInterestRow(entry.key, percentage);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildInterestRow(String label, double percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
              Text(
                "${percentage.toStringAsFixed(1)}%",
                style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 800),
                height: 8,
                width: (MediaQuery.of(context).size.width - 98) * (percentage / 100),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Colors.cyanAccent, Colors.blueAccent]),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(color: Colors.cyanAccent.withOpacity(0.3), blurRadius: 6, spreadRadius: 1),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lp = Provider.of<LanguageProvider>(context); // Access Provider
    final sortedAnalysis = _analysisData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      backgroundColor: const Color(0xFF0F0C29),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          lp.getString('personalized'), // TRANSLATED TITLE
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
          ),
        ),
        child: _isInitialLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
            : SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(
                  lp.getString('interest_profile'), // TRANSLATED
                  lp.getString('interest_desc'),    // TRANSLATED
                ),
                const SizedBox(height: 30),
                _buildPercentageAnalysis(sortedAnalysis, lp),
                const SizedBox(height: 40),
                Center(
                  child: Text(
                    lp.getString('accuracy_tip'), // TRANSLATED
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String sub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.cyanAccent,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: Colors.cyanAccent.withOpacity(0.5), blurRadius: 8)],
              ),
            ),
            const SizedBox(width: 12),
            Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
        const SizedBox(height: 12),
        Text(sub, style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.5), height: 1.5)),
      ],
    );
  }
}