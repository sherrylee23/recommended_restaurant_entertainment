import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class PendingApprovalPage extends StatelessWidget {
  final String status;
  final String? rejectReason;

  const PendingApprovalPage({
    super.key,
    this.status = 'pending',
    this.rejectReason,
  });

  @override
  Widget build(BuildContext context) {
    // Check if the business was rejected
    final bool isRejected = status.toLowerCase() == 'rejected';

    return Scaffold(
      backgroundColor: const Color(0xFF0F0C29),
      body: Stack(
        children: [
          // Background Gradient
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Glowing Icon (Red for Rejected, Cyan for Pending)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (isRejected ? Colors.redAccent : Colors.cyanAccent).withOpacity(0.1),
                    boxShadow: [
                      BoxShadow(
                        color: (isRejected ? Colors.redAccent : Colors.cyanAccent).withOpacity(0.1),
                        blurRadius: 40,
                        spreadRadius: 5,
                      )
                    ],
                  ),
                  child: Icon(
                      isRejected ? LucideIcons.xCircle : LucideIcons.clock,
                      size: 80,
                      color: isRejected ? Colors.redAccent : Colors.cyanAccent
                  ),
                ),
                const SizedBox(height: 40),

                // Title
                Text(
                  isRejected ? "Application Rejected" : "Account Under Review",
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 20),

                // Glassmorphic Info Box
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: isRejected
                                ? Colors.redAccent.withOpacity(0.2)
                                : Colors.white.withOpacity(0.1)
                        ),
                      ),
                      child: Text(
                        isRejected
                            ? "Unfortunately, your application was rejected.\n\nReason: ${rejectReason ?? 'Documents provided were invalid or unclear.'}"
                            : "Thank you for registering! Our team is currently verifying your SSM document. This usually takes 24-48 hours.",
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, color: Colors.white70, height: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 50),

                // Back Button
                SizedBox(
                  width: double.infinity,
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      height: 55,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isRejected
                              ? [Colors.redAccent, Colors.orangeAccent]
                              : [Colors.cyanAccent, Colors.blueAccent],
                        ),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Text(
                        "Back to Login",
                        style: TextStyle(
                          color: Color(0xFF0F0C29),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}