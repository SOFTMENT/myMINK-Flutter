import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:lottie/lottie.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mymink/core/constants/api_constants.dart';
import 'package:mymink/core/constants/collections.dart';
import 'package:mymink/core/constants/colors.dart';
import 'package:mymink/core/widgets/custom_image.dart';
import 'package:mymink/features/livestreaming/data/models/LiveChatModel.dart';
import 'package:mymink/features/livestreaming/data/models/live_streaming_model.dart';

class JoinLiveStreamPage extends StatefulWidget {
  final LiveStreamingModel liveStreamingModel;

  const JoinLiveStreamPage({
    super.key,
    required this.liveStreamingModel,
  });

  @override
  State<JoinLiveStreamPage> createState() => _JoinLiveStreamPageState();
}

class _JoinLiveStreamPageState extends State<JoinLiveStreamPage>
    with SingleTickerProviderStateMixin {
  static final String _appId = ApiConstants.agoraAppId;

  late final RtcEngine _engine;
  late final AnimationController _heartsAnim;

  bool isAdmin = false;
  bool joined = false;
  bool isMute = false;
  bool isVideoDisabled = false;
  int audienceCount = 0;
  int likeCount = 0;
  int? remoteUid;
  List<LiveChatModel> liveChatModels = [];
  final messageController = TextEditingController();

  StreamSubscription? _audienceSub;
  StreamSubscription? _chatSub;
  StreamSubscription? _likeSub;

  @override
  void initState() {
    super.initState();
    _heartsAnim = AnimationController(vsync: this);
    isAdmin =
        widget.liveStreamingModel.uid == FirebaseAuth.instance.currentUser?.uid;
    _initAgora();
    _listenFirestore();
  }

  Future<void> _initAgora() async {
    _engine = createAgoraRtcEngine();
    await _engine.initialize(RtcEngineContext(appId: _appId));

    _engine.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (connection, elapsed) {
        setState(() => joined = true);
      },
      onUserJoined: (connection, uid, elapsed) {
        setState(() => remoteUid = uid);
      },
      onUserOffline: (connection, uid, reason) {
        if (uid == widget.liveStreamingModel.agoraUID)
          Navigator.of(context).pop();
      },
    ));

    await _engine.setClientRole(
      role: isAdmin
          ? ClientRoleType.clientRoleBroadcaster
          : ClientRoleType.clientRoleAudience,
    );

    await _engine.enableVideo();
    if (isAdmin) await _engine.startPreview();

    await _engine.joinChannel(
      token: widget.liveStreamingModel.token,
      channelId: widget.liveStreamingModel.uid,
      uid: 0,
      options: const ChannelMediaOptions(),
    );
  }

  void _listenFirestore() {
    _audienceSub = FirebaseFirestore.instance
        .collection(Collections.liveStreamings)
        .doc(widget.liveStreamingModel.uid)
        .collection(Collections.audiences)
        .snapshots()
        .listen((snap) {
      setState(() => audienceCount = snap.docs.length);
    });

    _chatSub = FirebaseFirestore.instance
        .collection(Collections.liveStreamings)
        .doc(widget.liveStreamingModel.uid)
        .collection(Collections.chats)
        .orderBy('time', descending: true)
        .limit(50)
        .snapshots()
        .listen((snap) {
      liveChatModels = snap.docs
          .map((d) => LiveChatModel.fromMap(d.data(), documentId: d.id))
          .toList();
      setState(() {});
    });

    if (isAdmin) {
      _likeSub = FirebaseFirestore.instance
          .collection(Collections.liveStreamings)
          .doc(widget.liveStreamingModel.uid)
          .snapshots()
          .listen((doc) {
        final newCount = doc.data()?['likeCount'] as int? ?? 0;
        if (newCount != likeCount) {
          likeCount = newCount;
          _heartsAnim..forward(from: 0);
        }
      });
    }
  }

  @override
  void dispose() {
    _audienceSub?.cancel();
    _chatSub?.cancel();
    _likeSub?.cancel();
    messageController.dispose();
    _engine.leaveChannel();
    _engine.release();
    _heartsAnim.dispose();
    super.dispose();
  }

  void _toggleMute() {
    isMute = !isMute;
    _engine.muteLocalAudioStream(isMute);
    setState(() {});
  }

  void _toggleVideo() {
    isVideoDisabled = !isVideoDisabled;
    isVideoDisabled ? _engine.disableVideo() : _engine.enableVideo();
    setState(() {});
  }

  void _switchCamera() => _engine.switchCamera();

  void _sendMessage() {
    final txt = messageController.text.trim();
    if (txt.isEmpty) return;
    messageController.clear();
    FirebaseFirestore.instance
        .collection(Collections.liveStreamings)
        .doc(widget.liveStreamingModel.uid)
        .collection(Collections.chats)
        .add({
      'time': FieldValue.serverTimestamp(),
      'message': txt,
      'name': widget.liveStreamingModel.fullName,
      'profile': widget.liveStreamingModel.profilePic,
    });
  }

  void _sendLike() {
    if (!isAdmin) {
      _heartsAnim..forward(from: 0);
    }

    FirebaseFirestore.instance
        .collection(Collections.liveStreamings)
        .doc(widget.liveStreamingModel.uid)
        .update({'likeCount': FieldValue.increment(1)});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(children: [
          // Video Area
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: isAdmin
                  ? AgoraVideoView(
                      controller: VideoViewController(
                        rtcEngine: _engine,
                        canvas: const VideoCanvas(uid: 0),
                      ),
                    )
                  : (remoteUid != null
                      ? AgoraVideoView(
                          controller: VideoViewController.remote(
                            rtcEngine: _engine,
                            canvas: VideoCanvas(uid: remoteUid!),
                            connection: RtcConnection(
                                channelId: widget.liveStreamingModel.uid),
                          ),
                        )
                      : Container(color: Colors.grey[900])),
            ),
          ),

          // Top bar
          Positioned(
            top: 8,
            left: 8,
            right: 8,
            child: Row(children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: 8),
              ClipRRect(
                borderRadius: BorderRadiusGeometry.circular(100),
                child: CustomImage(
                    imageKey: widget.liveStreamingModel.profilePic,
                    width: 44,
                    height: 44),
              ),
              const SizedBox(width: 8),
              Text(widget.liveStreamingModel.fullName,
                  style: const TextStyle(color: Colors.white, fontSize: 17)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4)),
                child: Row(children: [
                  const Icon(Icons.remove_red_eye,
                      size: 14, color: Colors.white),
                  const SizedBox(width: 4),
                  Text('$audienceCount',
                      style:
                          const TextStyle(color: Colors.white, fontSize: 12)),
                ]),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: const Color(0xFFE91E63),
                    borderRadius: BorderRadius.circular(4)),
                child: const Text('LIVE',
                    style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ]),
          ),

          // Right-side controls
          Positioned(
            top: 80,
            right: 8,
            child: Column(children: [
              IconButton(
                  onPressed: _toggleMute,
                  icon: Icon(isMute ? Symbols.mic_off : Symbols.mic,
                      size: 32, color: Colors.white)),
              IconButton(
                  onPressed: _toggleVideo,
                  icon: Icon(
                      isVideoDisabled
                          ? Symbols.videocam_off_rounded
                          : Symbols.videocam_rounded,
                      size: 28,
                      color: Colors.white)),
              IconButton(
                  onPressed: _switchCamera,
                  icon: const Icon(
                    Icons.cached,
                    color: Colors.white,
                    size: 32,
                  )),
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.photo_filter,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ]),
          ),

          // Hearts Lottie (centered)
          Positioned(
            bottom: 0,
            right: 0,
            child: SizedBox(
              width: 160,
              height: 300,
              child: Lottie.asset(
                'assets/animations/hearts.json',
                controller: _heartsAnim,
                onLoaded: (comp) {
                  _heartsAnim
                    ..duration = comp.duration
                    ..forward(from: 0);
                },
              ),
            ),
          ),

          // Chat list
          Positioned(
            left: 0,
            right: 0,
            bottom: 60,
            height: 200,
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: liveChatModels.length,
              itemBuilder: (ctx, i) {
                final msg = liveChatModels[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(children: [
                    CustomImage(imageKey: msg.profile, width: 30, height: 30),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text.rich(
                        TextSpan(children: [
                          TextSpan(
                              text: '${msg.name}: ',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          TextSpan(
                              text: msg.message,
                              style: const TextStyle(color: Colors.white)),
                        ]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ]),
                );
              },
            ),
          ),

          // Message input + send + heart
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: Colors.black87,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(children: [
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                        color: const Color.fromARGB(39, 255, 255, 255),
                        borderRadius: BorderRadius.circular(8)),
                    child: Padding(
                      padding: const EdgeInsets.only(
                          left: 12, right: 12, bottom: 10),
                      child: TextField(
                        textCapitalization: TextCapitalization.sentences,
                        controller: messageController,
                        style: const TextStyle(
                            color: Color.fromARGB(255, 255, 255, 255)),
                        decoration: const InputDecoration(
                            hintText: 'Message...',
                            hintStyle: TextStyle(
                                color: Color.fromARGB(137, 255, 255, 255)),
                            border: InputBorder.none),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(
                    Icons.send,
                    color: AppColors.white,
                    size: 32,
                  ),
                ),
                IconButton(
                  onPressed: _sendLike,
                  icon: const Icon(
                    Icons.favorite,
                    color: AppColors.primaryRed,
                    size: 32,
                  ),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}
