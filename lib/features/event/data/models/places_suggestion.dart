class PlaceSuggestion {
  final String description;
  final String placeId;
  final String mainText;
  final String secondaryText;

  PlaceSuggestion({
    required this.description,
    required this.placeId,
    required this.mainText,
    required this.secondaryText,
  });

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    final sf = json['structured_formatting'] as Map<String, dynamic>?;
    return PlaceSuggestion(
      description: json['description'] as String? ?? '',
      placeId: json['place_id'] as String? ?? '',
      mainText: sf?['main_text'] as String? ?? '',
      secondaryText: sf?['secondary_text'] as String? ?? '',
    );
  }
}
