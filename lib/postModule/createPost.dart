import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _customCategoryController = TextEditingController();

  final List<File> _selectedMedia = [];
  double _rating = 0;
  bool _isOtherSelected = false;
  final List<String> _selectedCategories = [];

  final List<String> _categories = [
    'Restaurant', 'Cafe', 'Bar', 'Street Food',
    'Cinema', 'Karaoke', 'Theme Park', 'Shopping', 'Live Music', 'Gaming',
    'Other'
  ];

  // 1. Updated for Multi-Photo Selection
  Future<void> _pickMedia() async {
    final ImagePicker picker = ImagePicker();
    // pickMultiImage allows selecting multiple photos at once from Drive/Gallery
    final List<XFile> images = await picker.pickMultiImage();

    if (images.isNotEmpty) {
      setState(() {
        for (var image in images) {
          // Maintaining the 9-photo limit for your Smart Lifestyle app
          if (_selectedMedia.length < 9) {
            _selectedMedia.add(File(image.path));
          }
        }
      });

      if (_selectedMedia.length >= 9 && images.length > (_selectedMedia.length - images.length)) {
        _showSnackBar("Maximum 9 photos allowed", Colors.orange);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Create New Post", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.blue.shade100, Colors.purple.shade50]),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 2. Horizontal Preview List (Fixed Preview Issue)
            if (_selectedMedia.isNotEmpty)
              Container(
                height: 110,
                margin: const EdgeInsets.only(bottom: 20),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedMedia.length,
                  itemBuilder: (context, index) {
                    final file = _selectedMedia[index];

                    return Container(
                      width: 100,
                      margin: const EdgeInsets.only(right: 12),
                      child: Stack(
                        children: [
                          GestureDetector(
                            onTap: () {
                              // Navigates to swipeable gallery
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => GalleryPreview(
                                      files: _selectedMedia,
                                      initialIndex: index
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              height: 100,
                              width: 100,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.black12,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                  file,
                                  fit: BoxFit.cover,
                                  // Handles potential Google Drive sync lag
                                  errorBuilder: (context, error, stackTrace) => const Center(
                                    child: Icon(Icons.broken_image, color: Colors.grey),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 2,
                            right: 2,
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedMedia.removeAt(index)),
                              child: const CircleAvatar(
                                radius: 10,
                                backgroundColor: Colors.red,
                                child: Icon(Icons.close, size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

            _mediaPicker(LucideIcons.image, "Add Photos", _pickMedia),
            const Text("\nMaximum 9 photos", style: TextStyle(fontSize: 12, color: Colors.grey)),

            const SizedBox(height: 25),
            _buildLabel("Title"),
            _buildTextField(_titleController, "Give your post a title..."),

            const SizedBox(height: 15),
            _buildLabel("Description"),
            _buildTextField(_descriptionController, "Tell us more about your experience...", maxLines: 4),

            const SizedBox(height: 15),
            _buildLabel("Location"),
            _buildTextField(_locationController, "Where was this?", icon: LucideIcons.mapPin),

            const SizedBox(height: 15),
            _buildLabel("Select Categories"),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: _categories.map((category) {
                final isSelected = _selectedCategories.contains(category);
                return FilterChip(
                  label: Text(category),
                  selected: isSelected,
                  selectedColor: Colors.blue.shade200,
                  onSelected: (bool selected) {
                    setState(() {
                      if (selected) {
                        _selectedCategories.add(category);
                        if (category == 'Other') _isOtherSelected = true;
                      } else {
                        _selectedCategories.remove(category);
                        if (category == 'Other') {
                          _isOtherSelected = false;
                          _customCategoryController.clear();
                        }
                      }
                    });
                  },
                );
              }).toList(),
            ),
            if (_isOtherSelected)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: _buildTextField(_customCategoryController, "Enter custom category...", icon: LucideIcons.plusCircle),
              ),

            const SizedBox(height: 25),
            _buildLabel("Rating"),
            Row(
              children: List.generate(5, (index) {
                return IconButton(
                  onPressed: () => setState(() => _rating = index + 1.0),
                  icon: Icon(index < _rating ? Icons.star : Icons.star_border, color: Colors.amber, size: 32),
                );
              }),
            ),

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF8ECAFF), Color(0xFF4A90E2), Colors.purpleAccent]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton(
                  onPressed: () {
                    _showSnackBar("Uploading ${ _selectedMedia.length } items...", Colors.green);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
                  child: const Text("POST NOW", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mediaPicker(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.blueAccent, size: 28),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontSize: 16, color: Colors.blueAccent, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(padding: const EdgeInsets.only(bottom: 8, left: 4), child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)));
  }

  Widget _buildTextField(TextEditingController controller, String hint, {int maxLines = 1, IconData? icon}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon, color: Colors.blueAccent, size: 20) : null,
        filled: true,
        fillColor: Colors.grey.shade50,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.blue.shade100)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.blueAccent)),
      ),
    );
  }
}

// 3. Swipeable Full-Screen Gallery Widget
class GalleryPreview extends StatelessWidget {
  final List<File> files;
  final int initialIndex;
  const GalleryPreview({super.key, required this.files, required this.initialIndex});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: PageView.builder(
        // Controller enables starting the gallery at the tapped image
        controller: PageController(initialPage: initialIndex),
        itemCount: files.length,
        itemBuilder: (context, index) {
          return Center(
            child: InteractiveViewer(
              child: Image.file(
                files[index],
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Text("Image not ready", style: TextStyle(color: Colors.white)),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}