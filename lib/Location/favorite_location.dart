import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart'; // REQUIRED
import '../language_provider.dart'; // REQUIRED

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
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final userId = widget.userData['id'];
      final data = await _supabase
          .from('favorite_places')
          .select()
          .eq('profile_id', userId)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _favorites = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching favorites: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteFavorite(int id, LanguageProvider lp) async {
    try {
      await _supabase.from('favorite_places').delete().eq('id', id);
      _fetchFavorites();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(lp.getString('removed_fav')), // TRANSLATED
            backgroundColor: Colors.redAccent.withOpacity(0.8),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint("Delete error: $e");
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final lp = Provider.of<LanguageProvider>(context);

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
        title: Text(
          lp.getString('saved_places'), // TRANSLATED
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1),
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
            ? _buildEmptyState(lp)
            : _buildFavoritesList(lp),
      ),
    );
  }

  Widget _buildFavoritesList(LanguageProvider lp) {
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
        final String category = place['category'] ?? 'place';

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
                      _getCategoryIcon(category),
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
                      lp.getString(category).toUpperCase(), // TRANSLATED CATEGORY
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
                    onPressed: () => _deleteFavorite(place['id'], lp),
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

  Widget _buildEmptyState(LanguageProvider lp) {
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
          Text(
            lp.getString('no_favorites_title'), // TRANSLATED
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            lp.getString('no_favorites_desc'), // TRANSLATED
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
            child: Text(lp.getString('go_explore')), // TRANSLATED
          ),
        ],
      ),
    );
  }
}