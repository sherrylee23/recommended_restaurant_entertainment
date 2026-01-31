import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
// import 'package:recommended_restaurant_entertainment/profile.dart'; // Import if needed elsewhere

class DiscoverPage extends StatelessWidget {
  const DiscoverPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Changed from grey[100] to match your style

      // ===== AppBar with Teammate's Gradient Design =====
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Discover',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        // --- The Gradient Header ---
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.shade100,
                Colors.purple.shade50,
              ],
            ),
          ),
        ),
        actions: [
          // Keeping your Search and Filter functions
          IconButton(
            icon: const Icon(LucideIcons.search, color: Colors.black),
            onPressed: () {},
          ),
          PopupMenuButton<String>(
            icon: const Icon(LucideIcons.menu, color: Colors.black),
            onSelected: (value) {
              if (value == 'filter') {
                _showFilterBottomSheet(context);
              } else if (value == 'logout') {
                print("User logged out");
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'filter',
                child: Row(
                  children: [
                    Icon(LucideIcons.sliders, size: 18, color: Colors.black),
                    SizedBox(width: 10),
                    Text('Filter & Sort'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(LucideIcons.logOut, size: 18, color: Colors.red),
                    SizedBox(width: 10),
                    Text('Logout', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),

      // ===== Body: Untouched Grid Logic =====
      body: GridView.builder(
        padding: const EdgeInsets.all(10),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.65,
        ),
        itemCount: 10,
        itemBuilder: (context, index) {
          return _discoverCard();
        },
      ),
    );
  }

  // ===== Discover Card: Pattern updated to Lucide Icons =====
  Widget _discoverCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.network(
              "https://picsum.photos/300/400?sig=${DateTime.now().millisecond}",
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 6),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              "Delicious food",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: const [
                CircleAvatar(
                  radius: 10,
                  backgroundImage: NetworkImage("https://i.pravatar.cc/100"),
                ),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "windy0303",
                    style: TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Icon pattern changed to Lucide heart
                Icon(LucideIcons.heart, size: 14, color: Colors.red),
                SizedBox(width: 2),
                Text("193", style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===== Filter Bottom Sheet: Untouched logic =====
  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Filter & Sort",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(LucideIcons.trendingUp),
                title: const Text("Most Popular"),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(LucideIcons.zap),
                title: const Text("Latest"),
                onTap: () => Navigator.pop(context),
              ),
              const Divider(),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(label: const Text("Cafe"), onSelected: (_) {}),
                  FilterChip(label: const Text("Dessert"), onSelected: (_) {}),
                  FilterChip(label: const Text("Fast Food"), onSelected: (_) {}),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}