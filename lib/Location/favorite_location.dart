import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  // --- 获取数据：从 Supabase 读取当前用户的收藏 ---
  Future<void> _fetchFavorites() async {
    setState(() => _isLoading = true);
    try {
      final userId = widget.userData['id'];
      final data = await _supabase
          .from('favorite_places')
          .select()
          .eq('profile_id', userId)
          .order('created_at', ascending: false); // 按时间排序，最新的在上面

      setState(() {
        _favorites = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching favorites: $e");
      setState(() => _isLoading = false);
    }
  }

  // --- 删除功能：从数据库移除收藏 ---
  Future<void> _deleteFavorite(int id) async {
    try {
      await _supabase.from('favorite_places').delete().eq('id', id);
      _fetchFavorites(); // 刷新列表
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Removed from favorites")),
        );
      }
    } catch (e) {
      debugPrint("Delete error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Favorite Places"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _favorites.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: _favorites.length,
        itemBuilder: (context, index) {
          final place = _favorites[index];
          return Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.blueAccent,
                child: Icon(Icons.location_on, color: Colors.white),
              ),
              title: Text(
                place['place_name'] ?? "Unknown Place",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text("Category: ${place['category']}"),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () => _deleteFavorite(place['id']),
              ),
              onTap: () {
                // 这里可以返回经纬度给上一个页面，或者直接在这里处理逻辑
                Navigator.pop(context, {
                  'lat': place['latitude'],
                  'lon': place['longitude']
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text("No favorites yet!", style: TextStyle(fontSize: 18, color: Colors.grey[600])),
          const Text("Go explore the map and save some places!"),
        ],
      ),
    );
  }
}