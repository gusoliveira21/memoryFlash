import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FeedbackRemoteDataSource {
  String get _discordWebhookUrl => dotenv.env['DISCORD_WEBHOOK_URL'] ?? '';
  String get _gistRawUrl => dotenv.env['GIST_RAW_URL'] ?? '';

  Future<bool> checkFeedbackEnabled() async {
    try {
      final response = await http.get(Uri.parse(_gistRawUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['com.gusoliveira21.memoryflash'] ?? false;
      } else {
        return false;
      }
    } catch (e) {
      print('Erro ao buscar gist: $e');
      return false;
    }
  }

  Future<bool> sendFeedback(String message, {String? email}) async {
    try {
      final emailInfo = (email != null && email.trim().isNotEmpty) ? email.trim() : "Não informado";
      final formattedMessage = "[App: com.gusoliveira21.memoryflash] Sugestão:\n$message\n\nEmail para contato: $emailInfo";
      
      final response = await http.post(
        Uri.parse(_discordWebhookUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'content': formattedMessage}),
      );
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print('Erro ao enviar para Discord: $e');
      return false;
    }
  }
}
