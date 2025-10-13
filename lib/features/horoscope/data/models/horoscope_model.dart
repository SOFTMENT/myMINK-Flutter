class HoroscopeModel {
  final String? aries;
  final String? taurus;
  final String? gemini;
  final String? cancer;
  final String? leo;
  final String? virgo;
  final String? libra;
  final String? scorpio;
  final String? sagittarius;
  final String? capricorn;
  final String? aquarius;
  final String? pisces;

  HoroscopeModel({
    this.aries,
    this.taurus,
    this.gemini,
    this.cancer,
    this.leo,
    this.virgo,
    this.libra,
    this.scorpio,
    this.sagittarius,
    this.capricorn,
    this.aquarius,
    this.pisces,
  });

  factory HoroscopeModel.fromJson(Map<String, dynamic> json) {
    return HoroscopeModel(
      aries: json['aries'],
      taurus: json['taurus'],
      gemini: json['gemini'],
      cancer: json['cancer'],
      leo: json['leo'],
      virgo: json['virgo'],
      libra: json['libra'],
      scorpio: json['scorpio'],
      sagittarius: json['sagittarius'],
      capricorn: json['capricorn'],
      aquarius: json['aquarius'],
      pisces: json['pisces'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'aries': aries,
      'taurus': taurus,
      'gemini': gemini,
      'cancer': cancer,
      'leo': leo,
      'virgo': virgo,
      'libra': libra,
      'scorpio': scorpio,
      'sagittarius': sagittarius,
      'capricorn': capricorn,
      'aquarius': aquarius,
      'pisces': pisces,
    };
  }
}
