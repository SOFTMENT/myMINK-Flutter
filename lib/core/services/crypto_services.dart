import 'package:mymink/features/cryptocurrency/data/models/crypto_model.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CryptoServices {
  static Future<List<CryptoModel>> getAllCryptoAssets(String currency) async {
    final url = Uri.parse(
        'https://api.coingecko.com/api/v3/coins/markets?vs_currency=$currency&order=market_cap_desc&per_page=200&page=1&sparkline=false&locale=en');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => CryptoModel.fromJson(json)).toList();
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch data: $e');
    }
  }
}
