import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:mymink/core/widgets/custom_image.dart';
import 'package:mymink/features/onboarding/data/models/user_model.dart';
import 'package:mymink/features/videocall/data/services/call_kit_config.dart';

class VideoCallPage extends StatefulWidget {
  final String channelName;
  final String token;
  final bool isCaller;
  final UserModel? calleeModel;
  const VideoCallPage({
    super.key,
    required this.channelName,
    required this.token,
    this.isCaller = false,
    this.calleeModel = null,
  });

  @override
  State<VideoCallPage> createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> {
  late RtcEngine _engine;

  final List<int> _remoteUids = [];
  bool _isEngineReady = false;
  final Map<int, bool> _mutedRemoteUsers = {};
  bool _isMuted = false;
  bool _isVideoEnabled = true;
  bool _isSpeakerOn = true;

  @override
  void initState() {
    super.initState();
    _initAgora();
  }

  Future<void> _initAgora() async {
    _engine = createAgoraRtcEngine();
    await _engine.initialize(
      RtcEngineContext(appId: CallkitConfig.agoraAppId),
    );

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) async {
          print('[Agora] Local user joined: ${connection.localUid}');

          await _engine.setEnableSpeakerphone(true);
        },
        onUserJoined: (connection, remoteUid, elapsed) {
          if (!_remoteUids.contains(remoteUid)) {
            setState(() => _remoteUids.add(remoteUid));
          }
        },
        onUserOffline: (connection, remoteUid, reason) {
          setState(() => _remoteUids.remove(remoteUid));
          if (_remoteUids.isEmpty) {
            _endCall();
          }
        },
        onUserMuteVideo: (connection, remoteUid, muted) {
          print('[Agora] Remote user $remoteUid video muted: $muted');
          setState(() {
            _mutedRemoteUsers[remoteUid] = muted;
          });
        },
        onLeaveChannel: (connection, stats) {
          print('[Agora] Left channel');
        },
        onError: (err, msg) {
          print('[Agora] Error: $err - $msg');
        },
      ),
    );

    await _engine.setAudioProfile(
      profile: AudioProfileType.audioProfileDefault,
      scenario: AudioScenarioType.audioScenarioChatroom,
    );

    await _engine.enableVideo();
    await _engine.startPreview();
    await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await _engine.joinChannel(
      token: widget.token,
      channelId: widget.channelName,
      uid: 0,
      options: const ChannelMediaOptions(
        channelProfile: ChannelProfileType.channelProfileCommunication,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
    );

    setState(() {
      _isEngineReady = true;
    });
  }

  void _endCall() async {
    await FlutterCallkitIncoming.endAllCalls(); // 👈 End system call UI
    if (_isEngineReady) {
      await _engine.leaveChannel();
      await _engine.release();
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    if (_isEngineReady) {
      _engine.leaveChannel();
      _engine.release();
    }
    super.dispose();
  }

  Widget _controlButton({
    required IconData icon,
    required VoidCallback onTap,
    Color bgColor = const Color.fromARGB(121, 113, 113, 113),
    Color iconColor = Colors.white,
  }) {
    return ClipOval(
      child: Material(
        color: bgColor,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 54,
            height: 54,
            child: Icon(icon, color: iconColor),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        top: false, // ✅ Allow remote video to go behind status bar
        child: _isEngineReady
            ? Stack(
                children: [
                  // 📹 50% top - Remote user
                  Column(
                    children: [
                      Expanded(
                          flex: 1,
                          child: _remoteUids.isNotEmpty
                              ? Builder(
                                  builder: (_) {
                                    final uid = _remoteUids.first;
                                    final isMuted =
                                        _mutedRemoteUsers[uid] ?? false;

                                    if (isMuted) {
                                      return Center(
                                        child: Container(
                                          color: Colors.grey.shade900,
                                          child: const Center(
                                            child: Icon(Icons.videocam_off,
                                                color: Colors.white, size: 48),
                                          ),
                                        ),
                                      );
                                    }

                                    return AgoraVideoView(
                                      controller: VideoViewController.remote(
                                        rtcEngine: _engine,
                                        canvas: VideoCanvas(uid: uid),
                                        connection: RtcConnection(
                                            channelId: widget.channelName),
                                      ),
                                    );
                                  },
                                )
                              : widget.calleeModel != null
                                  ? Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.max,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            height: 60,
                                            width: 60,
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadiusGeometry.circular(
                                                      100),
                                              child: CustomImage(
                                                imageKey: widget
                                                    .calleeModel!.profilePic,
                                                width: 100,
                                                height: 100,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(
                                            height: 12,
                                          ),
                                          Text(
                                            widget.calleeModel!.fullName ?? '',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16),
                                          ),
                                          const SizedBox(
                                            height: 6,
                                          ),
                                          const Text(
                                            'Calling...',
                                            style: const TextStyle(
                                                color: Color.fromARGB(
                                                    191, 255, 255, 255),
                                                fontSize: 13),
                                          )
                                        ],
                                      ),
                                    )
                                  : Container()),

                      // 👤 50% bottom - Local video
                      Expanded(
                        flex: 1,
                        child: _isVideoEnabled
                            ? AgoraVideoView(
                                controller: VideoViewController(
                                  rtcEngine: _engine,
                                  canvas: const VideoCanvas(uid: 0),
                                ),
                              )
                            : Container(
                                color: Colors.grey.shade900,
                                child: const Center(
                                  child: Icon(Icons.videocam_off,
                                      color: Colors.white),
                                ),
                              ),
                      ),
                    ],
                  ),

                  // 🎛️ Call controls
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _controlButton(
                          icon: _isMuted ? Icons.mic_off : Icons.mic,
                          onTap: () {
                            setState(() => _isMuted = !_isMuted);
                            _engine.muteLocalAudioStream(_isMuted);
                          },
                        ),
                        _controlButton(
                          icon: _isVideoEnabled
                              ? Icons.videocam
                              : Icons.videocam_off,
                          onTap: () {
                            setState(() => _isVideoEnabled = !_isVideoEnabled);
                            _engine.muteLocalVideoStream(!_isVideoEnabled);
                          },
                        ),
                        _controlButton(
                          icon: Icons.call_end,
                          bgColor: Colors.red,
                          onTap: _endCall,
                        ),
                        _controlButton(
                          icon:
                              _isSpeakerOn ? Icons.volume_up : Icons.volume_off,
                          onTap: () {
                            setState(() => _isSpeakerOn = !_isSpeakerOn);
                            _engine.setEnableSpeakerphone(_isSpeakerOn);
                          },
                        ),
                        _controlButton(
                          icon: Icons.cameraswitch,
                          onTap: () => _engine.switchCamera(),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
