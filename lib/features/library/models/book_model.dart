class BookModel {
  final List<BookResult> results;

  BookModel({required this.results});

  factory BookModel.fromJson(Map<String, dynamic> json) {
    return BookModel(
      results: (json['results'] as List? ?? [])
          .map((item) => BookResult.fromJson(item))
          .toList(),
    );
  }
}

class BookResult {
  final int id;
  final String title;
  final List<Author> authors;
  final List<Author> translators;
  final List<String> subjects;
  final List<String> bookshelves;
  final List<String> languages;
  final bool? copyright;
  final String mediaType;
  final Map<String, dynamic> formats;
  final int downloadCount;

  BookResult({
    required this.id,
    required this.title,
    required this.authors,
    required this.translators,
    required this.subjects,
    required this.bookshelves,
    required this.languages,
    this.copyright,
    required this.mediaType,
    required this.formats,
    required this.downloadCount,
  });

  factory BookResult.fromJson(Map<String, dynamic> json) {
    return BookResult(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      authors: (json['authors'] as List? ?? [])
          .map((a) => Author.fromJson(a))
          .toList(),
      translators: (json['translators'] as List? ?? [])
          .map((a) => Author.fromJson(a))
          .toList(),
      subjects: List<String>.from(json['subjects'] ?? []),
      bookshelves: List<String>.from(json['bookshelves'] ?? []),
      languages: List<String>.from(json['languages'] ?? []),
      copyright: json['copyright'],
      mediaType: json['media_type'] ?? '',
      formats: Map<String, dynamic>.from(json['formats'] ?? {}),
      downloadCount: json['download_count'] ?? 0,
    );
  }
}

class Author {
  final String name;
  final int? birthYear;
  final int? deathYear;

  Author({
    required this.name,
    this.birthYear,
    this.deathYear,
  });

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      name: json['name'] ?? 'Unknown',
      birthYear: json['birth_year'],
      deathYear: json['death_year'],
    );
  }
}
