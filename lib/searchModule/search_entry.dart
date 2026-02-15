import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:recommended_restaurant_entertainment/searchModule/search_result.dart';

class SearchEntryPage extends StatefulWidget {
  // MODIFIED: Added parameter to receive the current logged-in user's data
  final Map<String, dynamic> currentUserData;

  const SearchEntryPage({super.key, required this.currentUserData});

  @override
  State<SearchEntryPage> createState() => _SearchEntryPageState();
}

class _SearchEntryPageState extends State<SearchEntryPage> {
  final TextEditingController _controller = TextEditingController();
  List<String> _dynamicCategories = [];
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _fetchCategoriesFromSupabase();
  }

  // Fetches unique categories currently used in the 'posts' table
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

  void _submitSearch(String query) {
    if (query.trim().isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchResultsPage(
          query: query.trim(),
          // MODIFIED: Passing the viewer's data forward to the results page
          currentUserData: widget.currentUserData,
        ),
      ),
    );
  }

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
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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