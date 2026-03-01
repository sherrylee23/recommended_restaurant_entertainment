import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:recommended_restaurant_entertainment/loginModule/login_page.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'business_edit_profile.dart';

class BusinessProfilePage extends StatefulWidget {
  final Map<String, dynamic> businessData;
  const BusinessProfilePage({super.key, required this.businessData});

  @override
  State<BusinessProfilePage> createState() => _BusinessProfilePageState();
}

class _BusinessProfilePageState extends State<BusinessProfilePage> {
  // Fix: Make nullable to avoid LateInitializationError
  Map<String, dynamic>? _currentBusinessData;
  List<Map<String, dynamic>> _posts = [];
  final TextEditingController _postController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  List<File> _selectedImages = [];
  bool _isUploading = false;
  bool _isLoadingPosts = true;

  @override
  void initState() {
    super.initState();
    // Fix: Initialize immediately with passed data so UI has content to show
    _currentBusinessData = widget.businessData;
    _fetchProfile();
    _fetchPosts();
  }

  Future<void> _fetchProfile() async {
    try {
      final data = await Supabase.instance.client
          .from('business_profiles')
          .select()
          .eq('id', widget.businessData['id'])
          .single();

      if (mounted) {
        setState(() {
          _currentBusinessData = data;
        });
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
    }
  }

  Future<void> _fetchPosts() async {
    try {
      final data = await Supabase.instance.client
          .from('business_posts')
          .select()
          .eq('business_id', widget.businessData['id'])
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _posts = List<Map<String, dynamic>>.from(data);
          _isLoadingPosts = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingPosts = false);
    }
  }

  void _showSSMDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.verified, color: Colors.green),
              SizedBox(width: 10),
              Text("Verified Business", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            "This business has been successfully verified via SSM (Suruhanjaya Syarikat Malaysia).",
            style: TextStyle(fontSize: 15, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Got it", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickImages(StateSetter setSheetState) async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setSheetState(() {
        _selectedImages.addAll(images.map((img) => File(img.path)));
      });
    }
  }

  void _showCreatePostSheet() {
    _selectedImages = [];
    _postController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20, right: 20, top: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                    const Text("New Post", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                    _isUploading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : ElevatedButton(
                      onPressed: () async {
                        if (_postController.text.isNotEmpty || _selectedImages.isNotEmpty) {
                          setSheetState(() => _isUploading = true);
                          try {
                            List<String> imageUrls = [];
                            for (var imageFile in _selectedImages) {
                              final fileName = 'post_${DateTime.now().millisecondsSinceEpoch}_${_selectedImages.indexOf(imageFile)}.jpg';
                              final path = '${widget.businessData['id']}/$fileName';
                              await Supabase.instance.client.storage.from('business_posts').upload(path, imageFile);
                              final url = Supabase.instance.client.storage.from('business_posts').getPublicUrl(path);
                              imageUrls.add(url);
                            }
                            await Supabase.instance.client.from('business_posts').insert({
                              'business_id': widget.businessData['id'],
                              'text': _postController.text,
                              'image_urls': imageUrls,
                            });
                            Navigator.pop(context);
                            _fetchPosts();
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                          } finally {
                            if (mounted) setSheetState(() => _isUploading = false);
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF07C160)),
                      child: const Text("Post", style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
                TextField(
                  controller: _postController,
                  maxLines: 3,
                  decoration: const InputDecoration(hintText: "What's new?", border: InputBorder.none),
                ),
                if (_selectedImages.isNotEmpty)
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedImages.length,
                      itemBuilder: (context, i) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(_selectedImages[i], width: 100, height: 100, fit: BoxFit.cover),
                        ),
                      ),
                    ),
                  ),
                IconButton(icon: const Icon(Icons.add_a_photo, color: Colors.grey), onPressed: () => _pickImages(setSheetState)),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Safety check: Show loader if data is somehow still null
    if (_currentBusinessData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final String businessName = _currentBusinessData!['business_name']?.toString() ?? "Business";
    final String businessId = _currentBusinessData!['id']?.toString() ?? "N/A";

    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(businessName, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu, color: Colors.black87),
            onSelected: (value) => value == 'logout' ? _handleLogout() : null,
            itemBuilder: (context) => [const PopupMenuItem(value: 'logout', child: Text("Logout"))],
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchProfile();
          await _fetchPosts();
        },
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildGradientHeader(businessName, businessId),
              _buildMomentsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGradientHeader(String name, String id) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Colors.blue.shade100, Colors.purple.shade50],
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            _buildBusinessHeader(name, id),
            Padding(
              padding: const EdgeInsets.only(left: 30, top: 15, bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoSection("Address:", _currentBusinessData!['address'] ?? "N/A"),
                  _buildInfoSection("Hours:", _currentBusinessData!['hours'] ?? "N/A"),
                  _buildInfoSection("Phone:", _currentBusinessData!['phone'] ?? "N/A"),
                ],
              ),
            ),
            _buildStatsAndEditRow(),
            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }

  Widget _buildMomentsSection() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 12, 15, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Moments", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                GestureDetector(
                  onTap: _showCreatePostSheet,
                  child: _buildAddButtonIcon(),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),
          if (_isLoadingPosts)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
          else if (_posts.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Text("No posts yet")))
          else
            _buildPostList(),
        ],
      ),
    );
  }

  Widget _buildPostList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        final post = _posts[index];
        final List<dynamic> imageUrls = post['image_urls'] ?? [];

        return Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(radius: 22, child: Icon(Icons.store)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_currentBusinessData!['business_name'] ?? "Business",
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF576B95))),
                    if (post['text'] != null && post['text'].toString().isNotEmpty)
                      Padding(padding: const EdgeInsets.only(top: 4), child: Text(post['text'])),
                    if (imageUrls.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: imageUrls.length == 1
                            ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(imageUrls[0], fit: BoxFit.cover))
                            : SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: imageUrls.length,
                            itemBuilder: (context, i) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(imageUrls[i], width: 120, height: 120, fit: BoxFit.cover),
                              ),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    const Text("Just now", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAddButtonIcon() {
    return Container(
      width: 35, height: 35,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [Color(0xFF80D8FF), Color(0xFFEA80FC)]),
      ),
      child: const Icon(Icons.add, color: Colors.white, size: 24),
    );
  }

  Widget _buildBusinessHeader(String name, String id) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          const CircleAvatar(radius: 45, backgroundColor: Colors.white, child: Icon(Icons.store, size: 50, color: Colors.brown)),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 5),
                  GestureDetector(
                    onTap: () => _showSSMDialog(context),
                    child: const Icon(Icons.verified, size: 18, color: Colors.green),
                  ),
                ],
              ),
              Text("ID:$id", style: const TextStyle(color: Colors.black54, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, dynamic content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
          Text(content?.toString() ?? "N/A", style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildStatsAndEditRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_posts.length.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Text("Posts", style: TextStyle(fontSize: 12))
                ]),
            const SizedBox(width: 30),
          ]),
          ElevatedButton(
            onPressed: () async {
              // Wait for edit to finish
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BusinessEditProfilePage(businessData: _currentBusinessData!),
                ),
              );
              // Trigger refresh when back
              _fetchProfile();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.9),
                foregroundColor: Colors.black87,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: Colors.grey.shade300))),
            child: const Text("Edit Profile", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginPage()), (route) => false);
  }
}