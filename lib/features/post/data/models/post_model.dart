import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mymink/features/onboarding/data/models/user_model.dart';

class PostModel {
  String? postID;
  DateTime? postCreateDate;
  String? postType;
  List<String>? postImages;
  List<double>? postImagesOrientations;
  String? postVideo;
  double? postVideoRatio;
  String? videoImage;
  String? caption;
  int? likes;
  int? comment;
  int? shares;
  String? uid;
  String? bid;
  String? notificationToken;
  UserModel? userModel;
  bool? isLiveStream;
  int? watchCount;
  bool? isActive;
  String? shareURL;
  bool? isPromoted;
  String? enCaption;

  PostModel({
    this.postID,
    this.postCreateDate,
    this.postType,
    this.postImages,
    this.postImagesOrientations,
    this.postVideo,
    this.postVideoRatio,
    this.videoImage,
    this.caption,
    this.likes,
    this.comment,
    this.shares,
    this.uid,
    this.bid,
    this.notificationToken,
    this.isLiveStream,
    this.watchCount,
    this.isActive,
    this.shareURL,
    this.isPromoted,
    this.enCaption,
  });

  Map<String, dynamic> toJson() {
    return {
      'postID': postID,
      'postCreateDate': postCreateDate, // Firestore handles DateTime→Timestamp
      'postType': postType,
      'postImages': postImages,
      'postImagesOrientations': postImagesOrientations,
      'postVideo': postVideo,
      'postVideoRatio': postVideoRatio,
      'videoImage': videoImage,
      'caption': caption,
      'likes': likes,
      'comment': comment,
      'shares': shares,
      'uid': uid,
      'bid': bid,
      'notificationToken': notificationToken,
      'isLiveStream': isLiveStream,
      'watchCount': watchCount,
      'isActive': isActive,
      'shareURL': shareURL,
      'isPromoted': isPromoted,
      'enCaption': enCaption,
    };
  }

  // ----- helpers -----
  static DateTime? _toDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is Timestamp) return v.toDate();
    if (v is num) return DateTime.fromMillisecondsSinceEpoch(v.toInt());
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  static List<double>? _toDoubleList(dynamic v) {
    if (v is List) {
      return v.map((e) => (e as num).toDouble()).toList();
    }
    return null;
  }

  static List<String>? _toStringList(dynamic v) {
    if (v is List) {
      return v.map((e) => e.toString()).toList();
    }
    return null;
  }

  factory PostModel.fromJson(Map<String, dynamic> map) {
    return PostModel(
      postID: map['postID'] as String?,
      postCreateDate: _toDate(map['postCreateDate']),
      postType: map['postType'] as String?,
      postImages: _toStringList(map['postImages']),
      postImagesOrientations: _toDoubleList(map['postImagesOrientations']),
      postVideo: map['postVideo'] as String?,
      postVideoRatio: (map['postVideoRatio'] is num)
          ? (map['postVideoRatio'] as num).toDouble()
          : null,
      videoImage: map['videoImage'] as String?,
      caption: map['caption'] as String?,
      likes: (map['likes'] as num?)?.toInt(),
      comment: (map['comment'] as num?)?.toInt(),
      shares: (map['shares'] as num?)?.toInt(),
      uid: map['uid'] as String?,
      bid: map['bid'] as String?,
      notificationToken: map['notificationToken'] as String?,
      isLiveStream: map['isLiveStream'] as bool?,
      watchCount: (map['watchCount'] as num?)?.toInt(),
      isActive: map['isActive'] as bool?,
      shareURL: map['shareURL'] as String?,
      isPromoted: map['isPromoted'] as bool?,
      enCaption: map['enCaption'] as String?,
    );
  }
}
