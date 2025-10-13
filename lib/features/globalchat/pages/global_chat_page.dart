import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mymink/core/constants/app_routes.dart';
import 'package:mymink/core/constants/colors.dart';
import 'package:mymink/core/services/chat_service.dart';
import 'package:mymink/core/widgets/chat_bubble.dart';
import 'package:mymink/core/widgets/custom_app_bar.dart';
import 'package:mymink/core/widgets/dismiss_keyboard_ontap.dart';
import 'package:mymink/features/discussion/widgets/reply_input_bar.dart';
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
  bool _shouldAutoScroll = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels > 300) {
        _shouldAutoScroll = false;
      }
    });
  }

  Future<UserModel?> _getUser(String uid) async {
    if (_userCache.containsKey(uid)) return _userCache[uid];
    final result = await UserService.getUserByUid(uid: uid);
    if (result.hasError || result.data == null) return null;
    return _userCache[uid] = result.data!;
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    _shouldAutoScroll = true;

    await ChatServiceHelper.sendMessageToCollection(
      collectionPath: 'GlobalChatRoom',
      message: text,
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: DismissKeyboardOnTap(
        child: Column(
          children: [
            CustomAppBar(title: 'Global Chat'),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _chatRef.orderBy('timestamp').snapshots(),
                builder: (ctx, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final rawDocs = snap.data!.docs;
                  final messages = rawDocs
                      .map((d) => GlobalChatMessage.fromDoc(d))
                      .toList()
                      .reversed
                      .toList();

                  if (_shouldAutoScroll) {
                    _scrollToBottom();
                    _shouldAutoScroll = false;
                  }

                  return ListView.builder(
                    key: const PageStorageKey('globalChatList'),
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    itemCount: messages.length,
                    itemBuilder: (context, i) {
                      final msg = messages[i];
                      final isUser = msg.uid == UserModel.instance.uid;
                      final cachedUser = _userCache[msg.uid];

                      if (cachedUser != null) {
                        return _buildChatTile(msg, cachedUser, isUser);
                      }

                      return FutureBuilder<UserModel?>(
                        future: _getUser(msg.uid),
                        builder: (c, us) {
                          if (!us.hasData) return const SizedBox.shrink();
                          final user = us.data!;
                          return _buildChatTile(msg, user, isUser);
                        },
                      );
                    },
                  );
                },
              ),
            ),
            ReplyInputBar(
              replyController: _controller,
              postReply: _sendMessage,
              hint: 'Write a reply...',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatTile(GlobalChatMessage msg, UserModel user, bool isUser) {
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
  }
}
