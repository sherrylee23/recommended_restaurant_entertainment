import 'package:flutter/material.dart';
import 'package:recommended_restaurant_entertainment/userModule/feedback.dart';
import 'package:recommended_restaurant_entertainment/customer_service/chatbot.dart';

class HelpCenterPage extends StatelessWidget {
  final Map<String, dynamic> userData;
  const HelpCenterPage({super.key, required this.userData});

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
          "Help Center",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
            child: Column( // Fixed: Restored missing Column
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                _buildSectionHeader("Support"),
                _buildSectionCard([
                  // Chat with Nomi Item
                  _buildSupportItem("Chat with Nomi", Icons.chat_bubble_outline, context),

                  const Divider(height: 1, indent: 16, endIndent: 16),

                  // Feedback Item
                  ListTile(
                    title: const Text("Feedback", style: TextStyle(fontSize: 16)),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.black54,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FeedbackPage(userData: userData),
                        ),
                      );
                    },
                  ),
                ]),

                const SizedBox(height: 24),

              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Helper Methods ---

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.grey[700],
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildSectionCard(List<Widget> children) {
    return Container(
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
      child: Column(children: children),
    );
  }

  Widget _buildHelpItem(String title, BuildContext context) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontSize: 16)),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.black54,
      ),
      onTap: () {
        // Implement FAQ navigation here if needed
      },
    );
  }

  Widget _buildSupportItem(String title, IconData icon, BuildContext context) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontSize: 16)),
      trailing: Icon(icon, size: 24, color: Colors.black87),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            // Correctly passing userData to Chatbot
            builder: (context) => ChatNomiPage(userData: userData),
          ),
        );
      },
    );
  }
}