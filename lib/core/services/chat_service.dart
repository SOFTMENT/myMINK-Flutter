import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mymink/features/globalchat/data/models/global_chat_model.dart';
import 'package:mymink/features/onboarding/data/models/user_model.dart';

class ChatServiceHelper {
  /// Sends a new message to a Firestore collection.
  static Future<void> sendMessageToCollection({
    required String collectionPath,
    required String message,
  }) async {
    if (message.trim().isEmpty) return;

    final user = UserModel.instance;

    final docRef = FirebaseFirestore.instance.collection(collectionPath).doc();

    final newMessage = GlobalChatMessage(
      id: docRef.id, // ✅ use the auto-generated ID
      uid: user.uid!,
      content: message.trim(),
      timestamp: DateTime.now(),
    );

    await docRef.set(newMessage.toMap());
  }
}
