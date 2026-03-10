import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/services/socket/socket_service.dart';

class VideoCallPage extends StatefulWidget {
  final String name;
  final String photoUrl;
  final String appID = '7c1109dc675e47f6b2562f2dab6581bd';
  final String chatId;
  final String channelName;
  final String token;
  final int uuid;
  final String callId;

  const VideoCallPage({
    super.key,
    required this.name,
    required this.photoUrl,
    required this.chatId,
    required this.channelName,
    required this.token,
    required this.uuid,
    required this.callId,
  });

  @override
  State<VideoCallPage> createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> {
  late RtcEngine agoraEngine;
  int? remoteUid;
  bool localUserJoined = false;
  bool _micEnabled = true;
  bool _cameraEnabled = true;
  String engineLog = 'Initializing...';
  String callingStatus = 'Calling...';
  bool callProgress = true;
  bool _isLeavingCall = false;

  // ✅ Call শুরুর সময় track করবে
  DateTime? _callStartTime;

  SocketService socketService = Get.find<SocketService>();

  Worker? _declinedWorker;
  Worker? _endedWorker;

  @override
  void initState() {
    super.initState();

    // ✅ Page open হওয়ার সাথে সাথে signal reset করো
    // এটা না করলে আগের true value থেকে ever() fire হবে না
    socketService.resetCallSignals();

    print('VideoCallPage initState');
    print(
      'Token: ${widget.token} | Channel: ${widget.channelName} | '
      'CallId: ${widget.callId} | UUID: ${widget.uuid}',
    );

    _declinedWorker = ever(socketService.callDeclinedSignal, (bool value) {
      print('👀 callDeclinedSignal changed: $value');
      if (value && mounted && !_isLeavingCall) {
        print('📵 Call declined — closing VideoCallPage');
        _leaveAndPop();
      }
    });

    _endedWorker = ever(socketService.callEndedSignal, (bool value) {
      print('👀 callEndedSignal changed: $value');
      if (value && mounted && !_isLeavingCall) {
        print('📵 Call ended — closing VideoCallPage');
        _leaveAndPop();
      }
    });

    joinCall();
  }

  /// ✅ Call duration সেকেন্ডে বের করো
  int _getCallDuration() {
    if (_callStartTime == null) return 0;
    return DateTime.now().difference(_callStartTime!).inSeconds;
  }

  /// ✅ Agora cleanly leave করে socket emit করে page বন্ধ করো
  Future<void> _leaveAndPop({bool emitCallEnd = false}) async {
    if (_isLeavingCall) return;
    _isLeavingCall = true;

    // ✅ callEnd emit করতে বললে duration সহ পাঠাও
    if (emitCallEnd) {
      final duration = _getCallDuration();
      print('📞 Emitting callEnd with duration: $duration seconds');
      socketService.socket.emitWithAck(
        'callEnd',
        {
          'callId': widget.callId,
          'duration': duration,
        },
        ack: (response) {
          print('Server acknowledged for callEnd: $response');
        },
      );
    }

    try {
      await agoraEngine.leaveChannel();
    } catch (e) {
      print('Error leaving channel: $e');
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> joinCall() async {
    callProgress = false;
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) setState(() {});
    await initAgora();
  }

  Future<void> stopRingtone() async {}

  Future<void> ringtone() async {}

  Future<void> initAgora() async {
    try {
      agoraEngine = createAgoraRtcEngine();

      await agoraEngine.initialize(
        RtcEngineContext(
          appId: widget.appID,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );

      ringtone();
      if (mounted) setState(() {});

      agoraEngine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            if (mounted) {
              setState(() {
                localUserJoined = true;
                engineLog = 'Joined channel successfully';
              });
            }
          },
          onUserJoined: (RtcConnection connection, int rUid, int elapsed) {
            if (mounted) {
              setState(() {
                remoteUid = rUid;
                engineLog = 'Remote user joined: $rUid';
              });
              // ✅ Call শুরুর সময় save করো
              _callStartTime = DateTime.now();
              stopRingtone();
              startTimer();
            }
          },
          onUserOffline: (
            RtcConnection connection,
            int rUid,
            UserOfflineReasonType reason,
          ) {
            print('onUserOffline: $rUid, reason: $reason');
            if (mounted && !_isLeavingCall) {
              final duration = _getCallDuration();
              print('📞 Remote user left. Duration: $duration seconds');

              // ✅ Duration সহ callEnd emit করো এবং page বন্ধ করো
              socketService.socket.emitWithAck(
                'callEnd',
                {
                  'callId': widget.callId,
                  'duration': duration,
                },
                ack: (response) {
                  print('Server acknowledged for callEnd: $response');
                },
              );

              _leaveAndPop();
            }
          },
          onConnectionStateChanged: (
            RtcConnection connection,
            ConnectionStateType state,
            ConnectionChangedReasonType reason,
          ) {
            if (mounted) {
              setState(() {
                engineLog = 'Connection: ${state.name} - ${reason.name}';
              });
            }
          },
          onError: (ErrorCodeType err, String msg) {
            if (mounted) {
              setState(() {
                engineLog = 'Error: ${err.name} - $msg';
              });
            }
          },
        ),
      );

      await agoraEngine.enableVideo();
      await agoraEngine.startPreview();

      if (mounted) {
        setState(() {
          engineLog = 'Joining channel: ${widget.channelName}...';
        });
      }

      await agoraEngine.joinChannel(
        token: widget.token,
        channelId: widget.channelName,
        uid: widget.uuid,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          publishMicrophoneTrack: true,
          publishCameraTrack: true,
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          engineLog = 'Error: $e';
        });
      }
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
      return remoteUid != null && mounted;
    });
  }

  @override
  void dispose() {
    _declinedWorker?.dispose();
    _endedWorker?.dispose();
    socketService.resetCallSignals();
    agoraEngine.leaveChannel();
    agoraEngine.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Remote video (full screen)
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

          // Waiting screen — remote user এখনো join করেনি
          if (remoteUid == null)
            Container(
              color: Colors.black87,
              width: double.maxFinite,
              height: double.maxFinite,
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 128),
                    CircleAvatar(
                      radius: 48,
                      backgroundImage: widget.photoUrl.isNotEmpty
                          ? NetworkImage(widget.photoUrl)
                          : null,
                      child: widget.photoUrl.isEmpty
                          ? const Icon(Icons.person, size: 48)
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      callingStatus,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Local video (small, top right) — call চলাকালীন
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

          // End call button — waiting screen এ (receiver আসেনি)
          if (remoteUid == null)
            Positioned(
              bottom: 36,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Center(
                  child: CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.red,
                    child: IconButton(
                      onPressed: () {
                        stopRingtone();
                        // Receiver আসার আগে cancel করলে callCancel emit করো
                        socketService.socket.emit('callCancel', {
                          'callId': widget.callId,
                        });
                        _leaveAndPop();
                      },
                      icon: const Icon(Icons.call_end, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),

          // Call timer — call চলাকালীন
          if (remoteUid != null)
            Positioned(
              bottom: 130,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Obx(
                      () => Text(
                        time.value,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Camera off indicator
          if (!_cameraEnabled)
            const Positioned(
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

          // Controls — call চলাকালীন (mic, camera, flip, end)
          if (remoteUid != null && localUserJoined)
            Positioned(
              bottom: 36,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Mic toggle
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: _micEnabled
                          ? Colors.black26
                          : Colors.red,
                      child: IconButton(
                        onPressed: () async {
                          setState(() => _micEnabled = !_micEnabled);
                          await agoraEngine.muteLocalAudioStream(!_micEnabled);
                        },
                        icon: Icon(
                          _micEnabled
                              ? Icons.mic_none
                              : Icons.mic_off_outlined,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Camera toggle
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: _cameraEnabled
                          ? Colors.black26
                          : Colors.red,
                      child: IconButton(
                        onPressed: () async {
                          setState(() => _cameraEnabled = !_cameraEnabled);
                          await agoraEngine.muteLocalVideoStream(!_cameraEnabled);
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
                    // Flip camera
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
                    // ✅ End call — duration সহ callEnd emit করো
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.red,
                      child: IconButton(
                        onPressed: () {
                          // emitCallEnd: true দিলে _leaveAndPop duration সহ emit করবে
                          _leaveAndPop(emitCallEnd: true);
                        },
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