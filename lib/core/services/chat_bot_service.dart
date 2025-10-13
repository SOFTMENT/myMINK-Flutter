import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:mymink/core/constants/api_constants.dart';

class ChatService {
  static Future<String> getChatResponse(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConstants.openApiKey}',
        },
        body: jsonEncode({
          "model": "gpt-3.5-turbo",
          "messages": [
            {"role": "user", "content": prompt}
          ]
        }),
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['choices'][0]['message']['content'];
      } else {
        throw Exception('OpenAI Error: ${response.body}');
      }
    } catch (e) {
      print('Exception: $e');
      rethrow;
    }
  }
}
