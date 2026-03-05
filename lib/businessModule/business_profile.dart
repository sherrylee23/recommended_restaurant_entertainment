import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:recommended_restaurant_entertainment/loginModule/login_page.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart'; // Ensure lucide_icons is imported
import 'dart:io';
import 'business_edit_profile.dart';

class BusinessProfilePage extends StatefulWidget {
  final Map<String, dynamic> businessData;
  const BusinessProfilePage({super.key, required this.businessData});

  @override
  State<BusinessProfilePage> createState() => _BusinessProfilePageState();
}

class _BusinessProfilePageState extends State<BusinessProfilePage> {
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
    _currentBusinessData = widget.businessData;
    _fetchProfile();
    _fetchPosts();
  }

  // --- LOGIC PRESERVED ---
  Future<void> _fetchProfile() async {
    try {
      final data = await Supabase.instance.client
          .from('business_profiles')
          .select()
          .eq('id', widget.businessData['id'])
          .single();
      if (mounted) setState(() => _currentBusinessData = data);
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
      builder: (BuildContext context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: const Color(0xFF1A1A35),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.greenAccent, width: 0.5)),
          title: const Row(
            children: [
              Icon(Icons.verified, color: Colors.greenAccent),
              SizedBox(width: 10),
              Text("Verified", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            "This business has been successfully verified via SSM (Suruhanjaya Syarikat Malaysia).",
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Got it", style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
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
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A35).withOpacity(0.9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20, right: 20, top: 20,
          ),
          child: StatefulBuilder(
            builder: (context, setSheetState) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.white54))),
                    const Text("Post Moment", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
                    _isUploading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyanAccent))
                        : TextButton(
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
                      child: const Text("Post", style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                TextField(
                  controller: _postController,
                  maxLines: 4,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(hintText: "What's new with your business?", hintStyle: TextStyle(color: Colors.white24), border: InputBorder.none),
                ),
                if (_selectedImages.isNotEmpty)
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedImages.length,
                      itemBuilder: (context, i) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(_selectedImages[i], width: 100, height: 100, fit: BoxFit.cover),
                            ),
                            Positioned(right: 0, child: GestureDetector(onTap: () => setSheetState(() => _selectedImages.removeAt(i)), child: const CircleAvatar(radius: 10, backgroundColor: Colors.red, child: Icon(Icons.close, size: 12, color: Colors.white)))),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 15),
                IconButton(icon: const Icon(LucideIcons.image, color: Colors.cyanAccent, size: 30), onPressed: () => _pickImages(setSheetState)),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentBusinessData == null) return const Scaffold(backgroundColor: Color(0xFF0F0C29), body: Center(child: CircularProgressIndicator(color: Colors.cyanAccent)));

    final String businessName = _currentBusinessData!['business_name']?.toString() ?? "Business";
    final String businessId = _currentBusinessData!['id']?.toString() ?? "N/A";

    return Scaffold(
      backgroundColor: const Color(0xFF0F0C29),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(businessName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(LucideIcons.moreVertical, color: Colors.white),
            color: const Color(0xFF1A1A35),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: Colors.white10)),
            onSelected: (value) => value == 'logout' ? _handleLogout() : null,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'logout', child: Row(children: [Icon(Icons.logout, color: Colors.redAccent, size: 18), SizedBox(width: 10), Text("Logout", style: TextStyle(color: Colors.redAccent))])),
            ],
          )
        ],
      ),
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)]),
        ),
        child: RefreshIndicator(
          onRefresh: () async { await _fetchProfile(); await _fetchPosts(); },
          color: Colors.cyanAccent,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildModernHeader(businessName, businessId),
                _buildMomentsSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader(String name, String id) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            _buildBusinessAvatar(name, id),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.1))),
                child: Column(
                  children: [
                    _buildInfoRow(LucideIcons.mapPin, _currentBusinessData!['address'] ?? "No address"),
                    const SizedBox(height: 10),
                    _buildInfoRow(LucideIcons.clock, _currentBusinessData!['hours'] ?? "No hours set"),
                    const SizedBox(height: 10),
                    _buildInfoRow(LucideIcons.phone, _currentBusinessData!['phone'] ?? "No contact"),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildStatsAndEditRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessAvatar(String name, String id) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [Colors.cyanAccent, Colors.purpleAccent]), boxShadow: [BoxShadow(color: Colors.cyanAccent.withOpacity(0.3), blurRadius: 15)]),
            child: const CircleAvatar(radius: 40, backgroundColor: Color(0xFF1A1A35), child: Icon(LucideIcons.store, size: 40, color: Colors.white70)),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Flexible(child: Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, overflow: TextOverflow.ellipsis))),
                  const SizedBox(width: 8),
                  GestureDetector(onTap: () => _showSSMDialog(context), child: const Icon(Icons.verified, size: 18, color: Colors.greenAccent)),
                ]),
                Text("ID: $id", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.cyanAccent),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13))),
      ],
    );
  }

  Widget _buildStatsAndEditRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_posts.length.toString(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            Text("Moments", style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5))),
          ]),
          ElevatedButton(
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (context) => BusinessEditProfilePage(businessData: _currentBusinessData!)));
              _fetchProfile();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.05),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.white.withOpacity(0.2))),
            ),
            child: const Text("Edit Business", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildMomentsSection() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(25, 25, 25, 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("TIMELINE", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 12, color: Colors.white54)),
              GestureDetector(
                onTap: _showCreatePostSheet,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), gradient: const LinearGradient(colors: [Colors.cyanAccent, Colors.blueAccent])),
                  child: const Row(children: [Icon(Icons.add, size: 16, color: Color(0xFF0F0C29)), SizedBox(width: 4), Text("NEW", style: TextStyle(color: Color(0xFF0F0C29), fontWeight: FontWeight.bold, fontSize: 11))]),
                ),
              ),
            ],
          ),
        ),
        if (_isLoadingPosts)
          const Padding(padding: EdgeInsets.all(50), child: CircularProgressIndicator(color: Colors.cyanAccent))
        else if (_posts.isEmpty)
          Padding(padding: const EdgeInsets.all(80), child: Text("No moments shared yet.", style: TextStyle(color: Colors.white.withOpacity(0.2))))
        else
          _buildPostList(),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildPostList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        final post = _posts[index];
        final List<dynamic> imageUrls = post['image_urls'] ?? [];

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.05))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (post['text'] != null && post['text'].toString().isNotEmpty)
                Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(post['text'], style: const TextStyle(color: Colors.white, fontSize: 15))),
              if (imageUrls.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: imageUrls.length == 1
                      ? Image.network(imageUrls[0], fit: BoxFit.cover, width: double.infinity)
                      : SizedBox(
                    height: 180,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: imageUrls.length,
                      itemBuilder: (context, i) => Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(imageUrls[i], width: 250, fit: BoxFit.cover)),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              const Text("Shared recently", style: TextStyle(color: Colors.white24, fontSize: 11)),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleLogout() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginPage()), (route) => false);
  }
}