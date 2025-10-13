// lib/core/models/search_index.dart
enum SearchIndex {
  posts('Posts'),
  users('Users'),
  events('Events'),
  marketplace('Marketplace'),
  businesses('Businesses');

  const SearchIndex(this.rawValue);
  final String rawValue;

  /// Parse from the raw string (case-insensitive).
  static SearchIndex fromRaw(String raw) => SearchIndex.values.firstWhere(
        (e) => e.rawValue.toLowerCase() == raw.toLowerCase(),
        orElse: () => SearchIndex.posts, // choose a sensible default or throw
      );

  // Optional helpers for (de)serialization:
  String toJson() => rawValue;
  static SearchIndex fromJson(Object? json) => fromRaw(json as String);
}
