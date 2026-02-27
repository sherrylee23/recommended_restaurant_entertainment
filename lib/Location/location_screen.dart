import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'favorite_location.dart';

class MapDiscoveryPage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const MapDiscoveryPage({super.key, required this.userData});

  @override
  State<MapDiscoveryPage> createState() => _MapDiscoveryPageState();
}

class _MapDiscoveryPageState extends State<MapDiscoveryPage> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  // Default to Kuala Lumpur
  LatLng _currentLocation = const LatLng(3.1390, 101.6869);
  List<Marker> _nearbyMarkers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );

      if (position.longitude < 0) {
        _currentLocation = const LatLng(3.1390, 101.6869);
      } else {
        _currentLocation = LatLng(position.latitude, position.longitude);
      }
    } catch (e) {
      debugPrint("Location Error: $e");
      _currentLocation = const LatLng(3.2036, 101.7244);
    }

    if (mounted) {
      setState(() => _isLoading = false);
      _mapController.move(_currentLocation, 15.0);
      _fetchNearbySuggestions(_currentLocation);
    }
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) return;
    setState(() => _isLoading = true);

    final url = 'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}+Malaysia&format=json&limit=1';

    try {
      final response = await http.get(Uri.parse(url), headers: {'User-Agent': 'my_discovery_app'});
      final List data = json.decode(response.body);

      if (data.isNotEmpty) {
        final newPos = LatLng(double.parse(data[0]['lat']), double.parse(data[0]['lon']));
        _mapController.move(newPos, 16.0);
        _fetchNearbySuggestions(newPos);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Location not found")));
      }
    } catch (e) {
      debugPrint("Search error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchNearbySuggestions(LatLng location) async {
    setState(() => _isLoading = true);

    final query = """
    [out:json][timeout:30];
    (
      node(around:3000, ${location.latitude}, ${location.longitude})[amenity~"restaurant|cafe|cinema|theatre|nightclub|pub|karaoke_box"];
      node(around:3000, ${location.latitude}, ${location.longitude})[leisure~"theme_park|water_park|bowling_alley|arcade|fitness_centre|park|playground"];
      node(around:3000, ${location.latitude}, ${location.longitude})[shop~"mall"];
    );
    out body;
    """;

    final url = 'https://overpass-api.de/api/interpreter?data=${Uri.encodeComponent(query)}';

    try {
      final response = await http.get(Uri.parse(url), headers: {'User-Agent': 'my_discovery_app'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<Marker> markers = [];

        for (var element in data['elements']) {
          final tags = element['tags'] ?? {};
          final String type = tags['amenity'] ?? tags['leisure'] ?? tags['shop'] ?? "place";
          final String name = tags['name'] ?? "Nearby Place";

          markers.add(
            Marker(
              point: LatLng(element['lat'], element['lon']),
              width: 45, height: 45,
              child: GestureDetector(
                onTap: () => _showPlaceDetail(name, type, element['lat'], element['lon']),
                child: _buildMarkerIcon(type),
              ),
            ),
          );
        }

        if (mounted) {
          setState(() {
            _nearbyMarkers = markers;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Overpass Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildMarkerIcon(String type) {
    IconData icon;
    Color color;

    switch (type) {
      case 'restaurant':
      case 'cafe':
        icon = Icons.restaurant;
        color = Colors.orangeAccent;
        break;
      case 'cinema':
      case 'theatre':
      case 'karaoke_box':
        icon = Icons.movie_creation_outlined;
        color = Colors.purpleAccent;
        break;
      case 'mall':
        icon = Icons.local_mall;
        color = Colors.blueAccent;
        break;
      case 'park':
      case 'theme_park':
      case 'water_park':
      case 'playground':
        icon = Icons.terrain_outlined;
        color = Colors.green;
        break;
      case 'arcade':
      case 'bowling_alley':
        icon = Icons.videogame_asset_outlined;
        color = Colors.pinkAccent;
        break;
      case 'nightclub':
      case 'pub':
        icon = Icons.nightlife;
        color = Colors.indigo;
        break;
      default:
        icon = Icons.location_on;
        color = Colors.redAccent;
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(Icons.location_on, color: color, size: 45),
        Positioned(
          top: 6,
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ],
    );
  }

  Future<void> _saveToFavorites(String name, String category, double lat, double lon) async {
    final supabase = Supabase.instance.client;
    try {
      await supabase.from('favorite_places').insert({
        'profile_id': widget.userData['id'],
        'place_name': name,
        'category': category,
        'latitude': lat,
        'longitude': lon,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Saved $name!"), backgroundColor: Colors.green)
        );
      }
    } catch (e) {
      debugPrint("Save error: $e");
    }
  }

  void _showPlaceDetail(String name, String type, double lat, double lon) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              subtitle: Text(type.toUpperCase().replaceAll('_', ' '), style: TextStyle(color: Colors.grey[600])),
              trailing: IconButton(
                icon: const Icon(Icons.favorite_border, color: Colors.red, size: 30),
                onPressed: () {
                  Navigator.pop(context);
                  _saveToFavorites(name, type, lat, lon);
                },
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.directions),
              label: const Text("View on Map"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Explore Malaysia"),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmarks),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => FavoritesPage(userData: widget.userData)),
              );
              if (result != null) {
                final target = LatLng(result['lat'], result['lon']);
                _mapController.move(target, 17.0);
                _fetchNearbySuggestions(target);
              }
            },
          )
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: 14.0,
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.malaysia_discovery',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                      point: _currentLocation,
                      width: 60, height: 60,
                      child: const Icon(Icons.person_pin_circle, color: Colors.blue, size: 50)
                  ),
                  ..._nearbyMarkers,
                ],
              ),
            ],
          ),

          // Search Bar
          Positioned(
            top: 10, left: 15, right: 15,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3))],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Search places in Malaysia...",
                  prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => _searchController.clear(),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onSubmitted: (value) => _searchLocation(value),
              ),
            ),
          ),

          // Recenter Button
          Positioned(
            bottom: 30, right: 20,
            child: FloatingActionButton(
              heroTag: "recenter",
              backgroundColor: Colors.blueAccent,
              onPressed: () {
                _mapController.move(_currentLocation, 16.0);
                _fetchNearbySuggestions(_currentLocation);
              },
              child: const Icon(Icons.my_location, color: Colors.white),
            ),
          ),

          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}