import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class VideoCallPage extends StatefulWidget {
  final String name;
  final String photoUrl;
  final String appID = '7c1109dc675e47f6b2562f2dab6581bd';
  final String chatId; // genareted token

  const VideoCallPage({
    super.key,
    required this.name,
    required this.photoUrl,
    required this.chatId,
  });

  @override
  State<VideoCallPage> createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> {
  // final AudioPlayer _player = AudioPlayer();

  late RtcEngine agoraEngine;
  int? remoteUid;
  bool localUserJoined = false;
  bool _micEnabled = true;
  bool _cameraEnabled = true;
  String engineLog = 'Initializing...';
  String callingStatus = 'Progressing...';
  String token =
      '007eJxTYDju3WDulXqNT+Oq7ZHHnWErppcvmbSh17Vh9/rzh3ujJzYrMJgnGxoaWKYkm5mbppqYp5klGZmaGaUZpSQmmZlaGCalbOVamtkQyMggXeLLwsgAgSA+O4NzYk6OS2I+AwMA+7Mg8w==';
  String channelName = 'CallDao';
  bool callProgress = true;

  @override
  void initState() {
    super.initState();
    // _player.setReleaseMode(ReleaseMode.loop);
    joinCall();
  }

  Future<void> joinCall() async {
    // final value = await CallingController().callInfoAndNotification(
    //   isVideo: true,
    //   chatID: widget.chatId,
    // );

    // if (value == null ||
    //     value['token'] == null ||
    //     value['channelName'] == null) {
    //   print("Call Info And Notification returned null");
    //   Get.back();
    //   return;
    // }

    // token = value['token'] ?? '';
    // channelName = value['channelName'] ?? '';

    print('Call Info And Notification: ');

    callProgress = false;

    await Future.delayed(const Duration(milliseconds: 100));
    setState(() {});
    await initAgora();
  }

  Future<void> stopRingtone() async {
    // await _player.stop();
  }

  Future<void> ringtone() async {
    // await _player.play(AssetSource('audio/ringtone.mp3'));
  }

  Future<void> initAgora() async {
    try {
      agoraEngine = createAgoraRtcEngine();

      await agoraEngine.initialize(
        RtcEngineContext(
          appId: widget.appID,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );

      callingStatus = 'Calling...';
      ringtone();
      setState(() {});

      agoraEngine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            setState(() {
              localUserJoined = true;
              engineLog = 'Joined channel successfully';
            });
          },
          onUserJoined: (RtcConnection connection, int rUid, int elapsed) {
            setState(() {
              remoteUid = rUid;
              engineLog = 'Remote user joined: $rUid';
              stopRingtone();
              startTimer();
            });
          },
          onUserOffline:
              (
                RtcConnection connection,
                int rUid,
                UserOfflineReasonType reason,
              ) {
                if (mounted) {
                  agoraEngine.leaveChannel();
                  Navigator.pop(context);
                }
              },
          onConnectionStateChanged:
              (
                RtcConnection connection,
                ConnectionStateType state,
                ConnectionChangedReasonType reason,
              ) {
                setState(() {
                  engineLog = 'Connection: ${state.name} - ${reason.name}';
                });
              },
          onError: (ErrorCodeType err, String msg) {
            setState(() {
              engineLog = 'Error: ${err.name} - $msg';
            });
          },
        ),
      );

      await agoraEngine.enableVideo();
      await agoraEngine.startPreview();

      setState(() {
        engineLog = 'Joining channel: ${channelName}...';
      });

      await agoraEngine.joinChannel(
        token: token,
        channelId: channelName,
        uid: 0,
        options: ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          publishMicrophoneTrack: true,
          publishCameraTrack: true,
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
        ),
      );
    } catch (e) {
      setState(() {
        engineLog = 'Error: $e';
      });
    }
  }

  RxString time = '00:00'.obs;

  Future<void> startTimer() async {
    int seconds = 0;
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      seconds++;
      final minutesStr = ((seconds ~/ 60) % 60).toString().padLeft(2, '0');
      final secondsStr = (seconds % 60).toString().padLeft(2, '0');
      time.value = '$minutesStr:$secondsStr';
      return remoteUid != null;
    });
  }

  @override
  void dispose() {
    agoraEngine.leaveChannel();
    agoraEngine.release();
    // _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          if (!callProgress)
            remoteUid != null
                ? Positioned.fill(
                    child: AgoraVideoView(
                      controller: VideoViewController(
                        rtcEngine: agoraEngine,
                        canvas: VideoCanvas(uid: remoteUid),
                      ),
                    ),
                  )
                : AgoraVideoView(
                    controller: VideoViewController(
                      rtcEngine: agoraEngine,
                      canvas: const VideoCanvas(uid: 0),
                    ),
                  ),

          if (remoteUid == null)
            Container(
              color: Colors.black12,
              width: double.maxFinite,
              height: double.maxFinite,
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 128),

                    CircleAvatar(
                      backgroundImage: NetworkImage(widget.photoUrl),
                    ),
                    SizedBox(height: 16),
                    Text(
                      widget.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 20,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      callingStatus,
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

          if (remoteUid != null && localUserJoined)
            Positioned(
              right: 16,
              top: 16,
              width: 120,
              height: 160,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: AgoraVideoView(
                  controller: VideoViewController(
                    rtcEngine: agoraEngine,
                    canvas: const VideoCanvas(uid: 0),
                  ),
                ),
              ),
            ),
          if (remoteUid == null)
            Positioned(
              bottom: 36,
              left: 0,
              right: 0,
              child: SafeArea(
                child: CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.red,
                  child: IconButton(
                    onPressed: () {
                      stopRingtone();
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.call_end, color: Colors.white),
                  ),
                ),
              ),
            ),

          if (remoteUid != null)
            Positioned(
              bottom: 130,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Obx(
                      () => Text(
                        time.value,
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          if (!_cameraEnabled)
            Positioned(
              top: 70,
              right: 50,
              child: CircleAvatar(
                radius: 24,
                backgroundColor: Colors.black26,
                child: Icon(
                  Icons.videocam_off_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),

          if (remoteUid != null && localUserJoined)
            Positioned(
              bottom: 36,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: _micEnabled
                          ? Colors.black26
                          : Colors.red,
                      child: IconButton(
                        onPressed: () async {
                          setState(() {
                            _micEnabled = !_micEnabled;
                          });
                          await agoraEngine.muteLocalAudioStream(!_micEnabled);
                        },
                        icon: Icon(
                          _micEnabled ? Icons.mic_none : Icons.mic_off_outlined,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: _cameraEnabled
                          ? Colors.black26
                          : Colors.red,
                      child: IconButton(
                        onPressed: () async {
                          setState(() {
                            _cameraEnabled = !_cameraEnabled;
                          });
                          await agoraEngine.muteLocalVideoStream(
                            !_cameraEnabled,
                          );
                        },
                        icon: Icon(
                          _cameraEnabled
                              ? Icons.videocam_outlined
                              : Icons.videocam_off_outlined,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.black26,
                      child: IconButton(
                        onPressed: () async {
                          await agoraEngine.switchCamera();
                        },
                        icon: const Icon(
                          Icons.flip_camera_ios_outlined,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.red,
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.call_end, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
