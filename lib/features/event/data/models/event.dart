// lib/features/events/models/event_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  /// Firestore doc id (maps to `eventId` on-wire for compatibility)
  final String id;

  /// Organizer uid (Swift: eventOrganizerUid)
  String eventOrganizerUid;

  /// Title (Swift: eventTitle)
  String title;

  /// Coords (Swift: latitude / longitude)
  double? latitude;
  double? longitude;

  /// Address bits (Swift: addressName, address, city, state, postal, country)
  String addressName;
  String address;

  /// Dates (Swift: eventCreateDate, eventStartDate, eventEndDate)
  final DateTime eventCreateDate;
  DateTime? startDate;

  String? ticketPrice; // keep int to match your Swift Int

  /// Country code (Swift: countryCode)
  String countryCode;

  /// Status (Swift: isActive)
  bool isActive;

  /// Description (Swift: eventDescription)
  String description;

  /// URL (Swift: eventURL)
  String eventUrl;

  /// Images. We also read/write legacy `eventImage1..4` for compatibility.
  List<String> eventImages;

  EventModel({
    required this.id,
    this.eventOrganizerUid = '',
    this.title = '',
    this.latitude,
    this.longitude,
    this.addressName = '',
    this.address = '',
    required this.eventCreateDate,
    this.startDate,
    this.ticketPrice,
    this.countryCode = '',
    this.isActive = true,
    this.description = '',
    this.eventUrl = '',
    this.eventImages = const [],
  });

  EventModel copyWith({
    String? id,
    String? organizerUid,
    String? title,
    String? tags,
    double? latitude,
    double? longitude,
    String? addressName,
    String? address,
    String? city,
    String? state,
    String? postal,
    String? country,
    DateTime? dateCreated,
    DateTime? startDate,
    DateTime? endDate,
    int? ticketSold,
    bool? isFree,
    String? ticketName,
    int? ticketQuantity,
    String? ticketPrice,
    String? countryCode,
    bool? isActive,
    String? description,
    String? eventUrl,
    List<String>? eventImages,
  }) {
    return EventModel(
      id: id ?? this.id,
      eventOrganizerUid: organizerUid ?? this.eventOrganizerUid,
      title: title ?? this.title,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      addressName: addressName ?? this.addressName,
      address: address ?? this.address,
      eventCreateDate: dateCreated ?? this.eventCreateDate,
      startDate: startDate ?? this.startDate,
      ticketPrice: ticketPrice ?? this.ticketPrice,
      countryCode: countryCode ?? this.countryCode,
      isActive: isActive ?? this.isActive,
      description: description ?? this.description,
      eventUrl: eventUrl ?? this.eventUrl,
      eventImages: eventImages ?? this.eventImages,
    );
  }

  Map<String, dynamic> toJson() {
    // Keep both modern list and legacy fields for backwards compatibility
    final Map<String, dynamic> json = {
      'eventId': id,
      'eventOrganizerUid': eventOrganizerUid,
      'eventTitle': title,
      'latitude': latitude,
      'longitude': longitude,
      'addressName': addressName,
      'address': address,
      'eventCreateDate': Timestamp.fromDate(eventCreateDate),
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'countryCode': countryCode,
      'isActive': isActive,
      'eventDescription': description,
      'ticketPrice': ticketPrice,
      'eventURL': eventUrl,
      'eventImages': eventImages,
    };

    return json;
  }

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: (json['eventId'] ?? json['id'] ?? '') as String,
      eventOrganizerUid:
          (json['eventOrganizerUid'] ?? json['uid'] ?? '') as String,
      title: (json['eventTitle'] ?? json['title'] ?? '') as String,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      addressName: (json['addressName'] ?? '') as String,
      address: (json['address'] ?? '') as String,
      eventCreateDate: _toDateTime(json['eventCreateDate']) ?? DateTime.now(),
      startDate: _toDateTime(json['startDate']),
      countryCode: (json['countryCode'] ?? '') as String,
      isActive: (json['isActive'] as bool?) ?? true,
      description:
          (json['eventDescription'] ?? json['description'] ?? '') as String,
      ticketPrice: (json['ticketPrice'] as String?),
      eventUrl: (json['eventURL'] ?? json['url'] ?? '') as String,
      eventImages: (json['eventImages'] is List)
          ? List<String>.from(json['eventImages'])
          : const <String>[],
    );
  }

  factory EventModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    // If your collection stores id as doc.id, make it available to the model
    data['eventId'] ??= doc.id;
    return EventModel.fromJson(data);
  }
}

/// Same helper you used in MarketplaceModel
DateTime? _toDateTime(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is String) return DateTime.tryParse(value);
  return null;
}
