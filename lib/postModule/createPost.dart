import 'dart:io';
import 'dart:ui'; // Required for Glassmorphism
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreatePostPage extends StatefulWidget {
  final String profileUserId;

  const CreatePostPage({super.key, required this.profileUserId});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  // --- ALL LOGIC & CONTROLLERS PRESERVED ---
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  final List<File> _selectedMedia = [];
  double _rating = 0;
  bool _isUploading = false;
  final List<String> _selectedCategories = [];

  List<Map<String, dynamic>> _locationResults = [];
  String? _selectedLocationName;
  String? _userName;

  final List<String> _categories = [
    'Restaurant', 'Cafe', 'Bar', 'Street Food',
    'Cinema', 'Karaoke', 'Theme Park', 'Shopping', 'Live Music', 'Gaming',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchUserInfo();
    });
    _titleController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // --- LOGIC FUNCTIONS (UNTOUCHED) ---

  int _getWordCount(String text) {
    if (text.trim().isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).length;
  }

  bool _isFormValid() {
    return _selectedMedia.isNotEmpty &&
        _titleController.text.isNotEmpty &&
        _selectedLocationName != null &&
        _selectedCategories.isNotEmpty &&
        _rating > 0;
  }

  Future<void> _fetchUserInfo() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user != null) {
      try {
        final data = await supabase.from('profiles').select('name').eq('user_id', user.id).single();
        if (mounted) setState(() => _userName = data['name']);
      } catch (e) {
        if (mounted) setState(() => _userName = user.email?.split('@')[0]);
      }
    }
  }

  Future<void> _searchLocations(String query) async {
    if (query.isEmpty) { setState(() => _locationResults = []); return; }
    try {
      final data = await Supabase.instance.client.from('locations').select('name, address, area').ilike('name', '%$query%').limit(5);
      setState(() => _locationResults = List<Map<String, dynamic>>.from(data));
    } catch (e) { debugPrint("Search error: $e"); }
  }

  Future<void> _handlePostSubmission() async {
    FocusScope.of(context).unfocus();
    if (!_isFormValid()) return;
    final supabase = Supabase.instance.client;
    final int? currentProfileId = int.tryParse(widget.profileUserId);
    if (currentProfileId == null) {
      _showSnackBar("Error: Invalid Profile ID. Please re-login.", Colors.red);
      return;
    }
    setState(() => _isUploading = true);
    try {
      List<String> mediaUrls = [];
      for (var i = 0; i < _selectedMedia.length; i++) {
        final file = _selectedMedia[i];
        final path = 'posts/$currentProfileId/${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        await supabase.storage.from('post_media').upload(path, file);
        mediaUrls.add(supabase.storage.from('post_media').getPublicUrl(path));
      }
      await supabase.from('posts').insert({
        'profile_id': currentProfileId,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'location_name': _selectedLocationName,
        'rating': _rating,
        'category_names': _selectedCategories,
        'media_urls': mediaUrls,
      });
      if (mounted) {
        _showSnackBar("Post shared successfully!", Colors.green);
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showSnackBar("Submission Error: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showSnackBar(String m, Color c) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: c, behavior: SnackBarBehavior.floating));
  }

  // --- REDESIGNED UI COMPONENTS ---

  @override
  Widget build(BuildContext context) {
    final int currentWordCount = _getWordCount(_titleController.text);
    final bool canSubmit = _isFormValid();

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF0F0C29),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("New Discovery", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
          ),
        ),
        child: Stack(
          children: [
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_userName != null) _buildUserBadge(),
                    if (_selectedMedia.isNotEmpty) _buildMediaStrip(),
                    _buildMediaPicker(),
                    const SizedBox(height: 30),

                    // --- TITLE ---
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      _buildLabel("Title *"),
                      Text("$currentWordCount/5 words",
                          style: TextStyle(fontSize: 12, color: currentWordCount > 5 ? Colors.redAccent : Colors.white38, fontWeight: FontWeight.bold))
                    ]),
                    _buildGlassTextField(
                        _titleController,
                        "Catchy title...",
                        formatters: [TextInputFormatter.withFunction((old, val) => _getWordCount(val.text) > 5 ? old : val)]
                    ),
                    const SizedBox(height: 20),

                    _buildLabel("Description"),
                    _buildGlassTextField(_descriptionController, "Tell us more about the vibe...", maxLines: 3),
                    const SizedBox(height: 20),

                    _buildLabel("Location *"),
                    _buildLocationSearch(),
                    const SizedBox(height: 20),

                    _buildLabel("Categories *"),
                    _buildCategoryChips(),
                    const SizedBox(height: 20),

                    _buildLabel("Rating *"),
                    _buildStarRating(),
                    const SizedBox(height: 40),

                    _buildSubmitButton(canSubmit),
                  ],
                ),
              ),
            ),
            if (_isUploading) _buildLoadingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserBadge() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.blueAccent.withOpacity(0.2))),
      child: Text("Posting as: $_userName", style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }

  Widget _buildGlassTextField(TextEditingController controller, String hint, {int maxLines = 1, List<TextInputFormatter>? formatters}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: TextField(
          controller: controller,
          maxLines: maxLines,
          inputFormatters: formatters,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.blueAccent)),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationSearch() => Column(children: [
    ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: TextField(
          controller: _locationController,
          onChanged: _searchLocations,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: _selectedLocationName ?? "Search KL/Selangor...",
            prefixIcon: const Icon(LucideIcons.mapPin, color: Colors.blueAccent, size: 20),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.blueAccent)),
          ),
        ),
      ),
    ),
    if (_locationResults.isNotEmpty && _selectedLocationName == null)
      Container(
        margin: const EdgeInsets.only(top: 8),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.95), borderRadius: BorderRadius.circular(15)),
        child: Column(children: _locationResults.map((loc) => ListTile(
            title: Text(loc['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("${loc['area']} • ${loc['address']}", maxLines: 1),
            onTap: () { setState(() { _selectedLocationName = loc['name']; _locationResults = []; _locationController.text = loc['name']; }); }
        )).toList()),
      )
  ]);

  Widget _buildMediaPicker() => GestureDetector(
    onTap: () async {
      final i = await ImagePicker().pickMultiImage();
      if (i.isNotEmpty) setState(() { for (var x in i) { if (_selectedMedia.length < 9) _selectedMedia.add(File(x.path)); } });
    },
    child: Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.1), style: BorderStyle.solid),
      ),
      child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(LucideIcons.image, color: Colors.blueAccent), SizedBox(width: 10), Text("Add Photos *", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))]),
    ),
  );

  Widget _buildCategoryChips() => Wrap(
    spacing: 8, runSpacing: 8,
    children: _categories.map((c) {
      final isSelected = _selectedCategories.contains(c);
      return GestureDetector(
        onTap: () => setState(() => isSelected ? _selectedCategories.remove(c) : _selectedCategories.add(c)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blueAccent : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? Colors.blueAccent : Colors.white.withOpacity(0.1)),
          ),
          child: Text(c, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        ),
      );
    }).toList(),
  );

  Widget _buildStarRating() => Row(
    children: List.generate(5, (i) => IconButton(
        icon: Icon(i < _rating ? Icons.star_rounded : Icons.star_outline_rounded, color: Colors.amber, size: 36),
        onPressed: () => setState(() => _rating = i + 1.0)
    )),
  );

  Widget _buildSubmitButton(bool canSubmit) => Container(
    width: double.infinity, height: 55,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(15),
      gradient: (canSubmit && !_isUploading)
          ? const LinearGradient(colors: [Colors.blueAccent, Colors.purpleAccent])
          : LinearGradient(colors: [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.1)]),
      boxShadow: canSubmit ? [BoxShadow(color: Colors.blueAccent.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))] : [],
    ),
    child: ElevatedButton(
      onPressed: (canSubmit && !_isUploading) ? _handlePostSubmission : null,
      style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
      child: Text(_isUploading ? "UPLOADING..." : "POST NOW", style: TextStyle(color: canSubmit ? Colors.white : Colors.white24, fontWeight: FontWeight.bold, fontSize: 16)),
    ),
  );

  Widget _buildMediaStrip() => Container(
      height: 110, margin: const EdgeInsets.only(bottom: 20),
      child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _selectedMedia.length,
          itemBuilder: (context, index) => Container(
              width: 100, margin: const EdgeInsets.only(right: 12),
              child: Stack(children: [
                GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ImageGalleryViewer(images: _selectedMedia, initialIndex: index, onDelete: (i) => setState(() => _selectedMedia.removeAt(i))))),
                    child: Hero(tag: 'photo_$index', child: ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.file(_selectedMedia[index], width: 100, height: 100, fit: BoxFit.cover)))
                ),
                Positioned(top: 4, right: 4, child: GestureDetector(onTap: () => setState(() => _selectedMedia.removeAt(index)), child: Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle), child: const Icon(Icons.close, size: 14, color: Colors.white))))
              ])
          )
      )
  );

  Widget _buildLoadingOverlay() => Positioned.fill(
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(color: Colors.black26, child: const Center(child: CircularProgressIndicator(color: Colors.blueAccent))),
    ),
  );

  Widget _buildLabel(String t) => Padding(padding: const EdgeInsets.only(bottom: 10, left: 4), child: Text(t, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)));
}

// FULL-SCREEN GALLERY VIEWER (STRICTLY PRESERVED)
class ImageGalleryViewer extends StatefulWidget {
  final List<File> images;
  final int initialIndex;
  final Function(int) onDelete;
  const ImageGalleryViewer({super.key, required this.images, required this.initialIndex, required this.onDelete});
  @override State<ImageGalleryViewer> createState() => _ImageGalleryViewerState();
}
class _ImageGalleryViewerState extends State<ImageGalleryViewer> {
  late PageController _pageController;
  late int _currentIndex;
  @override void initState() { super.initState(); _currentIndex = widget.initialIndex; _pageController = PageController(initialPage: widget.initialIndex); }
  @override Widget build(BuildContext context) { return Scaffold(backgroundColor: Colors.black, appBar: AppBar(backgroundColor: Colors.transparent, iconTheme: const IconThemeData(color: Colors.white), title: Text("${_currentIndex + 1} / ${widget.images.length}", style: const TextStyle(color: Colors.white)), actions: [IconButton(icon: const Icon(LucideIcons.trash2, color: Colors.redAccent), onPressed: () { widget.onDelete(_currentIndex); if (widget.images.length <= 1) Navigator.pop(context); else setState(() { if (_currentIndex >= widget.images.length) _currentIndex = widget.images.length - 1; }); })]), body: PageView.builder(controller: _pageController, itemCount: widget.images.length, onPageChanged: (i) => setState(() => _currentIndex = i), itemBuilder: (context, index) => Center(child: Hero(tag: 'photo_$index', child: InteractiveViewer(child: Image.file(widget.images[index], fit: BoxFit.contain)))))); }
}