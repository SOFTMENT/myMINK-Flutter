import 'package:cloud_firestore/cloud_firestore.dart';

class GlobalChatMessage {
  final String id;
  final String uid;

  final String content;
  final DateTime timestamp;

  GlobalChatMessage({
    required this.id,
    required this.uid,
    required this.content,
    required this.timestamp,
  });

  factory GlobalChatMessage.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GlobalChatMessage(
      id: doc.id,
      uid: data['uid'] ?? '',
      content: data['content'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'content': content,
      'timestamp': timestamp,
    };
  }
}
