// features/chat/data/models/last_message_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class LastMessage {
  final String? senderUid;
  final bool? isRead;
  final DateTime? date;
  final String? senderImage;
  final String? senderName;
  final String? senderToken;
  final String? message;
  final String? senderDeviceToken;
  final bool? isBusiness;

  LastMessage({
    this.senderUid,
    this.isRead,
    this.date,
    this.senderImage,
    this.senderName,
    this.senderToken,
    this.message,
    this.senderDeviceToken,
    this.isBusiness,
  });

  factory LastMessage.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return LastMessage(
      senderUid: data['senderUid'],
      isRead: data['isRead'],
      date: (data['date'] is Timestamp)
          ? (data['date'] as Timestamp).toDate()
          : null,
      senderImage: data['senderImage'],
      senderName: data['senderName'],
      senderToken: data['senderToken'],
      message: data['message'],
      senderDeviceToken: data['senderDeviceToken'],
      isBusiness: data['isBusiness'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderUid': senderUid,
      'isRead': isRead,
      'date': date,
      'senderImage': senderImage,
      'senderName': senderName,
      'senderToken': senderToken,
      'message': message,
      'senderDeviceToken': senderDeviceToken,
      'isBusiness': isBusiness,
    };
  }
}
