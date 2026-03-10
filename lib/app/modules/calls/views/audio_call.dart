import 'package:agora_rtc_engine/agora_rtc_engine.dart';
// import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
  // final AudioPlayer _player = AudioPlayer();

  late RtcEngine agoraEngine;
  bool localUserJoined = false;
  bool _micEnabled = true;
  bool _speakerEnabled = true;
  int? remoteUid;
  String engineLog = 'Initializing...';
  bool callProgress = true;
  bool _isLeavingCall = false;

  // ✅ Call শুরুর সময় track করবে
  DateTime? _callStartTime;

  SocketService socketService = Get.find<SocketService>();

  Worker? _declinedWorker;
  Worker? _endedWorker;

  RxString time = '00:00'.obs;

  @override
  void initState() {
    super.initState();

    // ✅ Page open হওয়ার সাথে সাথে signal reset করো
    socketService.resetCallSignals();

    //  _player.setReleaseMode(ReleaseMode.loop);

    _declinedWorker = ever(socketService.callDeclinedSignal, (bool value) {
      print('👀 callDeclinedSignal changed: $value');
      if (value && mounted && !_isLeavingCall) {
        print('📵 Call declined — closing AudioCallPage');
        _leaveAndPop();
      }
    });

    _endedWorker = ever(socketService.callEndedSignal, (bool value) {
      print('👀 callEndedSignal changed: $value');
      if (value && mounted && !_isLeavingCall) {
        print('📵 Call ended — closing AudioCallPage');
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

    if (mounted) {
      Navigator.pop(context);
    }
  }

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

  Future<void> ringtone() async {
    //  await _player.play(AssetSource('audio/ringtone.mp3'));
  }

  Future<void> stopRingtone() async {
    // await _player.stop();
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
            }
            print('✅ Joined audio channel');
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
            print('✅ Remote user joined: $rUid');
          },
          onUserOffline:
              (
                RtcConnection connection,
                int rUid,
                UserOfflineReasonType reason,
              ) {
                print('onUserOffline: $rUid, reason: $reason');
                if (mounted && !_isLeavingCall) {
                  final duration = _getCallDuration();
                  print('📞 Remote user left. Duration: $duration seconds');

                  // ✅ Duration সহ callEnd emit করো
                  socketService.socket.emitWithAck(
                    'callEnd',
                    {'callId': widget.callId, 'duration': duration},
                    ack: (response) {
                      print('Server acknowledged for callEnd: $response');
                    },
                  );

                  _leaveAndPop();
                }
              },
          onConnectionStateChanged:
              (
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
          },
        ),
      );

      if (mounted) {
        setState(() {
          engineLog = 'Joining channel...';
        });
      }

      await agoraEngine.joinChannel(
        token: widget.token,
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

  @override
  void dispose() {
    _declinedWorker?.dispose();
    _endedWorker?.dispose();
    socketService.resetCallSignals();
    agoraEngine.leaveChannel();
    agoraEngine.release();
    // _player.dispose();
    super.dispose();
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
            Positioned(
              top: 160,
              right: 0,
              left: 0,
              child: Column(
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
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (remoteUid != null)
                    Obx(() => Text(time.value))
                  else
                    const Text('Calling...'),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // End call button — waiting screen (receiver আসেনি)
            if (remoteUid == null)
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

            // Controls — call চলাকালীন
            if (remoteUid != null)
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
                            await agoraEngine.muteLocalAudioStream(
                              !_micEnabled,
                            );
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
                      // ✅ End call — duration সহ callEnd emit করো
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
