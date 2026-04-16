import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:recommended_restaurant_entertainment/searchModule/search_result.dart';
import '../language_provider.dart';

class SearchEntryPage extends StatefulWidget {
  final Map<String, dynamic> currentUserData;

  const SearchEntryPage({super.key, required this.currentUserData});

  @override
  State<SearchEntryPage> createState() => _SearchEntryPageState();
}

class _SearchEntryPageState extends State<SearchEntryPage> {
  final TextEditingController _controller = TextEditingController();

  List<String> _dynamicCategories = [];
  bool _isLoadingCategories = true;

  List<Map<String, dynamic>> _topRankedShops = [];
  bool _isLoadingRankings = true;

  @override
  void initState() {
    super.initState();
    _fetchCategoriesFromSupabase();
    _fetchTopRankings();
  }


  Future<void> _fetchCategoriesFromSupabase() async {
    try {
      final supabase = Supabase.instance.client;
      final data = await supabase.from('posts').select('category_names');

      String toTitleCase(String text) => text.isEmpty
          ? text
          : text[0].toUpperCase() + text.substring(1).toLowerCase();

      final Set<String> uniqueCategories = {};
      for (var row in data) {
        final List? categories = row['category_names'] as List?;
        if (categories != null) {
          for (var cat in categories) {
            uniqueCategories.add(toTitleCase(cat.toString().trim()));
          }
        }
      }

      if (mounted) {
        setState(() {
          _dynamicCategories = uniqueCategories.toList()..sort();
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching categories: $e");
      if (mounted) setState(() => _isLoadingCategories = false);
    }
  }

  Future<void> _fetchTopRankings() async {
    try {
      final supabase = Supabase.instance.client;
      final data = await supabase.from('posts').select('location_name, rating');
      final List<Map<String, dynamic>> fetchedPosts = List<Map<String, dynamic>>.from(data);

      Map<String, List<double>> locationGroups = {};
      for (var post in fetchedPosts) {
        String loc = post['location_name'] ?? 'Unknown Location';
        double rate = (post['rating'] ?? 0).toDouble();
        locationGroups.putIfAbsent(loc, () => []).add(rate);
      }

      List<Map<String, dynamic>> rankedLocations = locationGroups.entries.map((entry) {
        double avg = entry.value.reduce((a, b) => a + b) / entry.value.length;
        return {
          'location_name': entry.key,
          'avg_rating': avg,
        };
      }).toList();

      rankedLocations.sort((a, b) => b['avg_rating'].compareTo(a['avg_rating']));

      if (mounted) {
        setState(() {
          _topRankedShops = rankedLocations.take(5).toList();
          _isLoadingRankings = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching rankings: $e");
      if (mounted) setState(() => _isLoadingRankings = false);
    }
  }

  Future<void> _submitSearch(String query) async {
    final String trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return;

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SearchResultsPage(
            query: trimmedQuery,
            currentUserData: widget.currentUserData,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Access language provider
    final lp = Provider.of<LanguageProvider>(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
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
        child: Column(
          children: [
            // --- GLASS SEARCH BAR ---
            _buildGlassAppBar(context, lp),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section: Top Rated
                    _buildSectionHeader(LucideIcons.trophy, lp.getString('top_rated_loc'), Colors.orangeAccent),
                    const SizedBox(height: 12),
                    _isLoadingRankings
                        ? const Center(child: CircularProgressIndicator(color: Colors.white24))
                        : _buildRankedList(),

                    const SizedBox(height: 35),

                    // Section: Quick Categories
                    _buildSectionHeader(LucideIcons.layoutGrid, lp.getString('quick_categories'), Colors.blueAccent),
                    const SizedBox(height: 12),
                    _isLoadingCategories
                        ? const Center(child: CircularProgressIndicator(color: Colors.white24))
                        : _buildCategoryWrap(lp),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassAppBar(BuildContext context, LanguageProvider lp) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, bottom: 15, left: 10, right: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Container(
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: lp.getString('search_hint'), // TRANSLATED HINT
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                      suffixIcon: IconButton(
                        icon: const Icon(LucideIcons.search, color: Colors.blueAccent, size: 20),
                        onPressed: () => _submitSearch(_controller.text),
                      ),
                    ),
                    onSubmitted: _submitSearch,
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title, Color iconColor) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white, letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildRankedList() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _topRankedShops.length,
            separatorBuilder: (context, index) => Divider(height: 1, color: Colors.white.withOpacity(0.05)),
            itemBuilder: (context, index) {
              final shop = _topRankedShops[index];
              return ListTile(
                leading: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: index == 0 ? Colors.orangeAccent.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text("${index + 1}",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: index == 0 ? Colors.orangeAccent : Colors.white70,
                            fontSize: 14)),
                  ),
                ),
                title: Text(
                  shop['location_name'] ?? 'Unknown Location',
                  style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.white, fontSize: 15),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      shop['avg_rating'].toStringAsFixed(1),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                    ),
                  ],
                ),
                onTap: () => _submitSearch(shop['location_name']),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryWrap(LanguageProvider lp) {
    if (_dynamicCategories.isEmpty) {
      return Text(lp.getString('no_categories'), style: const TextStyle(color: Colors.white38));
    }
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _dynamicCategories.map((cat) {
        return GestureDetector(
          onTap: () => _submitSearch(cat),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.15)),
                ),
                child: Text(
                  cat,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}