// lib/models/live_chat_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class LiveChatModel {
  final String? profile;
  final String? name;
  final String? message;
  final String? uid;
  final DateTime? time;
  final String? id;

  LiveChatModel({
    this.profile,
    this.name,
    this.message,
    this.uid,
    this.time,
    this.id,
  });

  factory LiveChatModel.fromMap(Map<String, dynamic> map,
      {String? documentId}) {
    return LiveChatModel(
      profile: map['profile'] as String?,
      name: map['name'] as String?,
      message: map['message'] as String?,
      uid: map['uid'] as String?,
      time: map['time'] is Timestamp
          ? (map['time'] as Timestamp).toDate()
          : (map['time'] as DateTime?),
      id: documentId ?? map['id'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'profile': profile,
      'name': name,
      'message': message,
      'uid': uid,
      'time': time != null ? Timestamp.fromDate(time!) : null,
      'id': id,
    };
  }
}
