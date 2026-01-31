import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'chatbot.dart';
import 'feedback.dart';

class help_center extends StatelessWidget {
  const help_center({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Help Center', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- Section 1: FAQ Questions ---
            _buildSectionHeader("Guess what you want to ask"),
            _buildListContainer([
              _buildHelpItem(context, "How to chat?"),
              _buildHelpItem(context, "How to follow user?"),
              _buildHelpItem(context, "How to edit my profile?"),
            ]),

            // --- Section 2: Support ---
            _buildSectionHeader("Support"),
            _buildListContainer([
              _buildHelpItem(
                context,
                "Chat with Nomi",
                trailingIcon: LucideIcons.messageCircle,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const chatbot())),
              ),
              _buildHelpItem(
                context,
                "Feedback",
                // Ensure FeedbackPage matches the class name in your feedback.dart file
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FeedbackPage())),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  // --- Helper Methods (Keep these inside the class but outside the build method) ---

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
    );
  }

  Widget _buildListContainer(List<Widget> items) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(children: items),
    );
  }

  Widget _buildHelpItem(BuildContext context, String title, {IconData? trailingIcon, VoidCallback? onTap}) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontSize: 16)),
      trailing: Icon(trailingIcon ?? Icons.arrow_forward_ios, size: 16, color: Colors.black),
      onTap: onTap,
    );
  }
}