import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:mymink/features/music/data/models/music_model.dart';

class MusicService {
  static Future<List<Result>> searchSongs(String songName) async {
    final uri = Uri.parse(
      'https://my-minkm-usic.vercel.app/search/songs'
      '?query=${Uri.encodeComponent(songName)}'
      '&page=1&limit=50',
    );
    final resp = await http.get(uri);
    if (resp.statusCode != 200) {
      throw Exception('Failed to fetch songs');
    }
    final Map<String, dynamic> jsonMap = json.decode(resp.body);
    final model = SongModel.fromJson(jsonMap);
    return model.data?.results ?? [];
  }
}
