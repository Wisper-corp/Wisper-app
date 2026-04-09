import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wisper/app/modules/calls/controller/call_controller.dart';
import 'package:wisper/app/core/services/call/controller/call_services.dart';
import 'package:wisper/app/core/services/socket/socket_service.dart';
import 'package:wisper/app/modules/chat/controller/group/all_group_member_controller.dart';
import 'package:wisper/app/modules/chat/controller/class/class_member_controller.dart';
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/urls.dart';

class AudioCallPage extends StatefulWidget {
  final String name;
  final String photoUrl;
  final String appID = '7c1109dc675e47f6b2562f2dab6581bd';
  final String chatId;
  final String channelName;
  final String token;
  final int uuid;
  final String callId;
  final String? groupId;
  final String? classId;
  final bool isGroupCall;
  final String? callerName;

  const AudioCallPage({
    super.key,
    required this.name,
    required this.photoUrl,
    required this.chatId,
    required this.channelName,
    required this.token,
    required this.uuid,
    required this.callId,
    this.groupId,
    this.classId,
    this.isGroupCall = false,
    this.callerName,
  });

  @override
  State<AudioCallPage> createState() => _AudioCallPageState();
}

class _AudioCallPageState extends State<AudioCallPage> {
  final AudioPlayer _player = AudioPlayer();

  late RtcEngine agoraEngine;
  bool localUserJoined = false;
  bool _micEnabled = true;
  bool _speakerEnabled = false;

  final List<int> _remoteUids = [];

  String engineLog = 'Initializing...';
  bool callProgress = true;
  bool _isLeavingCall = false;

  DateTime? _callStartTime;

  final SocketService socketService = Get.find<SocketService>();
  final CallService callService = Get.isRegistered<CallService>()
      ? Get.find<CallService>()
      : Get.put(CallService());
  final CallController _callController = CallController();
  final GroupMembersController _groupMembersController =
      Get.put(GroupMembersController());
  final ClassMembersController _classMembersController =
      Get.put(ClassMembersController());

  Worker? _declinedWorker;
  Worker? _endedWorker;
  // ✅ NEW: participantInfo update হলে UI rebuild করার worker
  Worker? _participantInfoWorker;

  Timer? _noAnswerTimer;
  RxString time = '00:00'.obs;
  String _currentToken = '';
  bool _tokenRefreshing = false;

  bool _forceMultiParty = false;
  bool _callLogRetryDone = false;

  bool get hasRemoteUser => _remoteUids.isNotEmpty;
  bool get _isGroupCall =>
      (widget.groupId ?? '').isNotEmpty || widget.isGroupCall;
  bool get _isClassCall => (widget.classId ?? '').isNotEmpty;
  bool get _isMultiParty => _isGroupCall || _isClassCall || _forceMultiParty;

  // ✅ NEW: callService.participantInfo থেকে name পাওয়ার helper
  String _nameForUid(int uid) {
    final info = callService.participantInfo[uid];
    if (info != null && (info['name'] ?? '').isNotEmpty) {
      return info['name']!;
    }
    final incoming = _participantFromIncoming(uid);
    if (incoming != null) {
      final name = (incoming['name'] ?? incoming['nname'] ?? '').toString();
      if (name.isNotEmpty) return name;
    }
    // Fallback: 1-to-1 call এ widget.name use করো
    if (!_isMultiParty && widget.name.isNotEmpty) return widget.name;
    return 'User';
  }

  // ✅ NEW: callService.participantInfo থেকে image পাওয়ার helper
  String _imageForUid(int uid) {
    final info = callService.participantInfo[uid];
    if (info != null && (info['image'] ?? '').isNotEmpty) {
      return info['image']!;
    }
    final incoming = _participantFromIncoming(uid);
    if (incoming != null) {
      final image = (incoming['image'] ?? '').toString();
      if (image.isNotEmpty) return image;
    }
    return '';
  }

  Map? _participantFromIncoming(int uid) {
    final incoming = callService.incomingCall.value;
    if (incoming == null) return null;
    final participants = incoming['participants'];
    if (participants is! List) return null;
    for (final p in participants) {
      if (p is! Map) continue;
      final rawUid = p['uid'];
      final int? pUid = rawUid is int
          ? rawUid
          : int.tryParse(rawUid?.toString() ?? '');
      if (pUid == uid) return p;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _currentToken = widget.token;

    callService.resetCallSignals();
    _player.setReleaseMode(ReleaseMode.loop);

    _declinedWorker = ever(callService.callDeclinedSignal, (bool value) {
      if (value && mounted && !_isLeavingCall) {
        _cancelNoAnswerTimer();
        _leaveAndPop();
      }
    });

    _endedWorker = ever(callService.callEndedSignal, (bool value) {
      if (value && mounted && !_isLeavingCall) {
        _cancelNoAnswerTimer();
        _leaveAndPop();
      }
    });

    // ✅ NEW: participantInfo update হলে UI rebuild
    _participantInfoWorker = ever(callService.participantInfo, (_) {
      if (mounted) setState(() {});
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
              agoraEngine.setEnableSpeakerphone(false);
              _startNoAnswerTimer();
            }
          },
          onUserJoined: (RtcConnection connection, int rUid, int elapsed) {
            if (mounted) {
              _cancelNoAnswerTimer();
              stopRingtone();
              setState(() {
                if (!_remoteUids.contains(rUid)) {
                  _remoteUids.add(rUid);
                  // ✅ group call হলে forceMultiParty set করো
                  if (callService.participantInfo[rUid] == null) {
                    _forceMultiParty = true;
                  }
                }
                engineLog = 'Remote user joined: $rUid';
              });
              final keys = callService.participantInfo.keys.toList();
              print('🔎 [AudioCall] onUserJoined uid=$rUid');
              print('🔎 [AudioCall] participantInfo keys=$keys');
              print('🔎 [AudioCall] uid match in participantInfo: ${keys.contains(rUid)}');
              final incoming = callService.incomingCall.value;
              if (incoming != null && incoming['participants'] is List) {
                final list = incoming['participants'] as List;
                final uids = list
                    .map((p) => (p is Map ? p['uid'] : null))
                    .where((v) => v != null)
                    .toList();
                print('🔎 [AudioCall] incoming participant uids=$uids');
                print('🔎 [AudioCall] uid match in incoming list: ${uids.contains(rUid)}');
                for (final p in list) {
                  if (p is! Map) continue;
                  final rawUid = p['uid'];
                  final int? pUid = rawUid is int
                      ? rawUid
                      : int.tryParse(rawUid?.toString() ?? '');
                  if (pUid == rUid) {
                    print('✅ [AudioCall] matched participant: $p');
                    break;
                  }
                }
              }
              if (_remoteUids.length == 1) {
                _callStartTime = DateTime.now();
                startTimer();
              }
            }
            // ✅ Participant info আসতে একটু delay — তারপর UI refresh
            Future.delayed(const Duration(milliseconds: 300), () {
              if (!mounted) return;
              setState(() {});
            });
          },
          onUserOffline: (
            RtcConnection connection,
            int rUid,
            UserOfflineReasonType reason,
          ) {
            if (mounted) {
              setState(() {
                _remoteUids.remove(rUid);
              });

              if (_remoteUids.isEmpty && !_isLeavingCall) {
                final duration = _getCallDuration();
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
          },
          onError: (ErrorCodeType err, String msg) {
            if (mounted) {
              setState(() {
                engineLog = 'Error: ${err.name}';
              });
            }
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
    } catch (e) {
      if (mounted) {
        setState(() {
          engineLog = 'Error: $e';
        });
      }
    }
  }

  Future<void> _refreshTokenAndRejoin() async {
    if (_tokenRefreshing) return;
    _tokenRefreshing = true;

    final bool ok = await _callController.getToken(
      callId: widget.callId,
      roomId: widget.channelName,
    );

    if (!ok) {
      _tokenRefreshing = false;
      return;
    }

    _currentToken = _callController.token;

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
    // ✅ NEW: worker dispose
    _participantInfoWorker?.dispose();
    callService.resetCallSignals();
    _player.dispose();
    agoraEngine.leaveChannel();
    agoraEngine.release();
    super.dispose();
  }

  // ✅ UPDATED: participantInfo থেকে name এবং image দেখায়
  Widget _buildParticipantsList() {
    final count = _remoteUids.length;

    // কেউ join করেনি — waiting screen
    if (count == 0) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ✅ Caller image দেখাও (1-to-1 call)
          _buildAvatar(
            imageUrl: widget.photoUrl,
            label: widget.name,
            radius: 60,
          ),
          const SizedBox(height: 20),
          Text(
            widget.name.isNotEmpty ? widget.name : 'Calling...',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Calling...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black.withOpacity(0.4),
            ),
          ),
        ],
      );
    }

    // ✅ Call চলছে — timer + participants grid
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
        const SizedBox(height: 16),
        // Participant count badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${count + 1} participants',
            style: TextStyle(
              color: Colors.blue.shade800,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 24),
        // ✅ Participants avatars — name + image সহ
        Wrap(
          spacing: 20,
          runSpacing: 20,
          alignment: WrapAlignment.center,
          children: [
            // Local user (Me)
            _buildAvatarTileWithLabel(
              imageUrl: '',
              label: 'Me',
              isLocal: true,
            ),
            // Remote users — participantInfo থেকে name + image
            ..._remoteUids.map((uid) {
              final name = _nameForUid(uid);
              final image = _imageForUid(uid);
              return _buildAvatarTileWithLabel(
                imageUrl: image,
                label: name,
                isLocal: false,
              );
            }),
          ],
        ),
      ],
    );
  }

  // ✅ Avatar circle — network image সহ, fallback person icon
  Widget _buildAvatar({
    required String imageUrl,
    required String label,
    double radius = 36,
    Color? bgColor,
  }) {
    if (imageUrl.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: bgColor ?? Colors.blue.shade100,
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            placeholder: (_, __) => Icon(
              Icons.person,
              size: radius,
              color: Colors.white70,
            ),
            errorWidget: (_, __, ___) => Icon(
              Icons.person,
              size: radius,
              color: Colors.white70,
            ),
          ),
        ),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: bgColor ?? Colors.blue.shade300,
      child: Icon(Icons.person, size: radius, color: Colors.white),
    );
  }

  // ✅ Avatar tile with name label below — audio call participant card
  Widget _buildAvatarTileWithLabel({
    required String imageUrl,
    required String label,
    required bool isLocal,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar ring color: blue for local, green for remote
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isLocal
                  ? Colors.blue.shade400
                  : Colors.green.shade400,
              width: 2,
            ),
          ),
          child: _buildAvatar(
            imageUrl: imageUrl,
            label: label,
            radius: 36,
            bgColor: isLocal ? Colors.blue.shade300 : Colors.green.shade300,
          ),
        ),
        const SizedBox(height: 6),
        // Name label
        SizedBox(
          width: 80,
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
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
            // Center content — participants
            Positioned(
              top: 140,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildParticipantsList(),
              ),
            ),

            // End call — waiting screen
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
                        backgroundColor:
                            _micEnabled ? Colors.black26 : Colors.red,
                        child: IconButton(
                          onPressed: () async {
                            setState(() => _micEnabled = !_micEnabled);
                            await agoraEngine
                                .muteLocalAudioStream(!_micEnabled);
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
                            ? Colors.white
                            : Colors.black26,
                        child: IconButton(
                          onPressed: () async {
                            setState(
                                () => _speakerEnabled = !_speakerEnabled);
                            await agoraEngine
                                .setEnableSpeakerphone(_speakerEnabled);
                          },
                          icon: Icon(
                            _speakerEnabled
                                ? Icons.volume_up
                                : Icons.volume_off,
                            color: _speakerEnabled
                                ? Colors.black
                                : Colors.white,
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
