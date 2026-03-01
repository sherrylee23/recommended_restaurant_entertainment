import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:recommended_restaurant_entertainment/searchModule/search_result.dart';

class SearchEntryPage extends StatefulWidget {
  final Map<String, dynamic> currentUserData;

  const SearchEntryPage({super.key, required this.currentUserData});

  @override
  State<SearchEntryPage> createState() => _SearchEntryPageState();
}

class _SearchEntryPageState extends State<SearchEntryPage> {
  final TextEditingController _controller = TextEditingController();

  // State variables for categories
  List<String> _dynamicCategories = [];
  bool _isLoadingCategories = true;

  // State variables for AI Top Ranking Module
  List<Map<String, dynamic>> _topRankedShops = [];
  bool _isLoadingRankings = true;

  @override
  void initState() {
    super.initState();
    _fetchCategoriesFromSupabase();
    _fetchTopRankings();
  }

  // --- DATA FETCHING LOGIC ---

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

  // --- MODIFIED SEARCH SUBMISSION LOGIC ---

  Future<void> _submitSearch(String query) async {
    final String trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return;

    // AI logic (increment_interest_counts) has been removed from here.
    // Searching is now a neutral action that does not affect the user profile.

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

  // --- UI BUILDER ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: "Search location, title, or category...",
            border: InputBorder.none,
            suffixIcon: IconButton(
              icon: const Icon(LucideIcons.search, color: Colors.black, size: 25),
              onPressed: () => _submitSearch(_controller.text),
            ),
          ),
          onSubmitted: _submitSearch,
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(LucideIcons.trophy, color: Colors.orange, size: 20),
                SizedBox(width: 8),
                Text("Top Rated Locations",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),
            if (_isLoadingRankings)
              const Center(child: CircularProgressIndicator())
            else
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _topRankedShops.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final shop = _topRankedShops[index];
                    return ListTile(
                      leading: Text("${index + 1}",
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent, fontSize: 16)),
                      title: Text(
                        shop['location_name'] ?? 'Unknown Location',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            shop['avg_rating'].toStringAsFixed(1),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                      onTap: () => _submitSearch(shop['location_name']),
                    );
                  },
                ),
              ),

            const SizedBox(height: 30),

            const Text("Quick Categories",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            if (_isLoadingCategories)
              const Center(child: CircularProgressIndicator())
            else if (_dynamicCategories.isEmpty)
              const Text("No categories found in database.",
                  style: TextStyle(color: Colors.grey))
            else
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _dynamicCategories.map((cat) {
                  return ActionChip(
                    label: Text(cat),
                    backgroundColor: Colors.blue.shade50,
                    side: BorderSide.none,
                    onPressed: () => _submitSearch(cat),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}