import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart';

class NomiChatLogic {
  final Map<String, dynamic> userData;
  late final GenerativeModel _model;
  late ChatSession _chatSession;

  NomiChatLogic({required this.userData}) {
    _initializeAI();
  }

  void _initializeAI() {
    _model = GenerativeModel(
      // FIXED: Always use 'gemini-1.5-flash' for stability in Flutter
      model: 'gemini-3-flash-preview',
      apiKey: 'AIzaSyB0pr_xVmFdiHQB1ADxpKKaqQkmpzNaJDI',
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.none),
      ],
      systemInstruction: Content.system(
          "You are Nomi, a friendly AI assistant for a restaurant app. "
              "User: ${userData['username'] ?? 'Guest'}. "
              "\n\nRULES:\n"
              "1. COMMENT LIMITS: New (<14 days): 3/day, Active (14-365): 10/day, Trusted (>365): Unlimited.\n"
              "2. REPORT FORM: ONLY append '[TRIGGER_REPORT_FORM]' if the user specifically mentions "
              "reporting a restaurant, a scam, food poisoning, or explicitly asks for a report form. "
              "DO NOT trigger it for general questions about account limits or features."
              "3. HUMAN AGENT: If the user is frustrated, has a complex technical issue, "
              "or asks 'talk to a person', append '[TRIGGER_AGENT]' to your response."
      ),
    );
    _chatSession = _model.startChat();
  }

  Future<Map<String, dynamic>> sendMessage(String message) async {
    try {
      final response = await _chatSession.sendMessage(Content.text(message));
      final text = response.text ?? "I'm sorry, I couldn't process that.";

      bool needsReport = text.contains("[TRIGGER_REPORT_FORM]");
      String cleanText = text.replaceAll("[TRIGGER_REPORT_FORM]", "").trim();

      return {
        "success": true,
        "text": cleanText,
        "showAction": needsReport,
      };
    } catch (e) {
      debugPrint("Detailed Gemini Error: $e");
      return {
        "success": false,
        "text": "Connectivity error: $e",
        "showAction": false
      };
    }
  }

  // Inside nomi_chat_logic.dart

  Future<void> switchToHumanAgent() async {
    final userId = userData['id'];
    try {
      // We update the support_tickets or chat_sessions table
      // to alert the admin that a user is waiting.
      await Supabase.instance.client
          .from('support_chats')
          .upsert({
        'user_id': userId,
        'status': 'waiting_for_agent',
        'last_message_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint("Error switching to agent: $e");
    }
  }
}
