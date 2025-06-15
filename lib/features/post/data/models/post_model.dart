import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mymink/features/onboarding/data/models/user_model.dart';

class PostModel {
  String? postID;
  DateTime? postCreateDate;
  String? postType;
  List<String>? postImages;
  List<double>? postImagesOrientations; // CGFloat in Swift maps to double
  String? postVideo;
  double? postVideoRatio; // CGFloat in Swift maps to double
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

  // Constructor
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
  });

  // Convert a PostModel into a Map for Firebase or JSON
  Map<String, dynamic> toJson() {
    return {
      'postID': postID,
      'postCreateDate': postCreateDate,
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
    };
  }

  // Create a PostModel from a Map (e.g., for Firebase or JSON)
  factory PostModel.fromJson(Map<String, dynamic> map) {
    return PostModel(
      postID: map['postID'],
      postCreateDate: map['postCreateDate'] != null
          ? (map['postCreateDate'] as Timestamp).toDate()
          : null,
      postType: map['postType'],
      postImages: List<String>.from(map['postImages'] ?? []),
      postImagesOrientations:
          List<double>.from(map['postImagesOrientations'] ?? []),
      postVideo: map['postVideo'],
      postVideoRatio: map['postVideoRatio']?.toDouble(),
      videoImage: map['videoImage'],
      caption: map['caption'],
      likes: map['likes'],
      comment: map['comment'],
      shares: map['shares'],
      uid: map['uid'],
      bid: map['bid'],
      notificationToken: map['notificationToken'],
      isLiveStream: map['isLiveStream'],
      watchCount: map['watchCount'],
      isActive: map['isActive'],
      shareURL: map['shareURL'],
      isPromoted: map['isPromoted'],
    );
  }
}
