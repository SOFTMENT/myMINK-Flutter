import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  // Internal properties
  static UserModel? _userData;

  static UserModel get instance {
    _userData ??= UserModel();
    return _userData!;
  }

  static set data(UserModel? userData) {
    _userData = userData;
  }

  // Instance properties
  String? profilePic;
  String? fullName;
  String? email;
  String? uid;
  DateTime? registredAt;
  String? phoneNumber;
  String? regiType;
  String? website;
  String? location;
  String? gender;
  String? biography;
  String? username;
  String? notificationToken;
  String? encryptKey;
  String? encryptPassword;
  String? autoGraphImage;
  bool? isAccountPrivate;
  String? profileURL;
  bool? is2FAActive;
  String? phoneNumber2FA;
  String? braintreeCustomerId;
  bool? isBlocked;
  String? livestreamingURL;
  bool? isAccountDeactivate;
  bool? haveBlueTick;
  bool? haveBlackTick;
  String? activeEntitlement;
  String? entitlementStatus;
  bool? isAccountActive;
  int? daysLeft;
  DateTime? dob;

  // Constructor
  UserModel({
    this.profilePic,
    this.fullName,
    this.email,
    this.uid,
    this.registredAt,
    this.phoneNumber,
    this.regiType,
    this.website,
    this.location,
    this.gender,
    this.biography,
    this.username,
    this.notificationToken,
    this.encryptKey,
    this.encryptPassword,
    this.autoGraphImage,
    this.isAccountPrivate,
    this.profileURL,
    this.is2FAActive,
    this.phoneNumber2FA,
    this.braintreeCustomerId,
    this.isBlocked,
    this.livestreamingURL,
    this.isAccountDeactivate,
    this.haveBlueTick,
    this.haveBlackTick,
    this.activeEntitlement,
    this.entitlementStatus,
    this.isAccountActive,
    this.daysLeft,
    this.dob,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      profilePic: json['profilePic'],
      fullName: json['fullName'],
      email: json['email'],
      uid: json['uid'],
      registredAt: json['registredAt'] != null
          ? (json['registredAt'] as Timestamp).toDate()
          : null,
      phoneNumber: json['phoneNumber'],
      regiType: json['regiType'],
      website: json['website'],
      location: json['location'],
      gender: json['gender'],
      biography: json['biography'],
      username: json['username'],
      notificationToken: json['notificationToken'],
      encryptKey: json['encryptKey'],
      encryptPassword: json['encryptPassword'],
      autoGraphImage: json['autoGraphImage'],
      isAccountPrivate: json['isAccountPrivate'],
      profileURL: json['profileURL'],
      is2FAActive: json['is2FAActive'],
      phoneNumber2FA: json['phoneNumber2FA'],
      braintreeCustomerId: json['braintreeCustomerId'],
      isBlocked: json['isBlocked'],
      livestreamingURL: json['livestreamingURL'],
      isAccountDeactivate: json['isAccountDeactivate'],
      haveBlueTick: json['haveBlueTick'],
      haveBlackTick: json['haveBlackTick'],
      activeEntitlement: json['activeEntitlement'],
      entitlementStatus: json['entitlementStatus'],
      isAccountActive: json['isAccountActive'],
      daysLeft: json['daysLeft'],
      dob: json['dob'] != null ? (json['dob'] as Timestamp).toDate() : null,
    );
  }

  // ✅ toJson() method to convert UserModel to a map for saving to Firestore
  Map<String, dynamic> toJson() {
    return {
      'profilePic': profilePic,
      'fullName': fullName,
      'email': email,
      'uid': uid,
      'registredAt': registredAt,
      'phoneNumber': phoneNumber,
      'regiType': regiType,
      'website': website,
      'location': location,
      'gender': gender,
      'biography': biography,
      'username': username,
      'notificationToken': notificationToken,
      'encryptKey': encryptKey,
      'encryptPassword': encryptPassword,
      'autoGraphImage': autoGraphImage,
      'isAccountPrivate': isAccountPrivate,
      'profileURL': profileURL,
      'is2FAActive': is2FAActive,
      'phoneNumber2FA': phoneNumber2FA,
      'braintreeCustomerId': braintreeCustomerId,
      'isBlocked': isBlocked,
      'livestreamingURL': livestreamingURL,
      'isAccountDeactivate': isAccountDeactivate,
      'haveBlueTick': haveBlueTick,
      'haveBlackTick': haveBlackTick,
      'activeEntitlement': activeEntitlement,
      'entitlementStatus': entitlementStatus,
      'isAccountActive': isAccountActive,
      'daysLeft': daysLeft,
      'dob': dob,
    };
  }

  // Clear user data
  static void clearUserData() {
    _userData = null;
  }
}
