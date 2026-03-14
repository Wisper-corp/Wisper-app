import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wisper/app/modules/calls/controller/call_controller.dart';
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
  final AudioPlayer _player = AudioPlayer();

  late RtcEngine agoraEngine;
  final List<int> _remoteUids = [];

  bool localUserJoined = false;
  bool _micEnabled = true;
  bool _cameraEnabled = true;
  bool _speakerEnabled = true;
  String callingStatus = 'Calling...';
  bool callProgress = true;
  bool _isLeavingCall = false;

  DateTime? _callStartTime;
  SocketService socketService = Get.find<SocketService>();
  final CallController _callController = CallController();

  Worker? _declinedWorker;
  Worker? _endedWorker;
  Timer? _noAnswerTimer;
  RxString time = '00:00'.obs;
  String _currentToken = '';
  bool _tokenRefreshing = false;

  bool get hasRemoteUser => _remoteUids.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _currentToken = widget.token;
    socketService.resetCallSignals();
    _player.setReleaseMode(ReleaseMode.loop);

    _declinedWorker = ever(socketService.callDeclinedSignal, (bool value) {
      if (value && mounted && !_isLeavingCall) {
        _cancelNoAnswerTimer();
        _leaveAndPop();
      }
    });

    _endedWorker = ever(socketService.callEndedSignal, (bool value) {
      if (value && mounted && !_isLeavingCall) {
        _cancelNoAnswerTimer();
        _leaveAndPop();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final ok = await _ensurePermissions();
      if (!ok) {
        if (mounted) Navigator.pop(context);
        return;
      }
      joinCall();
    });
  }

  Future<bool> _ensurePermissions() async {
    final statuses = await [
      Permission.microphone,
      Permission.camera,
    ].request();

    final micOk = statuses[Permission.microphone]?.isGranted ?? false;
    final camOk = statuses[Permission.camera]?.isGranted ?? false;
    if (!micOk || !camOk) {
      Get.snackbar(
        'Permission Required',
        'Camera and Microphone permissions are needed.',
      );
      return false;
    }
    return true;
  }

  Future<void> ringtone() async {
    try {
      await _player.play(AssetSource('ringtone.mp3'));
    } catch (e) {
      print('Ringtone error: $e');
    }
  }

  Future<void> stopRingtone() async {
    try {
      await _player.stop();
    } catch (e) {
      print('Stop ringtone error: $e');
    }
  }

  void _startNoAnswerTimer() {
    _noAnswerTimer = Timer(const Duration(seconds: 30), () {
      if (!hasRemoteUser && mounted && !_isLeavingCall) {
        socketService.socket.emit('callCancel', {'callId': widget.callId});
        _leaveAndPop();
      }
    });
  }

  void _cancelNoAnswerTimer() {
    _noAnswerTimer?.cancel();
    _noAnswerTimer = null;
  }

  int _getCallDuration() {
    if (_callStartTime == null) return 0;
    return DateTime.now().difference(_callStartTime!).inSeconds;
  }

  Future<void> _leaveAndPop({bool emitCallEnd = false}) async {
    if (_isLeavingCall) return;
    _isLeavingCall = true;
    _cancelNoAnswerTimer();
    await stopRingtone();

    if (emitCallEnd) {
      final duration = _getCallDuration();
      socketService.socket.emitWithAck(
        'callEnd',
        {'callId': widget.callId, 'duration': duration},
        ack: (response) => print('callEnd ack: $response'),
      );
    }

    try {
      await agoraEngine.leaveChannel();
    } catch (e) {
      print('Error leaving: $e');
    }

    if (mounted) Navigator.pop(context);
  }

  Future<void> joinCall() async {
    callProgress = false;
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) setState(() {});
    await initAgora();
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

      await ringtone();
      if (mounted) setState(() {});

      agoraEngine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            if (mounted) {
              setState(() => localUserJoined = true);
              _startNoAnswerTimer();
            }
          },
          onUserJoined: (RtcConnection connection, int rUid, int elapsed) {
            if (mounted) {
              _cancelNoAnswerTimer();
              stopRingtone();
              setState(() {
                if (!_remoteUids.contains(rUid)) _remoteUids.add(rUid);
              });
              if (_remoteUids.length == 1) {
                _callStartTime = DateTime.now();
                startTimer();
              }
            }
          },
          onUserOffline: (
            RtcConnection connection,
            int rUid,
            UserOfflineReasonType reason,
          ) {
            if (mounted) {
              setState(() => _remoteUids.remove(rUid));
              if (_remoteUids.isEmpty && !_isLeavingCall) {
                socketService.socket.emitWithAck(
                  'callEnd',
                  {'callId': widget.callId, 'duration': _getCallDuration()},
                  ack: (_) {},
                );
                _leaveAndPop();
              }
            }
          },
          onConnectionStateChanged: (c, state, reason) {
            if (mounted) setState(() {});
          },
          onError: (err, msg) {
            if (mounted) setState(() {});
            if (err == ErrorCodeType.errInvalidToken) {
              _refreshTokenAndRejoin();
            }
          },
        ),
      );

      await agoraEngine.enableVideo();
      await agoraEngine.startPreview();
      await agoraEngine.joinChannel(
        token: _currentToken,
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
      if (mounted) setState(() {});
    }
  }

  Future<void> _refreshTokenAndRejoin() async {
    if (_tokenRefreshing) return;
    _tokenRefreshing = true;
    print('🔁 Invalid token — refreshing...');

    final bool ok = await _callController.getToken(
      callId: widget.callId,
      roomId: widget.channelName,
    );

    if (!ok) {
      print('❌ Token refresh failed: ${_callController.errorMessage}');
      _tokenRefreshing = false;
      return;
    }

    _currentToken = _callController.token;
    print('✅ Token refreshed — rejoining...');

    try {
      await agoraEngine.leaveChannel();
    } catch (_) {}

    await agoraEngine.joinChannel(
      token: _currentToken,
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

    _tokenRefreshing = false;
  }

  Future<void> startTimer() async {
    int seconds = 0;
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      seconds++;
      final m = ((seconds ~/ 60) % 60).toString().padLeft(2, '0');
      final s = (seconds % 60).toString().padLeft(2, '0');
      time.value = '$m:$s';
      return hasRemoteUser && mounted;
    });
  }

  @override
  void dispose() {
    _cancelNoAnswerTimer();
    _declinedWorker?.dispose();
    _endedWorker?.dispose();
    socketService.resetCallSignals();
    _player.dispose();
    agoraEngine.leaveChannel();
    agoraEngine.release();
    super.dispose();
  }

  // ─── Video tile helper ────────────────────────────────────────────────
  Widget _videoTile(int uid, {String? label, double? radius}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius ?? 16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          AgoraVideoView(
            controller: VideoViewController(
              rtcEngine: agoraEngine,
              canvas: VideoCanvas(uid: uid),
            ),
          ),
          if (label != null)
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── "Me" small overlay ───────────────────────────────────────────────
  Widget _meOverlay() {
    return Positioned(
      top: 12,
      right: 12,
      width: 80,
      height: 108,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(color: Colors.black45, blurRadius: 8),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: AgoraVideoView(
            controller: VideoViewController(
              rtcEngine: agoraEngine,
              canvas: const VideoCanvas(uid: 0),
            ),
          ),
        ),
      ),
    );
  }

  // ─── LAYOUT: 2 User (1 remote + me) ──────────────────────────────────
  // Sketch: User full screen, me small top-right
  Widget _layout2User() {
    return Stack(
      children: [
        Positioned.fill(child: _videoTile(_remoteUids[0], label: 'User')),
        _meOverlay(),
      ],
    );
  }

  // ─── LAYOUT: 3 User (2 remote + me) ──────────────────────────────────
  // Sketch: User1 top big, User2 bottom half, me small top-right
  Widget _layout3User() {
    return Stack(
      children: [
        Column(
          children: [
            // User1 — top 60%
            Expanded(
              flex: 6,
              child: SizedBox(
                width: double.infinity,
                child: _videoTile(_remoteUids[0], label: 'User 1'),
              ),
            ),
            const SizedBox(height: 2),
            // User2 — bottom 40%
            Expanded(
              flex: 4,
              child: SizedBox(
                width: double.infinity,
                child: _videoTile(_remoteUids[1], label: 'User 2'),
              ),
            ),
          ],
        ),
        _meOverlay(),
      ],
    );
  }

  // ─── LAYOUT: 4 User (3 remote + me) — 2x2 grid ───────────────────────
  // Sketch: User1 | User2 / User3 | Me — সব equal
  Widget _layout4User() {
    final allUids = [..._remoteUids.take(3), 0]; // 3 remote + local (me)
    final labels = ['User 1', 'User 2', 'User 3', 'Me'];

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
        childAspectRatio: 0.75,
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        return _videoTile(allUids[index], label: labels[index], radius: 0);
      },
    );
  }

  // ─── LAYOUT: 5+ User — scrollable grid ───────────────────────────────
  Widget _layoutManyUsers() {
    final allUids = [..._remoteUids, 0]; // all remote + me
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
        childAspectRatio: 0.75,
      ),
      itemCount: allUids.length,
      itemBuilder: (context, index) {
        final label = allUids[index] == 0 ? 'Me' : 'User ${index + 1}';
        return _videoTile(allUids[index], label: label, radius: 0);
      },
    );
  }

  // ─── Pick correct layout based on user count ─────────────────────────
  Widget _buildCallLayout() {
    final count = _remoteUids.length; // remote only
    if (count == 1) return _layout2User();
    if (count == 2) return _layout3User();
    if (count == 3) return _layout4User();
    return _layoutManyUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ═══════════════════════════════════════════════
          // WAITING SCREEN — call start হওয়ার আগে
          // ═══════════════════════════════════════════════
          if (!hasRemoteUser)
            Positioned.fill(
              child: Container(
                color: const Color(0xff0F0F1A),
                child: SafeArea(
                  child: Column(
                    children: [
                      const SizedBox(height: 60),
                      Text(
                        widget.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        callingStatus,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      // Local preview
                      if (!callProgress)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: SizedBox(
                            width: 180,
                            height: 260,
                            child: AgoraVideoView(
                              controller: VideoViewController(
                                rtcEngine: agoraEngine,
                                canvas: const VideoCanvas(uid: 0),
                              ),
                            ),
                          ),
                        ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 48),
                        child: GestureDetector(
                          onTap: () {
                            socketService.socket.emit('callCancel', {
                              'callId': widget.callId,
                            });
                            _leaveAndPop();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.5),
                                  blurRadius: 20,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.call_end_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ═══════════════════════════════════════════════
          // CALL LAYOUT — call চলাকালীন
          // ═══════════════════════════════════════════════
          if (hasRemoteUser && !callProgress) ...[
            // Video area — controls এর উপরে পর্যন্ত
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 90,
              child: _buildCallLayout(),
            ),

            // ─── TOP: name + timer ──────────────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            shadows: [
                              Shadow(color: Colors.black87, blurRadius: 10),
                            ],
                          ),
                        ),
                      ),
                      Obx(
                        () => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.circle,
                                color: Colors.red,
                                size: 7,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                time.value,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ─── BOTTOM CONTROLS ────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 90,
                color: const Color(0xff0F0F1A),
                child: SafeArea(
                  top: false,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _controlBtn(
                        icon: _micEnabled
                            ? Icons.mic_rounded
                            : Icons.mic_off_rounded,
                        active: _micEnabled,
                        onTap: () async {
                          setState(() => _micEnabled = !_micEnabled);
                          await agoraEngine.muteLocalAudioStream(!_micEnabled);
                        },
                      ),
                      _controlBtn(
                        icon: _cameraEnabled
                            ? Icons.videocam_rounded
                            : Icons.videocam_off_rounded,
                        active: _cameraEnabled,
                        onTap: () async {
                          setState(() => _cameraEnabled = !_cameraEnabled);
                          await agoraEngine.muteLocalVideoStream(!_cameraEnabled);
                        },
                      ),
                      // End call — bigger
                      GestureDetector(
                        onTap: () => _leaveAndPop(emitCallEnd: true),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.4),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.call_end_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                      _controlBtn(
                        icon: Icons.flip_camera_ios_rounded,
                        active: true,
                        onTap: () async => await agoraEngine.switchCamera(),
                      ),
                      _controlBtn(
                        icon: _speakerEnabled
                            ? Icons.volume_up_rounded
                            : Icons.volume_off_rounded,
                        active: _speakerEnabled,
                        onTap: () async {
                          setState(() => _speakerEnabled = !_speakerEnabled);
                          await agoraEngine.setEnableSpeakerphone(_speakerEnabled);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _controlBtn({
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: active
              ? Colors.white.withOpacity(0.12)
              : Colors.white.withOpacity(0.06),
          shape: BoxShape.circle,
          border: Border.all(
            color: active
                ? Colors.white.withOpacity(0.25)
                : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Icon(
          icon,
          color: active ? Colors.white : Colors.white38,
          size: 22,
        ),
      ),
    );
  }
}
