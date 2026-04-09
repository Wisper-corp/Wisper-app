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
import 'package:wisper/app/core/services/network_caller/network_caller.dart';
import 'package:wisper/app/core/services/network_caller/network_response.dart';
import 'package:wisper/app/urls.dart';

class VideoCallPage extends StatefulWidget {
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

  const VideoCallPage({
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
  State<VideoCallPage> createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> {
  final AudioPlayer _player = AudioPlayer();

  late RtcEngine agoraEngine;
  final List<int> _remoteUids = [];
  final Set<int> _remoteVideoMuted = {};

  bool localUserJoined = false;
  bool _micEnabled = true;
  bool _cameraEnabled = true;
  bool _speakerEnabled = true;
  String callingStatus = 'Calling...';
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

  // ✅ NEW: participantInfo change হলে UI rebuild করার জন্য worker
  Worker? _participantInfoWorker;

  Timer? _noAnswerTimer;
  RxString time = '00:00'.obs;
  String _currentToken = '';
  bool _tokenRefreshing = false;

  // ✅ REMOVED: _uidToName, _nameQueue — এখন callService.participantInfo use করবো
  // fallback name এর জন্য শুধু widget.name রাখবো (1-to-1 call এর জন্য)

  bool _forceMultiParty = false;
  bool _callLogRetryDone = false;

  bool get hasRemoteUser => _remoteUids.isNotEmpty;
  bool get _isGroupCall =>
      (widget.groupId ?? '').isNotEmpty || widget.isGroupCall;
  bool get _isClassCall => (widget.classId ?? '').isNotEmpty;
  bool get _isMultiParty => _isGroupCall || _isClassCall || _forceMultiParty;

  // ✅ NEW: callService.participantInfo থেকে name এবং image নেওয়ার helper
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

    // ✅ NEW: participantInfo update হলে UI rebuild করো (name/image দেখানোর জন্য)
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
                if (!_remoteUids.contains(rUid)) {
                  _remoteUids.add(rUid);
                  // ✅ participantInfo-এ না থাকলে group/call log থেকে load করার চেষ্টা
                  if (callService.participantInfo[rUid] == null) {
                    _forceMultiParty = true;
                  }
                }
              });
              final keys = callService.participantInfo.keys.toList();
              print('🔎 [VideoCall] onUserJoined uid=$rUid');
              print('🔎 [VideoCall] participantInfo keys=$keys');
              print('🔎 [VideoCall] uid match in participantInfo: ${keys.contains(rUid)}');
              final incoming = callService.incomingCall.value;
              if (incoming != null && incoming['participants'] is List) {
                final list = incoming['participants'] as List;
                final uids = list
                    .map((p) => (p is Map ? p['uid'] : null))
                    .where((v) => v != null)
                    .toList();
                print('🔎 [VideoCall] incoming participant uids=$uids');
                print('🔎 [VideoCall] uid match in incoming list: ${uids.contains(rUid)}');
                for (final p in list) {
                  if (p is! Map) continue;
                  final rawUid = p['uid'];
                  final int? pUid = rawUid is int
                      ? rawUid
                      : int.tryParse(rawUid?.toString() ?? '');
                  if (pUid == rUid) {
                    print('✅ [VideoCall] matched participant: $p');
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
                _remoteVideoMuted.remove(rUid);
              });
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
          onRemoteVideoStateChanged: (
            RtcConnection connection,
            int rUid,
            RemoteVideoState state,
            RemoteVideoStateReason reason,
            int elapsed,
          ) {
            if (!mounted) return;
            final bool muted =
                state == RemoteVideoState.remoteVideoStateStopped ||
                state == RemoteVideoState.remoteVideoStateFrozen;
            setState(() {
              if (muted) {
                _remoteVideoMuted.add(rUid);
              } else {
                _remoteVideoMuted.remove(rUid);
              }
            });
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
    // ✅ NEW: worker dispose
    _participantInfoWorker?.dispose();
    callService.resetCallSignals();
    _player.dispose();
    agoraEngine.leaveChannel();
    agoraEngine.release();
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────────────
  // VIDEO TILE — ✅ name label এখন participantInfo থেকে আসে
  // ──────────────────────────────────────────────────────────────────
  Widget _videoTile(int uid, {String? label, double? radius}) {
    final bool isLocal = uid == 0;
    final bool showLocalAvatar = isLocal && !_cameraEnabled;
    final bool showRemoteAvatar =
        !isLocal && _remoteVideoMuted.contains(uid);
    final String localName =
        StorageUtil.getData(StorageUtil.cachedUserName)?.toString() ?? 'Me';
    final String localImage =
        StorageUtil.getData(StorageUtil.cachedUserImage)?.toString() ?? '';
    final String remoteName = _nameForUid(uid);
    final String remoteImage = _imageForUid(uid);

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius ?? 16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (showLocalAvatar)
            Container(
              color: const Color(0xff1B1B1B),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.white12,
                      backgroundImage:
                          localImage.isNotEmpty ? NetworkImage(localImage) : null,
                      child: localImage.isEmpty
                          ? Text(
                              localName.isNotEmpty ? localName[0] : 'M',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      localName.isNotEmpty ? localName : 'Me',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            )
          else if (showRemoteAvatar)
            Container(
              color: const Color(0xff1B1B1B),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.white12,
                      backgroundImage: remoteImage.isNotEmpty
                          ? NetworkImage(remoteImage)
                          : null,
                      child: remoteImage.isEmpty
                          ? Text(
                              remoteName.isNotEmpty ? remoteName[0] : 'U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      remoteName.isNotEmpty ? remoteName : 'User',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            )
          else
            AgoraVideoView(
              controller: VideoViewController(
                rtcEngine: agoraEngine,
                canvas: VideoCanvas(uid: uid),
              ),
            ),
          // ✅ Name label — bottom-left
          if (label != null)
            Positioned(
              bottom: 6,
              left: 6,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // EMPTY TILE
  // ──────────────────────────────────────────────────────────────────
  Widget _emptyTile() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(0),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff1B1B1B), Color(0xff0E0E0E)],
        ),
        border: Border.all(color: Colors.white12, width: 1),
      ),
      child: Center(
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white10,
            border: Border.all(color: Colors.white12),
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // LAYOUT: 2 users → User1 fullscreen + Me small overlay top-right
  // ──────────────────────────────────────────────────────────────────
  Widget _layout2User() {
    final uid = _remoteUids[0];
    return Stack(
      children: [
        Positioned.fill(
          child: _videoTile(uid, label: _nameForUid(uid), radius: 0),
        ),
        Positioned(
          top: 20,
          right: 12,
          width: 120,
          height: 160,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [
                BoxShadow(color: Colors.black45, blurRadius: 8)
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _videoTile(0, label: 'Me', radius: 0),
            ),
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // LAYOUT: 3 users → Top: User1 | User2 / Bottom: Me (full)
  // ──────────────────────────────────────────────────────────────────
  Widget _layout3User() {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _videoTile(_remoteUids[0],
                    label: _nameForUid(_remoteUids[0]), radius: 0),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: _videoTile(_remoteUids[1],
                    label: _nameForUid(_remoteUids[1]), radius: 0),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Expanded(child: _videoTile(0, label: 'Me', radius: 0)),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // LAYOUT: 4 users → Top: User1 | User2 / Bottom: User3 | Me
  // ──────────────────────────────────────────────────────────────────
  Widget _layout4User() {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _videoTile(_remoteUids[0],
                    label: _nameForUid(_remoteUids[0]), radius: 0),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: _videoTile(_remoteUids[1],
                    label: _nameForUid(_remoteUids[1]), radius: 0),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _videoTile(_remoteUids[2],
                    label: _nameForUid(_remoteUids[2]), radius: 0),
              ),
              const SizedBox(width: 2),
              Expanded(child: _videoTile(0, label: 'Me', radius: 0)),
            ],
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // LAYOUT: 5 users → 2×2 grid (User1-4) / Bottom: Me (centered)
  // ──────────────────────────────────────────────────────────────────
  Widget _layout5User() {
    return Column(
      children: [
        Expanded(
          flex: 2,
          child: Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _videoTile(_remoteUids[0],
                          label: _nameForUid(_remoteUids[0]), radius: 0),
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      child: _videoTile(_remoteUids[1],
                          label: _nameForUid(_remoteUids[1]), radius: 0),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _videoTile(_remoteUids[2],
                          label: _nameForUid(_remoteUids[2]), radius: 0),
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      child: _videoTile(_remoteUids[3],
                          label: _nameForUid(_remoteUids[3]), radius: 0),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Expanded(
          child: Row(
            children: [
              const Expanded(child: SizedBox()),
              Expanded(child: _videoTile(0, label: 'Me', radius: 0)),
              const Expanded(child: SizedBox()),
            ],
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // LAYOUT: 6 users → 2×2 grid (User1-4) / Bottom: User5 | Me
  // ──────────────────────────────────────────────────────────────────
  Widget _layout6User() {
    return Column(
      children: [
        Expanded(
          flex: 2,
          child: Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _videoTile(_remoteUids[0],
                          label: _nameForUid(_remoteUids[0]), radius: 0),
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      child: _videoTile(_remoteUids[1],
                          label: _nameForUid(_remoteUids[1]), radius: 0),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _videoTile(_remoteUids[2],
                          label: _nameForUid(_remoteUids[2]), radius: 0),
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      child: _videoTile(_remoteUids[3],
                          label: _nameForUid(_remoteUids[3]), radius: 0),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _videoTile(_remoteUids[4],
                    label: _nameForUid(_remoteUids[4]), radius: 0),
              ),
              const SizedBox(width: 2),
              Expanded(child: _videoTile(0, label: 'Me', radius: 0)),
            ],
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // LAYOUT: 7+ users → Auto 3-column scrollable grid, Me last cell
  // ──────────────────────────────────────────────────────────────────
  Widget _layoutManyUsers() {
    const int columns = 3;
    final int remoteCount = _remoteUids.length;
    final int totalCount = remoteCount + 1;
    final int rows = (totalCount / columns).ceil();
    final int totalCells = rows * columns;
    final int fillersNeeded = totalCells - totalCount;

    final List<int> allUids = [
      ..._remoteUids,
      for (int i = 0; i < fillersNeeded; i++) -1,
      0,
    ];

    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
        childAspectRatio: 0.7,
      ),
      itemCount: allUids.length,
      itemBuilder: (context, index) {
        final uid = allUids[index];
        if (uid == -1) return _emptyTile();
        if (uid == 0) return _videoTile(0, label: 'Me', radius: 0);
        return _videoTile(uid, label: _nameForUid(uid), radius: 0);
      },
    );
  }

  Widget _buildCallLayout() {
    final int count = _remoteUids.length;
    if (count == 1) return _layout2User();
    if (count == 2) return _layout3User();
    if (count == 3) return _layout4User();
    if (count == 4) return _layout5User();
    if (count == 5) return _layout6User();
    return _layoutManyUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ══════════════════════════════════════════════════════════
          // WAITING SCREEN
          // ══════════════════════════════════════════════════════════
          if (!hasRemoteUser)
            Positioned.fill(
              child: Container(
                color: const Color(0xff0F0F1A),
                child: SafeArea(
                  child: Column(
                    children: [
                      const SizedBox(height: 60),
                      Text(
                        callingStatus,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      if (!callProgress)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: SizedBox(
                            width: 220,
                            height: 320,
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

          // ══════════════════════════════════════════════════════════
          // ACTIVE CALL LAYOUT
          // ══════════════════════════════════════════════════════════
          if (hasRemoteUser && !callProgress) ...[
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 90,
              child: _buildCallLayout(),
            ),

            // Timer pill
            Positioned(
              left: 0,
              right: 0,
              bottom: 120,
              child: SafeArea(
                top: false,
                child: Center(
                  child: Obx(
                    () => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.circle,
                              color: Colors.red, size: 4),
                          const SizedBox(width: 5),
                          Text(
                            time.value,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Bottom control bar
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
                          await agoraEngine
                              .muteLocalAudioStream(!_micEnabled);
                        },
                      ),
                      _controlBtn(
                        icon: _cameraEnabled
                            ? Icons.videocam_rounded
                            : Icons.videocam_off_rounded,
                        active: _cameraEnabled,
                        onTap: () async {
                          setState(() => _cameraEnabled = !_cameraEnabled);
                          await agoraEngine
                              .muteLocalVideoStream(!_cameraEnabled);
                        },
                      ),
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
                        onTap: () async =>
                            await agoraEngine.switchCamera(),
                      ),
                      _controlBtn(
                        icon: _speakerEnabled
                            ? Icons.volume_up_rounded
                            : Icons.volume_off_rounded,
                        active: _speakerEnabled,
                        onTap: () async {
                          setState(
                              () => _speakerEnabled = !_speakerEnabled);
                          await agoraEngine
                              .setEnableSpeakerphone(_speakerEnabled);
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
