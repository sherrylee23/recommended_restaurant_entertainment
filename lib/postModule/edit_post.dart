import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditPostPage extends StatefulWidget {
  final Map<String, dynamic> post;
  const EditPostPage({super.key, required this.post});

  @override
  State<EditPostPage> createState() => _EditPostPageState();
}

class _EditPostPageState extends State<EditPostPage> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;

  List<String> _existingUrls = [];
  final List<File> _newMedia = [];

  double _rating = 0;
  bool _isSaving = false;
  List<String> _selectedCategories = [];

  List<Map<String, dynamic>> _locationResults = [];
  String? _selectedLocationName;

  final List<String> _categories = [
    'Restaurant', 'Cafe', 'Bar', 'Street Food',
    'Cinema', 'Karaoke', 'Theme Park', 'Shopping', 'Live Music', 'Gaming', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.post['title']);
    _descriptionController = TextEditingController(text: widget.post['description']);
    _locationController = TextEditingController(text: widget.post['location_name']);
    _selectedLocationName = widget.post['location_name'];
    _rating = (widget.post['rating'] ?? 0).toDouble();
    _existingUrls = List<String>.from(widget.post['media_urls'] ?? []);
    _selectedCategories = List<String>.from(widget.post['category_names'] ?? []);
  }

  // --- LOGIC ---
  Future<void> _searchLocations(String query) async {
    if (query.isEmpty) {
      setState(() => _locationResults = []);
      return;
    }
    try {
      final data = await Supabase.instance.client
          .from('locations').select('name, address, area').ilike('name', '%$query%').limit(5);
      setState(() => _locationResults = List<Map<String, dynamic>>.from(data));
    } catch (e) { debugPrint("Search error: $e"); }
  }

  Future<void> _handleUpdate() async {
    FocusScope.of(context).unfocus();
    if (_titleController.text.isEmpty || _selectedLocationName == null || (_existingUrls.isEmpty && _newMedia.isEmpty)) {
      _showSnackBar("Missing info: Title, Location, and Photos are required!", Colors.orange);
      return;
    }

    setState(() => _isSaving = true);
    final supabase = Supabase.instance.client;

    try {
      List<String> finalUrls = List.from(_existingUrls);

      // Use profile_id for path consistency
      final dynamic profileId = widget.post['profile_id'];

      for (var i = 0; i < _newMedia.length; i++) {
        final path = 'posts/$profileId/edit_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        await supabase.storage.from('post_media').upload(path, _newMedia[i]);
        finalUrls.add(supabase.storage.from('post_media').getPublicUrl(path));
      }

      // --- MODIFIED: Ensure profile_id is kept in the map ---
      final updatedPost = {
        'id': widget.post['id'],
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'location_name': _selectedLocationName,
        'rating': _rating,
        'category_names': _selectedCategories,
        'media_urls': finalUrls,
        'profile_id': widget.post['profile_id'], // CRITICAL: Keep owner ID
      };

      await supabase.from('posts').update(updatedPost).eq('id', widget.post['id']);

      if (mounted) {
        _showSnackBar("Post updated successfully!", Colors.green);
        // Pass back the full object including profile_id
        Navigator.pop(context, updatedPost);
      }
    } catch (e) {
      _showSnackBar("Update failed: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnackBar(String m, Color c) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: c));
  }

  // --- UI HELPERS ---
  Widget _buildMediaStrip() {
    final List<dynamic> combinedMedia = [..._existingUrls, ..._newMedia];

    return Container(
      height: 110,
      margin: const EdgeInsets.only(bottom: 20),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: combinedMedia.length,
        itemBuilder: (context, index) {
          final item = combinedMedia[index];
          final bool isNetwork = item is String;

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditGalleryViewer(
                    initialIndex: index,
                    existingUrls: _existingUrls,
                    newMedia: _newMedia,
                    onDelete: (idx) {
                      setState(() {
                        if (idx < _existingUrls.length) {
                          _existingUrls.removeAt(idx);
                        } else {
                          _newMedia.removeAt(idx - _existingUrls.length);
                        }
                      });
                    },
                  ),
                ),
              );
            },
            child: Container(
              width: 100,
              margin: const EdgeInsets.only(right: 12),
              child: Stack(
                children: [
                  Hero(
                    tag: 'edit_photo_$index',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: isNetwork
                          ? Image.network(item, width: 100, height: 100, fit: BoxFit.cover)
                          : Image.file(item, width: 100, height: 100, fit: BoxFit.cover),
                    ),
                  ),
                  Positioned(
                    top: 2, right: 2,
                    child: GestureDetector(
                      onTap: () => setState(() {
                        isNetwork ? _existingUrls.remove(item) : _newMedia.remove(item);
                      }),
                      child: const CircleAvatar(radius: 10, backgroundColor: Colors.red, child: Icon(Icons.close, size: 14, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            leading: IconButton(icon: const Icon(LucideIcons.chevronLeft), onPressed: () => Navigator.pop(context)),
            title: const Text("Edit Post", style: TextStyle(fontWeight: FontWeight.bold)),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_existingUrls.isNotEmpty || _newMedia.isNotEmpty) _buildMediaStrip(),
                _buildMediaPicker(),
                const SizedBox(height: 25),
                _buildLabel("Title"),
                _buildTextField(_titleController, "Post title..."),
                const SizedBox(height: 15),
                _buildLabel("Description"),
                _buildTextField(_descriptionController, "Change your thoughts...", maxLines: 3),
                const SizedBox(height: 15),
                _buildLabel("Location"),
                _buildLocationSearch(),
                const SizedBox(height: 15),
                _buildLabel("Categories"),
                _buildCategoryChips(),
                const SizedBox(height: 25),
                _buildLabel("Rating"),
                _buildStarRating(),
                const SizedBox(height: 30),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
        if (_isSaving) Container(color: Colors.black26, child: const Center(child: CircularProgressIndicator())),
      ],
    );
  }

  Widget _buildTextField(TextEditingController c, String h, {int maxLines = 1}) => TextField(controller: c, maxLines: maxLines, decoration: InputDecoration(hintText: h, filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))));
  Widget _buildLabel(String t) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(t, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)));
  Widget _buildMediaPicker() => GestureDetector(onTap: () async { final i = await ImagePicker().pickMultiImage(); if (i.isNotEmpty) setState(() { for (var x in i) { if (_newMedia.length + _existingUrls.length < 9) _newMedia.add(File(x.path)); } }); }, child: Container(height: 70, decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(15)), child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(LucideIcons.image), SizedBox(width: 10), Text("Add More Photos")])));
  Widget _buildCategoryChips() => Wrap(spacing: 8, children: _categories.map((c) => FilterChip(label: Text(c), selected: _selectedCategories.contains(c), onSelected: (s) => setState(() => s ? _selectedCategories.add(c) : _selectedCategories.remove(c)))).toList());
  Widget _buildStarRating() => Row(children: List.generate(5, (i) => IconButton(icon: Icon(i < _rating ? Icons.star : Icons.star_border, color: Colors.amber, size: 32), onPressed: () => setState(() => _rating = i + 1.0))));
  Widget _buildSubmitButton() => Container(width: double.infinity, height: 55, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF8ECAFF), Color(0xFF4A90E2), Colors.purpleAccent]), borderRadius: BorderRadius.circular(12)), child: ElevatedButton(onPressed: _isSaving ? null : _handleUpdate, style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent), child: const Text("SAVE CHANGES", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))));
  Widget _buildLocationSearch() => Column(children: [TextField(controller: _locationController, onChanged: _searchLocations, decoration: InputDecoration(hintText: _selectedLocationName ?? "Search location...", prefixIcon: const Icon(LucideIcons.mapPin), filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))), if (_locationResults.isNotEmpty && _selectedLocationName != _locationController.text) Container(margin: const EdgeInsets.only(top: 4), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]), child: Column(children: _locationResults.map((loc) => ListTile(title: Text(loc['name'], style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text("${loc['area']} • ${loc['address']}", maxLines: 1), onTap: () => setState(() { _selectedLocationName = loc['name']; _locationResults = []; _locationController.text = loc['name']; }))).toList()))]);
}

// --- FULL-SCREEN GALLERY VIEWER CLASS ---
class EditGalleryViewer extends StatefulWidget {
  final List<String> existingUrls;
  final List<File> newMedia;
  final int initialIndex;
  final Function(int) onDelete;

  const EditGalleryViewer({
    super.key,
    required this.initialIndex,
    required this.existingUrls,
    required this.newMedia,
    required this.onDelete,
  });

  @override
  State<EditGalleryViewer> createState() => _EditGalleryViewerState();
}

class _EditGalleryViewerState extends State<EditGalleryViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    final List<dynamic> combined = [...widget.existingUrls, ...widget.newMedia];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text("${_currentIndex + 1} / ${combined.length}", style: const TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.trash2, color: Colors.redAccent),
            onPressed: () {
              widget.onDelete(_currentIndex);
              if (combined.length <= 1) {
                Navigator.pop(context);
              } else {
                setState(() {
                  if (_currentIndex >= combined.length - 1) {
                    _currentIndex = combined.length - 2;
                  }
                });
              }
            },
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: combined.length,
        onPageChanged: (idx) => setState(() => _currentIndex = idx),
        itemBuilder: (context, index) {
          final item = combined[index];
          return Center(
            child: Hero(
              tag: 'edit_photo_$index',
              child: InteractiveViewer(
                child: item is String
                    ? Image.network(item, fit: BoxFit.contain)
                    : Image.file(item, fit: BoxFit.contain),
              ),
            ),
          );
        },
      ),
    );
  }
}