// lib/features/music/data/models/music_model.dart

/// Top-level SongModel
class SongModel {
  final String? status;
  final JSONNull? message;
  final DataClass? data;

  SongModel({this.status, this.message, this.data});

  factory SongModel.fromJson(Map<String, dynamic> json) => SongModel(
        status: json['status'] as String?,
        message:
            json['message'] == null ? null : JSONNull.fromJson(json['message']),
        data: json['data'] == null
            ? null
            : DataClass.fromJson(json['data'] as Map<String, dynamic>),
      );
}

/// Data wrapper containing paging info + list of results
class DataClass {
  final int? total;
  final int? start;
  final List<Result>? results;

  DataClass({this.total, this.start, this.results});

  factory DataClass.fromJson(Map<String, dynamic> json) => DataClass(
        total: json['total'] as int?,
        start: json['start'] as int?,
        results: (json['results'] as List<dynamic>?)
            ?.map(
              (e) => Result.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
      );
}

/// Each song item
class Result {
  final String? id;
  final String? name;
  final String? type;
  final Album? album;
  final String? year;
  final JSONNull? releaseDate;
  final String? duration;
  final String? label;
  final String? primaryArtists;
  final String? primaryArtistsID;
  final String? featuredArtists;
  final String? featuredArtistsID;
  final int? explicitContent;
  final String? playCount;
  final String? language;
  final String? hasLyrics;
  final String? url;
  final String? copyright;
  final List<DownloadURL>? image;
  final List<DownloadURL>? downloadURL;

  Result({
    this.id,
    this.name,
    this.type,
    this.album,
    this.year,
    this.releaseDate,
    this.duration,
    this.label,
    this.primaryArtists,
    this.primaryArtistsID,
    this.featuredArtists,
    this.featuredArtistsID,
    this.explicitContent,
    this.playCount,
    this.language,
    this.hasLyrics,
    this.url,
    this.copyright,
    this.image,
    this.downloadURL,
  });

  factory Result.fromJson(Map<String, dynamic> json) => Result(
        id: json['id'] as String?,
        name: json['name'] as String?,
        type: json['type'] as String?,
        album: json['album'] == null
            ? null
            : Album.fromJson(json['album'] as Map<String, dynamic>),
        year: json['year'] as String?,
        releaseDate: json['releaseDate'] == null
            ? null
            : JSONNull.fromJson(json['releaseDate']),
        duration: json['duration'] as String?,
        label: json['label'] as String?,
        primaryArtists: json['primaryArtists'] as String?,
        primaryArtistsID: json['primaryArtistsId'] as String?,
        featuredArtists: json['featuredArtists'] as String?,
        featuredArtistsID: json['featuredArtistsId'] as String?,
        explicitContent: json['explicitContent'] as int?,
        playCount: json['playCount'] as String?,
        language: json['language'] as String?,
        hasLyrics: json['hasLyrics'] as String?,
        url: json['url'] as String?,
        copyright: json['copyright'] as String?,
        image: (json['image'] as List<dynamic>?)
            ?.map((e) => DownloadURL.fromJson(e as Map<String, dynamic>))
            .toList(),
        downloadURL: (json['downloadUrl'] as List<dynamic>?)
            ?.map((e) => DownloadURL.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Album info (may be null)
class Album {
  final String? id;
  final String? name;
  final String? url;

  Album({this.id, this.name, this.url});

  factory Album.fromJson(Map<String, dynamic> json) => Album(
        id: json['id'] as String?,
        name: json['name'] as String?,
        url: json['url'] as String?,
      );
}

/// Helper for both image[] and downloadUrl[] entries
class DownloadURL {
  final String? quality;
  final String? link;

  DownloadURL({this.quality, this.link});

  factory DownloadURL.fromJson(Map<String, dynamic> json) => DownloadURL(
        quality: json['quality'] as String?,
        link: json['link'] as String?,
      );
}

/// Represents explicit null in JSON
class JSONNull {
  JSONNull();

  factory JSONNull.fromJson(Object? _) => JSONNull();
}
