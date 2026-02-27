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
    _fetchTopRankings(); // Load AI location rankings on startup
  }

  // --- DATA FETCHING LOGIC ---

  // Fetches unique categories used in the 'posts' table
  Future<void> _fetchCategoriesFromSupabase() async {
    try {
      final supabase = Supabase.instance.client;
      final data = await supabase.from('posts').select('category_names');

      final Set<String> uniqueCategories = {};
      for (var row in data) {
        final List? categories = row['category_names'] as List?;
        if (categories != null) {
          for (var cat in categories) {
            uniqueCategories.add(cat.toString());
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

  // AI Module: Fetches top 5 locations based on average rating
  Future<void> _fetchTopRankings() async {
    try {
      final supabase = Supabase.instance.client;

      // 1. Fetch ratings and locations from all posts
      final data = await supabase
          .from('posts')
          .select('location_name, rating');

      final List<Map<String, dynamic>> fetchedPosts = List<Map<String, dynamic>>.from(data);

      // 2. AI Logic: Group all ratings by their location name
      Map<String, List<double>> locationGroups = {};
      for (var post in fetchedPosts) {
        String loc = post['location_name'] ?? 'Unknown Location';
        double rate = (post['rating'] ?? 0).toDouble();
        locationGroups.putIfAbsent(loc, () => []).add(rate);
      }

      // 3. Calculate the average rating for each unique location
      List<Map<String, dynamic>> rankedLocations = locationGroups.entries.map((entry) {
        double avg = entry.value.reduce((a, b) => a + b) / entry.value.length;
        return {
          'location_name': entry.key,
          'avg_rating': avg,
        };
      }).toList();

      // 4. Sort locations by highest average and take the top 5
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

  // --- SEARCH SUBMISSION LOGIC ---

  Future<void> _submitSearch(String query) async {
    final String trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return;

    final supabase = Supabase.instance.client;

    try {
      // 1. "Look ahead" to see what categories this search term (location or title) relates to
      final postData = await supabase
          .from('posts')
          .select('category_names')
          .or('location_name.ilike.%$trimmedQuery%,title.ilike.%$trimmedQuery%')
          .limit(10); // Check the top 10 matching posts

      // 2. Extract the actual categories from those posts
      Set<String> categoriesToRecord = {};
      for (var row in postData) {
        final List? cats = row['category_names'] as List?;
        if (cats != null) {
          for (var c in cats) {
            categoriesToRecord.add(c.toString());
          }
        }
      }

      // 3. Logic: If we found categories linked to this location/query, record THEM
      if (categoriesToRecord.isNotEmpty) {
        await supabase.rpc('increment_interest_counts', params: {
          'p_user_id': widget.currentUserData['id'],
          'categories': categoriesToRecord.toList(),
        });
        debugPrint("AI learned categories from $trimmedQuery: $categoriesToRecord");
      }
      // 4. Fallback: If it's a direct category search (no posts found yet), record the query itself
      else {
        await supabase.rpc('increment_interest_counts', params: {
          'p_user_id': widget.currentUserData['id'],
          'categories': [trimmedQuery],
        });
      }
    } catch (e) {
      debugPrint("AI Learning Error: $e");
    }

    // Navigate to results as usual
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
          decoration: const InputDecoration(
            hintText: "Search location, title, or category...",
            border: InputBorder.none,
          ),
          onSubmitted: _submitSearch,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- SECTION 1: TOP RANKED LOCATIONS (AI MODULE) ---
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
                            shop['avg_rating'].toStringAsFixed(1), // Display average with 1 decimal place
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

            // --- SECTION 2: QUICK CATEGORIES ---
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