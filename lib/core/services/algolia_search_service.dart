// lib/core/services/algolia_search_service.dart
import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:mymink/core/models/search_index.dart';

/// Generic callable → JSON decode → typed list
Future<List<T>> algoliaSearch<T>({
  required String searchText,
  required SearchIndex indexName,
  required T Function(Map<String, dynamic>) fromJson,
  String filters = '',
  String region = 'us-central1', // change if your function is elsewhere
}) async {
  try {
    final functions = FirebaseFunctions.instanceFor(region: region);
    final callable = functions.httpsCallable('searchByAlgolia');
    print(indexName.rawValue);
    final res = await callable.call(<String, dynamic>{
      'searchText': searchText,
      'indexName': indexName.rawValue,
      'filters': filters,
    });

    final data = res.data;

    // Your function returns a JSON string; be robust to other shapes too.
    List<dynamic> list;
    if (data is String) {
      final decoded = jsonDecode(data);
      if (decoded is List) {
        list = decoded;
      } else if (decoded is Map && decoded['hits'] is List) {
        list = decoded['hits'];
      } else {
        throw const FormatException('Unexpected JSON envelope (string).');
      }
    } else if (data is List) {
      list = data;
    } else if (data is Map && data['data'] is List) {
      list = data['data'];
    } else if (data is Map && data['hits'] is List) {
      list = data['hits'];
    } else {
      throw FormatException('Unexpected payload: ${data.runtimeType}');
    }

    return list
        .map((e) => fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  } on FirebaseFunctionsException catch (_) {
    // You can route this to Sentry/Crashlytics if needed
    // debugPrint('CF error: ${e.code} ${e.message}');
    return <T>[]; // or rethrow if you prefer handling upstream
  } catch (_) {
    return <T>[];
  }
}
