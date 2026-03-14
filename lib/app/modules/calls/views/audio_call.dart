import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wisper/app/modules/calls/controller/call_controller.dart';
import 'package:wisper/app/core/services/socket/socket_service.dart';

class AudioCallPage extends StatefulWidget {
  final String name;
  final String photoUrl;
  final String appID = '7c1109dc675e47f6b2562f2dab6581bd';
  final String chatId;
  final String channelName;
  final String token;
  final int uuid;
  final String callId;
 
  const AudioCallPage({
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
  State<AudioCallPage> createState() => _AudioCallPageState();
}

class _AudioCallPageState extends State<AudioCallPage> {
  final AudioPlayer _player = AudioPlayer();

  late RtcEngine agoraEngine;
  bool localUserJoined = false;
  bool _micEnabled = true;
  bool _speakerEnabled = true;

  // ✅ Single remoteUid এর বদলে list — group call support
  final List<int> _remoteUids = [];

  String engineLog = 'Initializing...';
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

  // ✅ কেউ join করেছে কিনা
  bool get hasRemoteUser => _remoteUids.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _currentToken = widget.token;

    socketService.resetCallSignals();
    _player.setReleaseMode(ReleaseMode.loop);

    _declinedWorker = ever(socketService.callDeclinedSignal, (bool value) {
      print('👀 callDeclinedSignal changed: $value');
      if (value && mounted && !_isLeavingCall) {
        print('📵 Call declined — closing AudioCallPage');
        _cancelNoAnswerTimer();
        _leaveAndPop();
      }
    });

    _endedWorker = ever(socketService.callEndedSignal, (bool value) {
      print('👀 callEndedSignal changed: $value');
      if (value && mounted && !_isLeavingCall) {
        print('📵 Call ended — closing AudioCallPage');
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
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      Get.snackbar('Permission Required', 'Microphone permission is needed.');
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
        print('⏰ No answer after 30s — auto cancelling call');
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
      print('📞 Emitting callEnd with duration: $duration seconds');
      socketService.socket.emitWithAck(
        'callEnd',
        {'callId': widget.callId, 'duration': duration},
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

    if (mounted) Navigator.pop(context);
  }

  Future<void> startTimer() async {
    int seconds = 0;
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      seconds++;
      final minutesStr = ((seconds ~/ 60) % 60).toString().padLeft(2, '0');
      final secondsStr = (seconds % 60).toString().padLeft(2, '0');
      time.value = '$minutesStr:$secondsStr';
      return hasRemoteUser && mounted;
    });
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
              setState(() {
                localUserJoined = true;
                engineLog = 'Connected to channel';
              });
              _startNoAnswerTimer();
            }
            print('✅ Joined audio channel');
          },
          onUserJoined: (RtcConnection connection, int rUid, int elapsed) {
            if (mounted) {
              _cancelNoAnswerTimer();
              stopRingtone();
              setState(() {
                // ✅ List এ add করো — duplicate check সহ
                if (!_remoteUids.contains(rUid)) {
                  _remoteUids.add(rUid);
                }
                engineLog = 'Remote user joined: $rUid';
              });
              // ✅ প্রথম user join করলে timer শুরু করো
              if (_remoteUids.length == 1) {
                _callStartTime = DateTime.now();
                startTimer();
              }
            }
            print('✅ Remote user joined: $rUid | Total: ${_remoteUids.length}');
          },
          onUserOffline: (
            RtcConnection connection,
            int rUid,
            UserOfflineReasonType reason,
          ) {
            print('onUserOffline: $rUid, reason: $reason');
            if (mounted) {
              setState(() {
                // ✅ List থেকে remove করো
                _remoteUids.remove(rUid);
              });

              // ✅ সবাই চলে গেলে call শেষ করো
              if (_remoteUids.isEmpty && !_isLeavingCall) {
                final duration = _getCallDuration();
                print('📞 All remote users left. Duration: $duration seconds');
                socketService.socket.emitWithAck(
                  'callEnd',
                  {'callId': widget.callId, 'duration': duration},
                  ack: (response) {
                    print('Server acknowledged for callEnd: $response');
                  },
                );
                _leaveAndPop();
              }
            }
          },
          onConnectionStateChanged: (
            RtcConnection connection,
            ConnectionStateType state,
            ConnectionChangedReasonType reason,
          ) {
            if (mounted) {
              setState(() {
                engineLog = 'Connection: ${state.name}';
              });
            }
            print('📶 Connection: ${state.name} - ${reason.name}');
          },
          onError: (ErrorCodeType err, String msg) {
            if (mounted) {
              setState(() {
                engineLog = 'Error: ${err.name}';
              });
            }
            print('❌ Error: ${err.name} - $msg');

            if (err == ErrorCodeType.errInvalidToken) {
              _refreshTokenAndRejoin();
            }
          },
        ),
      );

      if (mounted) {
        setState(() {
          engineLog = 'Joining channel...';
        });
      }

      await agoraEngine.joinChannel(
        token: _currentToken,
        channelId: widget.channelName,
        uid: widget.uuid,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          publishMicrophoneTrack: true,
          autoSubscribeAudio: true,
        ),
      );

      print('✅ Join channel request sent');
    } catch (e) {
      if (mounted) {
        setState(() {
          engineLog = 'Error: $e';
        });
      }
      print('❌ Error: $e');
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
        autoSubscribeAudio: true,
      ),
    );

    _tokenRefreshing = false;
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

  // ✅ Group audio call — participants list UI
  Widget _buildParticipantsList() {
    final count = _remoteUids.length;

    if (count == 0) {
      // কেউ আসেনি — শুধু waiting UI
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 60,
            backgroundImage: widget.photoUrl.isNotEmpty
                ? NetworkImage(widget.photoUrl)
                : null,
            child: widget.photoUrl.isEmpty
                ? const Icon(Icons.person, size: 60)
                : null,
          ),
          const SizedBox(height: 20),
          Text(
            widget.name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text('Calling...'),
        ],
      );
    }

    // ✅ ১+ জন — সবার avatar grid দেখাও
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Timer
        Obx(
          () => Text(
            time.value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),
        ),
        const SizedBox(height: 24),
        // ✅ Participant count badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${count + 1} participants', // remote + local
            style: TextStyle(
              color: Colors.blue.shade800,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 24),
        // ✅ Remote participants avatars
        Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: [
            // Local user
            _buildAvatarTile(label: 'You', isLocal: true),
            // Remote users
            ..._remoteUids.asMap().entries.map(
              (entry) {
                final idx = entry.key;
                final uid = entry.value;
                final label =
                    (idx == 0 && widget.name.isNotEmpty) ? widget.name : 'User $uid';
                return _buildAvatarTile(label: label, isLocal: false);
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAvatarTile({required String label, required bool isLocal}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: isLocal
              ? Colors.blue.shade300
              : Colors.green.shade300,
          child: Icon(
            Icons.person,
            size: 36,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 249, 250, 250),
              Color.fromARGB(255, 66, 140, 224),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            // ✅ Center content — participants
            Positioned(
              top: 140,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildParticipantsList(),
              ),
            ),

            // End call button — waiting screen (কেউ আসেনি)
            if (!hasRemoteUser)
              Positioned(
                bottom: 60,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Center(
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.red,
                      child: IconButton(
                        onPressed: () {
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

            // Controls — call চলাকালীন
            if (hasRemoteUser)
              Positioned(
                bottom: 60,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Mic toggle
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: _micEnabled
                            ? Colors.black26
                            : Colors.red,
                        child: IconButton(
                          onPressed: () async {
                            setState(() => _micEnabled = !_micEnabled);
                            await agoraEngine.muteLocalAudioStream(!_micEnabled);
                          },
                          icon: Icon(
                            _micEnabled ? Icons.mic : Icons.mic_off,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 32),
                      // Speaker toggle
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: _speakerEnabled
                            ? Colors.black26
                            : Colors.red,
                        child: IconButton(
                          onPressed: () async {
                            setState(() => _speakerEnabled = !_speakerEnabled);
                            await agoraEngine.setEnableSpeakerphone(
                              _speakerEnabled,
                            );
                          },
                          icon: Icon(
                            _speakerEnabled
                                ? Icons.volume_up
                                : Icons.volume_off,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 32),
                      // End call
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.red,
                        child: IconButton(
                          onPressed: () {
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
      ),
    );
  }
}
