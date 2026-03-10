import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart'; // REQUIRED
import 'package:recommended_restaurant_entertainment/userModule/feedback.dart';
import 'package:recommended_restaurant_entertainment/customer_service/nomi_chat_screen.dart';
import '../language_provider.dart'; // REQUIRED

class HelpCenterPage extends StatelessWidget {
  final Map<String, dynamic> userData;
  const HelpCenterPage({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    // Access language provider
    final lp = Provider.of<LanguageProvider>(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF0F0C29),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          lp.getString('help'), // TRANSLATED TITLE
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(lp.getString('support')), // TRANSLATED HEADER
                const SizedBox(height: 12),
                _buildSectionCard([
                  _buildSupportItem(
                    title: lp.getString('chat_nomi'), // TRANSLATED ITEM
                    icon: LucideIcons.bot,
                    context: context,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ChatNomiPage(userData: userData)),
                    ),
                  ),
                  Divider(height: 1, color: Colors.white.withOpacity(0.1), indent: 16, endIndent: 16),
                  _buildSupportItem(
                    title: lp.getString('feedback'), // TRANSLATED ITEM
                    icon: LucideIcons.messageSquare,
                    context: context,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => FeedbackPage(userData: userData)),
                    ),
                  ),
                ]),
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
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              color: Colors.cyanAccent,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: Colors.cyanAccent.withOpacity(0.5), blurRadius: 6)],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(children: children),
        ),
      ),
    );
  }

  Widget _buildSupportItem({
    required String title,
    required IconData icon,
    required BuildContext context,
    required VoidCallback onTap
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      title: Text(
          title,
          style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w500)
      ),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.cyanAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: Colors.cyanAccent),
      ),
      trailing: const Icon(LucideIcons.chevronRight, size: 18, color: Colors.white24),
      onTap: onTap,
    );
  }
}