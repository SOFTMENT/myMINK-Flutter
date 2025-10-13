import 'dart:convert';
import 'package:http/http.dart' as http;

class TranslationService {
  TranslationService._privateConstructor();
  static final TranslationService shared =
      TranslationService._privateConstructor();

  /// Translates [text] to English.
  Future<String> translateText({required String text}) async {
    const apiKey =
        "AIzaSyClxuD0JmWn1qG2QecBXuuaFzsdv-jcuMw"; // Use your API key here
    final encodedText = Uri.encodeComponent(text);
    final url =
        "https://translation.googleapis.com/language/translate/v2?target=en&q=$encodedText&key=$apiKey";

    try {
      final response = await http.post(Uri.parse(url));
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonMap = json.decode(response.body);
        // The expected JSON structure is:
        // { "data": { "translations": [ { "translatedText": "..." } ] } }
        final List<dynamic>? translations = jsonMap["data"]?["translations"];
        if (translations != null && translations.isNotEmpty) {
          return translations[0]["translatedText"] as String;
        }
      } else {
        print("Error: ${response.statusCode} ${response.body}");
      }
    } catch (e) {
      print("Exception in translateText: $e");
    }
    return "";
  }
}
