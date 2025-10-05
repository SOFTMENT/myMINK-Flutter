// One-to-One Chat UI (Flutter Equivalent of your iOS ShowChatViewController)

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mymink/core/constants/app_routes.dart';
import 'package:mymink/core/constants/collections.dart';
import 'package:mymink/core/constants/colors.dart';
import 'package:mymink/core/services/notification_service.dart';
import 'package:mymink/core/services/permission_helper.dart';

import 'package:mymink/core/widgets/chat_bubble.dart';
import 'package:mymink/core/widgets/custom_app_bar.dart';
import 'package:mymink/core/widgets/custom_image.dart';
import 'package:mymink/core/widgets/dismiss_keyboard_ontap.dart';
import 'package:mymink/features/discussion/widgets/reply_input_bar.dart';
import 'package:mymink/features/inbox/data/models/all_message_model.dart';
import 'package:mymink/features/videocall/data/services/video_call_services.dart';
import 'package:mymink/features/onboarding/data/models/user_model.dart';
import 'package:mymink/gen/assets.gen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

class ShowInboxChatPage extends StatefulWidget {
  final UserModel friend;
  final UserModel currentUser;

  const ShowInboxChatPage({
    super.key,
    required this.friend,
    required this.currentUser,
  });

  @override
  State<ShowInboxChatPage> createState() => _ShowInboxChatPageState();
}

class _ShowInboxChatPageState extends State<ShowInboxChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final CollectionReference _chatRef;

  @override
  void initState() {
    super.initState();
    _chatRef = FirebaseFirestore.instance
        .collection(Collections.chats)
        .doc(widget.currentUser.uid)
        .collection(widget.friend.uid ?? 'frienduid');
  }

  void _sendMessage({bool isVideoCall = false}) async {
    final text = _controller.text.trim();
    if (text.isEmpty && !isVideoCall) return;

    _controller.clear();
    final messageId = _chatRef.doc().id;
    final now = FieldValue.serverTimestamp();

    final messageData = AllMessageModel(
      senderUid: widget.currentUser.uid,
      message: isVideoCall ? '*--||videocall||--*' : text,
      messageId: messageId,
      date: DateTime.now(),
    ).toMap();

    await _chatRef.doc(messageId).set(messageData);
    await FirebaseFirestore.instance
        .collection(Collections.chats)
        .doc(widget.friend.uid)
        .collection(widget.currentUser.uid ?? 'currentuid')
        .doc(messageId)
        .set(messageData);

    await FirebaseFirestore.instance
        .collection(Collections.chats)
        .doc(widget.currentUser.uid)
        .collection(Collections.lastMessage)
        .doc(widget.friend.uid)
        .set({
      'message': text,
      'senderUid': widget.friend.uid,
      'isRead': true,
      'isBusiness': false,
      'senderImage': widget.friend.profilePic,
      'senderName': widget.friend.fullName,
      'date': now,
      'senderDeviceToken': widget.friend.notificationToken
    });

    await FirebaseFirestore.instance
        .collection(Collections.chats)
        .doc(widget.friend.uid)
        .collection(Collections.lastMessage)
        .doc(widget.currentUser.uid)
        .set({
      'message': text,
      'senderUid': widget.currentUser.uid,
      'isRead': false,
      'isBusiness': false,
      'senderImage': widget.currentUser.profilePic,
      'senderName': widget.currentUser.fullName,
      'date': now,
      'senderDeviceToken': widget.currentUser.notificationToken,
    });

    if (!isVideoCall)
      NotificationService.sendPushNotification(
          fcmToken: widget.friend.notificationToken ?? 'token',
          title: widget.currentUser.fullName ?? 'Name',
          body: text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.minScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
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
            CustomAppBar(
              leadingWidget: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadiusGeometry.circular(1000),
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: CustomImage(
                          imageKey: widget.friend.profilePic,
                          width: 100,
                          height: 100),
                    ),
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  Text(
                    widget.friend.fullName ?? '',
                    style: const TextStyle(
                        color: Colors.black,
                        fontSize: 17,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              title: '',
              gestureDetector: VideoCallService.agoraToken == null
                  ? null
                  : GestureDetector(
                      child:
                          Assets.images.videocall.image(width: 40, height: 40),
                      onTap: () async {
                        final granted =
                            await PermissionHelper.requestPermissions(
                          context: context,
                          permissions: [
                            Permission.camera,
                            Permission.microphone
                          ],
                          rationaleTitle: 'Camera & Microphone',
                          rationaleMessage:
                              'We need access to your camera and microphone to start a video call.',
                        );

                        if (!granted) return;

                        NotificationService.sendCallNotification(
                            fcmToken:
                                widget.friend.notificationToken ?? 'token',
                            agoraToken: VideoCallService.agoraToken ?? '',
                            channelName: VideoCallService.channelName,
                            callerName: widget.currentUser.fullName ?? 'Name',
                            callId: const Uuid().v4().toString());

                        _sendMessage(isVideoCall: true);

                        context.push(AppRoutes.videoCallPage, extra: {
                          'channelName': VideoCallService.channelName,
                          'token': VideoCallService.agoraToken,
                          'isCaller': true,
                          'calleModel': widget.friend
                        });
                      },
                    ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _chatRef.orderBy('date', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final messages = snapshot.data!.docs
                      .map((doc) => AllMessageModel.fromDoc(doc))
                      .toList();

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isMe = msg.senderUid == widget.currentUser.uid;

                      return ChatBubble(
                        content: msg.message ?? '',
                        isUser: isMe,
                        showSenderName: false,
                        timestamp: msg.date ?? new DateTime.now(),
                        senderName: isMe
                            ? widget.currentUser.fullName
                            : widget.friend.fullName,
                        profilePicUrl: isMe
                            ? widget.currentUser.profilePic
                            : widget.friend.profilePic,
                      );
                    },
                  );
                },
              ),
            ),
            ReplyInputBar(
                replyController: _controller,
                postReply: _sendMessage,
                hint: 'Write your message...')
          ],
        ),
      ),
    );
  }
}
