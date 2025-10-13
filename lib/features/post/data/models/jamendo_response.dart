// lib/features/post/data/models/jamendo_response.dart

import 'dart:convert';

/// Top‐level response from Jamendo `/v3.0/tracks`
class JamendoResponse {
  final List<Track> results;

  JamendoResponse({required this.results});

  factory JamendoResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['results'] as List<dynamic>?; // might be null
    final tracks = raw == null
        ? <Track>[]
        : raw.map((e) => Track.fromJson(e as Map<String, dynamic>)).toList();

    return JamendoResponse(results: tracks);
  }

  /// Parse directly from a JSON string
  static JamendoResponse parse(String jsonStr) =>
      JamendoResponse.fromJson(json.decode(jsonStr) as Map<String, dynamic>);
}

/// Represents a single track entry
class Track {
  final String id;
  final String name;
  final String artistName;
  final int duration; // in seconds
  final String audioUrl;
  final String albumImage;

  Track({
    required this.id,
    required this.name,
    required this.artistName,
    required this.duration,
    required this.audioUrl,
    required this.albumImage,
  });

  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      artistName: json['artist_name'] as String? ?? '',
      duration: int.tryParse('${json['duration']}') ?? 0,
      audioUrl: json['audio'] as String? ?? '',
      albumImage: json['album_image'] as String? ?? '',
    );
  }
}
