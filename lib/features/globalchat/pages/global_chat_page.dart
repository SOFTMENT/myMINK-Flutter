import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mymink/core/constants/app_routes.dart';
import 'package:mymink/core/constants/colors.dart';
import 'package:mymink/core/services/chat_service.dart';
import 'package:mymink/core/widgets/chat_bubble.dart';
import 'package:mymink/core/widgets/custom_app_bar.dart';
import 'package:mymink/features/globalchat/data/models/global_chat_model.dart';
import 'package:mymink/features/onboarding/data/models/user_model.dart';
import 'package:mymink/features/onboarding/data/services/user_service.dart';

class GlobalChatRoomPage extends StatefulWidget {
  const GlobalChatRoomPage({super.key});

  @override
  State<GlobalChatRoomPage> createState() => _GlobalChatRoomPageState();
}

class _GlobalChatRoomPageState extends State<GlobalChatRoomPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _userCache = <String, UserModel>{};
  final _chatRef = FirebaseFirestore.instance.collection('GlobalChatRoom');

  // Fetch & cache user info by UID
  Future<UserModel?> _getUser(String uid) async {
    if (_userCache.containsKey(uid)) return _userCache[uid];
    final result = await UserService.getUserByUid(uid: uid);
    if (result.hasError || result.data == null) return null;
    return _userCache[uid] = result.data!;
  }

  // Send & scroll only when user sends
  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    await ChatServiceHelper.sendMessageToCollection(
      collectionPath: 'GlobalChatRoom',
      message: text,
    );
    _controller.clear();

    // After sending, animate to bottom (offset 0 in reversed ListView)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 28),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primaryBlue,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              iconSize: 20,
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          CustomAppBar(title: 'Global Chat'),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatRef.orderBy('timestamp').snapshots(),
              builder: (ctx, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Chronological to reversed list
                final messages = snap.data!.docs
                    .map((d) => GlobalChatMessage.fromDoc(d))
                    .toList()
                    .reversed
                    .toList();

                return ListView.builder(
                  key: const PageStorageKey('globalChatList'),
                  controller: _scrollController,
                  reverse: true, // <-- flip it
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final msg = messages[i];
                    final isUser = msg.uid == UserModel.instance.uid;
                    return FutureBuilder<UserModel?>(
                      future: _getUser(msg.uid),
                      builder: (c, us) {
                        if (!us.hasData) return const SizedBox.shrink();
                        final user = us.data!;
                        return GestureDetector(
                          onTap: () {
                            if (!isUser) {
                              context.push(
                                AppRoutes.viewUserProfilePage,
                                extra: {'userModel': user},
                              );
                            }
                          },
                          child: ChatBubble(
                            content: msg.content,
                            isUser: isUser,
                            timestamp: msg.timestamp,
                            senderName: user.username,
                            profilePicUrl: user.profilePic,
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          _buildInput(),
        ],
      ),
    );
  }
}
