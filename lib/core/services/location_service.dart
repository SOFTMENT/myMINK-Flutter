// lib/services/location_service.dart

import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class LocationService {
  final String googleAPIKey = dotenv.env['GOOGLE_API_KEY'] ?? '';

  // Fetch location suggestions from Google Places API
  Future<List<dynamic>> fetchSuggestions(String query) async {
    if (query.isEmpty) return [];

    final String url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query&key=$googleAPIKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      return data['predictions'];
    } else {
      throw Exception('Failed to load suggestions');
    }
  }
}
