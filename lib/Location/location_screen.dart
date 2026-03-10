import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart'; // REQUIRED
import 'dart:convert';
import 'favorite_location.dart';
import '../language_provider.dart'; // REQUIRED

class MapDiscoveryPage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const MapDiscoveryPage({super.key, required this.userData});

  @override
  State<MapDiscoveryPage> createState() => _MapDiscoveryPageState();
}

class _MapDiscoveryPageState extends State<MapDiscoveryPage> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  LatLng _currentLocation = const LatLng(3.1390, 101.6869);
  List<Marker> _nearbyMarkers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  // --- LOGIC FUNCTIONS ---

  Future<void> _initLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 5),
      );
      if (position.longitude < 0) {
        _currentLocation = const LatLng(3.1390, 101.6869);
      } else {
        _currentLocation = LatLng(position.latitude, position.longitude);
      }
    } catch (e) {
      _currentLocation = const LatLng(3.2036, 101.7244);
    }
    if (mounted) {
      setState(() => _isLoading = false);
      _mapController.move(_currentLocation, 15.0);
      _fetchNearbySuggestions(_currentLocation);
    }
  }

  Future<void> _searchLocation(String query, LanguageProvider lp) async {
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
        _showSnackBar(lp.getString('loc_not_found'), Colors.orange);
      }
    } catch (e) { debugPrint("Search error: $e"); }
    finally { if (mounted) setState(() => _isLoading = false); }
  }

  Future<void> _fetchNearbySuggestions(LatLng location) async {
    if (!mounted) return;
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
              width: 45,
              height: 45,
              child: GestureDetector(
                onTap: () => _showPlaceDetail(name, type, element['lat'], element['lon']),
                child: _buildMarkerIcon(type),
              ),
            ),
          );
        }
        if (mounted) { setState(() { _nearbyMarkers = markers; _isLoading = false; }); }
      }
    } catch (e) { if (mounted) setState(() => _isLoading = false); }
  }

  Future<void> _saveToFavorites(String name, String category, double lat, double lon, LanguageProvider lp) async {
    final supabase = Supabase.instance.client;
    try {
      await supabase.from('favorite_places').insert({
        'profile_id': widget.userData['id'],
        'place_name': name,
        'category': category,
        'latitude': lat,
        'longitude': lon,
      });
      _showSnackBar(lp.getString('saved_to_fav').replaceFirst('{}', name), Colors.green);
    } catch (e) { debugPrint("Save error: $e"); }
  }

  void _showSnackBar(String m, Color c) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: c, behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    final lp = Provider.of<LanguageProvider>(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              color: const Color(0xFF0F0C29).withOpacity(0.7),
              child: Text(lp.getString('discovery_map'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: IconButton(
              icon: CircleAvatar(
                backgroundColor: const Color(0xFF0F0C29).withOpacity(0.7),
                child: const Icon(LucideIcons.bookmark, color: Colors.cyanAccent, size: 18),
              ),
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
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildMap(),
          _buildTopSearch(lp),
          _buildRecenterButton(),
          if (_isLoading) _buildLoadingBlur(),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _currentLocation,
        initialZoom: 14.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
          userAgentPackageName: 'com.example.malaysia_discovery',
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: _currentLocation,
              width: 80, height: 80,
              child: _buildUserLocationMarker(),
            ),
            ..._nearbyMarkers,
          ],
        ),
      ],
    );
  }

  Widget _buildUserLocationMarker() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blueAccent.withOpacity(0.2),
            border: Border.all(color: Colors.blueAccent.withOpacity(0.5), width: 2),
          ),
        ),
        const Icon(LucideIcons.mapPin, color: Color(0xFF0F0C29), size: 30),
      ],
    );
  }

  Widget _buildMarkerIcon(String type) {
    IconData icon;
    Color accentColor;

    switch (type) {
      case 'restaurant': case 'cafe': icon = LucideIcons.utensils; accentColor = Colors.orangeAccent; break;
      case 'cinema': case 'theatre': case 'karaoke_box': icon = LucideIcons.film; accentColor = Colors.purpleAccent; break;
      case 'mall': icon = LucideIcons.shoppingBag; accentColor = Colors.blueAccent; break;
      case 'park': case 'theme_park': case 'water_park': icon = LucideIcons.trees; accentColor = Colors.greenAccent; break;
      case 'arcade': case 'bowling_alley': icon = LucideIcons.gamepad2; accentColor = Colors.pinkAccent; break;
      case 'nightclub': case 'pub': icon = LucideIcons.glassWater; accentColor = Colors.indigoAccent; break;
      default: icon = LucideIcons.mapPin; accentColor = Colors.cyanAccent;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0C29),
        shape: BoxShape.circle,
        border: Border.all(color: accentColor.withOpacity(0.8), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(icon, color: accentColor, size: 18),
    );
  }

  Widget _buildTopSearch(LanguageProvider lp) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 80,
      left: 20, right: 20,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: const Color(0xFF0F0C29).withOpacity(0.85),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 15)],
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              onSubmitted: (query) => _searchLocation(query, lp),
              decoration: InputDecoration(
                hintText: lp.getString('search_malaysia'), // TRANSLATED
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(LucideIcons.search, color: Colors.cyanAccent, size: 20),
                suffixIcon: IconButton(
                  icon: const Icon(LucideIcons.x, color: Colors.white38, size: 16),
                  onPressed: () => _searchController.clear(),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecenterButton() {
    return Positioned(
      bottom: 110, right: 20,
      child: GestureDetector(
        onTap: () {
          _mapController.move(_currentLocation, 16.0);
          _fetchNearbySuggestions(_currentLocation);
        },
        child: Container(
          width: 55, height: 55,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(colors: [Colors.cyanAccent, Colors.blueAccent]),
            boxShadow: [
              BoxShadow(color: Colors.cyanAccent.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))
            ],
          ),
          child: const Icon(LucideIcons.navigation, color: Color(0xFF0F0C29), size: 24),
        ),
      ),
    );
  }

  Widget _buildLoadingBlur() {
    return Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          color: const Color(0xFF0F0C29).withOpacity(0.1),
          child: const Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
        ),
      ),
    );
  }

  void _showPlaceDetail(String name, String type, double lat, double lon) {
    final lp = Provider.of<LanguageProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF0F0C29).withOpacity(0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
                        const SizedBox(height: 4),
                        // TYPE TRANSLATED FROM L10N
                        Text(lp.getString(type).toUpperCase(), style: const TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.heart, color: Colors.pinkAccent, size: 28),
                    onPressed: () {
                      Navigator.pop(context);
                      _saveToFavorites(name, type, lat, lon, lp);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: const LinearGradient(colors: [Colors.cyanAccent, Colors.blueAccent]),
                ),
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(LucideIcons.map, color: Color(0xFF0F0C29)),
                  label: Text(lp.getString('close_detail'), style: const TextStyle(color: Color(0xFF0F0C29), fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    minimumSize: const Size(double.infinity, 55),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}