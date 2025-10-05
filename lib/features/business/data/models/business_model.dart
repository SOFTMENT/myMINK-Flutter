import 'package:cloud_firestore/cloud_firestore.dart';

class BusinessModel {
  String? businessId;
  String? uid;
  String? name;
  String? website;
  String? profilePicture;
  String? aboutBusiness;
  DateTime? createdAt;
  String? coverPicture;
  String? businessCategory;
  bool? isActive;
  String? shareLink;
  String? notificationToken;

  DateTime? lastPostDate;

  BusinessModel({
    this.businessId,
    this.uid,
    this.name,
    this.website,
    this.profilePicture,
    this.aboutBusiness,
    this.createdAt,
    this.coverPicture,
    this.businessCategory,
    this.isActive,
    this.shareLink,
    this.notificationToken,
    this.lastPostDate,
  });

  factory BusinessModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BusinessModel(
      businessId: data['businessId'],
      uid: data['uid'],
      name: data['name'],
      website: data['website'],
      profilePicture: data['profilePicture'],
      aboutBusiness: data['aboutBusiness'],
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      coverPicture: data['coverPicture'],
      businessCategory: data['businessCategory'],
      isActive: data['isActive'],
      shareLink: data['shareLink'],
      notificationToken: data['notificationToken'],
      lastPostDate: data['lastPostDate'] is Timestamp
          ? (data['lastPostDate'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'businessId': businessId,
      'uid': uid,
      'name': name,
      'website': website,
      'profilePicture': profilePicture,
      'aboutBusiness': aboutBusiness,
      'createdAt': createdAt,
      'coverPicture': coverPicture,
      'businessCategory': businessCategory,
      'isActive': isActive,
      'shareLink': shareLink,
      'notificationToken': notificationToken,
      'lastPostDate': lastPostDate,
    };
  }
}
