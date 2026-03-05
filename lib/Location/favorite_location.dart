import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';

class FavoritesPage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const FavoritesPage({super.key, required this.userData});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _favorites = [];

  @override
  void initState() {
    super.initState();
    _fetchFavorites();
  }

  // --- LOGIC FUNCTIONS (STRICTLY PRESERVED) ---

  Future<void> _fetchFavorites() async {
    setState(() => _isLoading = true);
    try {
      final userId = widget.userData['id'];
      final data = await _supabase
          .from('favorite_places')
          .select()
          .eq('profile_id', userId)
          .order('created_at', ascending: false);

      setState(() {
        _favorites = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching favorites: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteFavorite(int id) async {
    try {
      await _supabase.from('favorite_places').delete().eq('id', id);
      _fetchFavorites();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Removed from favorites"),
            backgroundColor: Colors.redAccent.withOpacity(0.8),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint("Delete error: $e");
    }
  }

  // --- CATEGORY ICON HELPER (MATCHING MAP STYLE) ---
  IconData _getCategoryIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'restaurant': case 'cafe': return LucideIcons.utensils;
      case 'cinema': case 'theatre': case 'karaoke_box': return LucideIcons.film;
      case 'mall': return LucideIcons.shoppingBag;
      case 'park': case 'theme_park': return LucideIcons.trees;
      case 'arcade': case 'gaming': return LucideIcons.gamepad2;
      case 'nightclub': case 'pub': return LucideIcons.glassWater;
      default: return LucideIcons.mapPin;
    }
  }

  // --- REDESIGNED UI ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF0F0C29),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Saved Places",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1),
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
            : _favorites.isEmpty
            ? _buildEmptyState()
            : _buildFavoritesList(),
      ),
    );
  }

  Widget _buildFavoritesList() {
    return ListView.builder(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 70,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      itemCount: _favorites.length,
      itemBuilder: (context, index) {
        final place = _favorites[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      _getCategoryIcon(place['category']),
                      color: Colors.blueAccent,
                      size: 24,
                    ),
                  ),
                  title: Text(
                    place['place_name'] ?? "Unknown Place",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      (place['category'] ?? "Place").toUpperCase(),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 11,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  trailing: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.trash2, color: Colors.redAccent, size: 18),
                    ),
                    onPressed: () => _deleteFavorite(place['id']),
                  ),
                  onTap: () {
                    Navigator.pop(context, {
                      'lat': place['latitude'],
                      'lon': place['longitude']
                    });
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.03),
            ),
            child: Icon(LucideIcons.mapPin, size: 64, color: Colors.white.withOpacity(0.1)),
          ),
          const SizedBox(height: 24),
          const Text(
            "No favorites yet!",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            "Go explore the map and save some places!",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.5)),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text("Go Explore"),
          ),
        ],
      ),
    );
  }
}