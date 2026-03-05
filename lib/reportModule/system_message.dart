import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SystemMessagePage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const SystemMessagePage({super.key, required this.userData});

  @override
  State<SystemMessagePage> createState() => _SystemMessagePageState();
}

class _SystemMessagePageState extends State<SystemMessagePage> {
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _markRead();
  }

  // --- LOGIC PRESERVED ---
  Future<void> _markRead() async {
    try {
      await supabase
          .from('system_messages')
          .update({'is_read': true})
          .eq('user_id', widget.userData['id'])
          .eq('is_read', false);
    } catch (e) {
      debugPrint("Error marking messages as read: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF0F0C29),
      appBar: AppBar(
        title: const Text(
          "System Notifications",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.white.withOpacity(0.05)),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
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
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: supabase
                .from('system_messages')
                .stream(primaryKey: ['id'])
                .eq('user_id', widget.userData['id'])
                .order('created_at', ascending: false),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.bellOff, size: 50, color: Colors.white.withOpacity(0.2)),
                      const SizedBox(height: 16),
                      Text(
                        "No notifications yet.",
                        style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 16),
                      ),
                    ],
                  ),
                );
              }

              final messages = snapshot.data!;
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                physics: const BouncingScrollPhysics(),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.blueAccent.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(LucideIcons.shieldCheck,
                                        color: Colors.blueAccent, size: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      msg['title'] ?? "Official Update",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Colors.white
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),
                              Container(
                                height: 1,
                                width: double.infinity,
                                color: Colors.white.withOpacity(0.1),
                              ),
                              const SizedBox(height: 15),
                              Text(
                                msg['content'] ?? "",
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 14,
                                    height: 1.5
                                ),
                              ),
                              const SizedBox(height: 15),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: Text(
                                  msg['created_at'] != null
                                      ? msg['created_at'].toString().substring(0, 16).replaceAll('T', ' ')
                                      : "",
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.white.withOpacity(0.3),
                                      letterSpacing: 0.5
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}