import 'package:flutter/material.dart';

class ReportBusinessPage extends StatelessWidget {
  const ReportBusinessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Report Business Attitude",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // --- SYSTEM BACKGROUND GRADIENT ---
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Colors.blue.shade100,
              Colors.purple.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildFormCard(
                  label: "Business Name",
                  isRequired: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Plaza Restaurant", style: TextStyle(fontSize: 16)),
                      Text("ID:13572468", style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
                    ],
                  ),
                ),
                _buildFormCard(
                  label: "Description",
                  isRequired: true,
                  child: const TextField(
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: "Enter details here...",
                      border: InputBorder.none,
                    ),
                  ),
                ),
                _buildFormCard(
                  label: "Photos and Videos",
                  isRequired: false,
                  child: Row(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.image, color: Colors.grey),
                      ),
                      const SizedBox(width: 20),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black87, width: 1.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(Icons.add_photo_alternate_outlined, size: 28),
                      ),
                    ],
                  ),
                ),
                _buildFormCard(
                  label: "Email",
                  isRequired: true,
                  child: const TextField(
                    decoration: InputDecoration(
                      hintText: "Example: abx@gmail.com",
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // --- GRADIENT SUBMIT BUTTON ---
                GestureDetector(
                  onTap: () {
                    // Handle Submit logic
                  },
                  child: Container(
                    width: double.infinity, // Set to specific width if preferred
                    height: 55,
                    decoration: BoxDecoration(
                      // Applying the Blue-to-Purple gradient from your system style
                      gradient: const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Color(0xFF8ECAFF),
                          Color(0xFF4A90E2),
                          Colors.purpleAccent,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      "Submit Feedback",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard({required String label, required bool isRequired, required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              if (isRequired)
                const Text(" *", style: TextStyle(color: Colors.red, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}