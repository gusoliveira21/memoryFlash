import 'dart:convert';
import 'package:http/http.dart' as http;

class FeedbackRemoteDataSource {
  final String _gistUrl = "https://gist.githubusercontent.com/gusoliveira21/1869fec0dbfc0958ed0ef7dfcfb9cd1d/raw/features_feedbacks_config.json";
  final String _discordWebhookUrl = "https://discord.com/api/webhooks/1536005866510225508/l9Bki7K4vSU0jquYalfPuKKhYZGV7bOI3HiXwekoz1L1JrARTdW5wIniniNK5xCS6bpt";

  Future<bool> checkFeedbackEnabled() async {
    try {
      final response = await http.get(Uri.parse(_gistUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Lendo a flag do memoryflash do JSON
        return data['com.gusoliveira21.memoryflash'] ?? false;
      } else {
        return false;
      }
    } catch (e) {
      print('Erro ao buscar gist: $e');
      return false;
    }
  }

  Future<bool> sendFeedback(String message) async {
    try {
      final formattedMessage = "[App: com.gusoliveira21.memoryflash] Sugestão:\n$message";
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
