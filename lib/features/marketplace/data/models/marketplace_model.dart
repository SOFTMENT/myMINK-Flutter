import 'package:cloud_firestore/cloud_firestore.dart';

class MarketplaceModel {
  final String id;
  final String uid;
  final String title;
  final String cost;
  final String about;
  final String categoryName;
  String productUrl;
  final DateTime dateCreated;
  final bool isActive;
  final String countryCode;

  List<String> productImages;

  MarketplaceModel({
    required this.id,
    required this.uid,
    required this.title,
    required this.cost,
    required this.about,
    required this.categoryName,
    this.productUrl = '',
    required this.dateCreated,
    this.isActive = true,
    this.countryCode = 'AU',
    this.productImages = const [],
  });

  MarketplaceModel copyWith({
    String? id,
    String? uid,
    String? title,
    String? cost,
    String? about,
    String? categoryName,
    String? productUrl,
    DateTime? dateCreated,
    bool? isActive,
    String? countryCode,
    List<String>? productImages,
  }) {
    return MarketplaceModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      title: title ?? this.title,
      cost: cost ?? this.cost,
      about: about ?? this.about,
      categoryName: categoryName ?? this.categoryName,
      productUrl: productUrl ?? this.productUrl,
      dateCreated: dateCreated ?? this.dateCreated,
      isActive: isActive ?? this.isActive,
      productImages: productImages ?? this.productImages,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'uid': uid,
        'title': title,
        'cost': cost,
        'about': about,
        'countryCode': countryCode,
        'categoryName': categoryName,
        'productUrl': productUrl,
        'dateCreated': Timestamp.fromDate(dateCreated),
        'isActive': isActive,
        'productImages': productImages,
      };

  factory MarketplaceModel.fromJson(Map<String, dynamic> json) {
    return MarketplaceModel(
      id: (json['id'] ?? '') as String,
      uid: (json['uid'] ?? '') as String,
      title: (json['title'] ?? '') as String,
      cost: (json['cost'] ?? '') as String,
      countryCode: (json['countryCode'] ?? '') as String,
      about: (json['about'] ?? '') as String,
      categoryName: (json['categoryName'] ?? '') as String,
      productUrl: (json['productUrl'] ?? '') as String,
      dateCreated: _toDateTime(json['dateCreated']) ?? DateTime.now(),
      isActive: (json['isActive'] as bool?) ?? true,
      productImages: (json['productImages'] is List)
          ? List<String>.from(json['productImages'])
          : const <String>[],
    );
  }

  factory MarketplaceModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    data['id'] ??= doc.id;
    return MarketplaceModel.fromJson(data);
  }
}

DateTime? _toDateTime(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is String) return DateTime.tryParse(value);
  return null;
}
