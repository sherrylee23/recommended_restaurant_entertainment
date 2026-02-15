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
  final List<String> _allCategories = [
    'Restaurant', 'Cafe', 'Bar', 'Street Food', 'Cinema',
    'Karaoke', 'Theme Park', 'Shopping', 'Live Music', 'Gaming'
  ];

  List<String> _manualInterests = [];
  Map<String, int> _analysisData = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // 1. Load existing manual adjustments from the Array column
    _manualInterests = List<String>.from(widget.userData['interests'] ?? []);

    // 2. Load analysis data from the JSONB column
    final rawAnalysis = widget.userData['interest_analysis'] as Map<String, dynamic>? ?? {};
    _analysisData = rawAnalysis.map((key, value) => MapEntry(key, value as int));
  }

  Future<void> _savePreferences() async {
    setState(() => _isSaving = true);
    try {
      // Updates the manual interests column in Supabase
      await Supabase.instance.client
          .from('profiles')
          .update({'interests': _manualInterests})
          .eq('id', widget.userData['id']);

      if (mounted) {
        // Return the updated list to the Profile page to update local state
        Navigator.pop(context, _manualInterests);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Preferences updated successfully!")),
        );
      }
    } catch (e) {
      debugPrint("Error saving interests: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to save preferences"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sort analysis categories by highest view count for the UI
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
            "AI Personalization",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- SECTION 1: AI ANALYSIS ---
            _buildSectionHeader("AI Analysis", "Categories you view most often"),
            const SizedBox(height: 16),
            if (sortedAnalysis.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text(
                    "No browsing history yet. Start exploring to see your analysis!",
                    style: TextStyle(color: Colors.grey, fontSize: 14)
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade50, Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Column(
                  children: sortedAnalysis.take(3).map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.activity, size: 18, color: Colors.blueAccent),
                          const SizedBox(width: 12),
                          Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                                "${entry.value} views",
                                style: const TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.w600)
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

            const SizedBox(height: 40),

            // --- SECTION 2: MANUAL ADJUSTMENT ---
            _buildSectionHeader("Manual Adjustment", "Select categories you want to prioritize"),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _allCategories.map((cat) {
                final isSelected = _manualInterests.contains(cat);
                return FilterChip(
                  label: Text(cat),
                  selected: isSelected,
                  onSelected: (val) {
                    setState(() {
                      val ? _manualInterests.add(cat) : _manualInterests.remove(cat);
                    });
                  },
                  selectedColor: Colors.blueAccent.withOpacity(0.1),
                  checkmarkColor: Colors.blueAccent,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.blueAccent : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  backgroundColor: Colors.grey.shade50,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: isSelected ? Colors.blueAccent : Colors.grey.shade300),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 50),

            // --- SAVE BUTTON ---
            SizedBox(
              width: double.infinity,
              height: 55,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF8ECAFF), Color(0xFF4A90E2), Colors.purpleAccent]),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(color: Colors.blueAccent.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _savePreferences,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: _isSaving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("APPLY AI SETTINGS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
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
        const SizedBox(height: 4),
        Text(sub, style: const TextStyle(fontSize: 14, color: Colors.black45)),
      ],
    );
  }
}