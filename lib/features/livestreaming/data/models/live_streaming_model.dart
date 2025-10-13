import 'package:cloud_firestore/cloud_firestore.dart';

class LiveStreamingModel {
  final String uid;
  final String fullName;
  final String profilePic;
  final DateTime date;
  final String token;
  final bool isOnline;
  final int agoraUID;
  final int count;
  final int likeCount;

  LiveStreamingModel({
    required this.uid,
    required this.fullName,
    required this.profilePic,
    required this.date,
    required this.token,
    required this.isOnline,
    required this.agoraUID,
    required this.count,
    required this.likeCount,
  });

  factory LiveStreamingModel.fromMap(Map<String, dynamic> map) {
    return LiveStreamingModel(
      uid: map['uid'] as String? ?? '',
      fullName: map['fullName'] as String? ?? '',
      profilePic: map['profilePic'] as String? ?? '',
      date: (map['date'] as Timestamp).toDate(),
      token: map['token'] as String? ?? '',
      isOnline: map['isOnline'] as bool? ?? false,
      agoraUID: map['agoraUID'] as int? ?? 0,
      count: map['count'] as int? ?? 0,
      likeCount: map['likeCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'profilePic': profilePic,
      'date': Timestamp.fromDate(date),
      'token': token,
      'isOnline': isOnline,
      'agoraUID': agoraUID,
      'count': count,
      'likeCount': likeCount,
    };
  }
}
