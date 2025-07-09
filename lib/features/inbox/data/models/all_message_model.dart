// features/chat/data/models/all_message_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class AllMessageModel {
  final String? senderUid;
  final String? message;
  final String? messageId;
  final DateTime? date;

  AllMessageModel({
    this.senderUid,
    this.message,
    this.messageId,
    this.date,
  });

  factory AllMessageModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return AllMessageModel(
      senderUid: data['senderUid'],
      message: data['message'],
      messageId: data['messageId'],
      date: (data['date'] is Timestamp)
          ? (data['date'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderUid': senderUid,
      'message': message,
      'messageId': messageId,
      'date': date,
    };
  }
}
