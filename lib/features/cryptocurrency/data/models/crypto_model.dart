class CryptoModel {
  final String name;
  final String symbol;
  final String image;
  final double currentPrice;
  final double priceChangePercentage24H;
  final int marketCapRank;
  final int marketCap;

  CryptoModel({
    required this.name,
    required this.symbol,
    required this.image,
    required this.currentPrice,
    required this.priceChangePercentage24H,
    required this.marketCapRank,
    required this.marketCap,
  });

  factory CryptoModel.fromJson(Map<String, dynamic> json) {
    return CryptoModel(
      name: json['name'] ?? '',
      symbol: json['symbol'] ?? '',
      image: json['image'] ?? '',
      currentPrice: (json['current_price'] ?? 0).toDouble(),
      priceChangePercentage24H:
          (json['price_change_percentage_24h'] ?? 0).toDouble(),
      marketCapRank: json['market_cap_rank'] ?? 0,
      marketCap: json['market_cap'] ?? 0,
    );
  }
}
