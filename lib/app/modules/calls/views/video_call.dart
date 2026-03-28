import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wisper/app/modules/calls/controller/call_controller.dart';
import 'package:wisper/app/core/services/socket/call_services.dart';
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
      ? Get.put(CallService())
      : Get.put(CallService());
  final CallController _callController = CallController();
  final GroupMembersController _groupMembersController =
      Get.put(GroupMembersController());
  final ClassMembersController _classMembersController =
      Get.put(ClassMembersController());

  Worker? _declinedWorker;
  Worker? _endedWorker;
  Timer? _noAnswerTimer;
  RxString time = '00:00'.obs;
  String _currentToken = '';
  bool _tokenRefreshing = false;
  final Map<int, String> _uidToName = {};
  final List<String> _nameQueue = [];
  bool _forceMultiParty = false;
  bool _callLogRetryDone = false;

  bool get hasRemoteUser => _remoteUids.isNotEmpty;
  bool get _isGroupCall =>
      (widget.groupId ?? '').isNotEmpty || widget.isGroupCall;
  bool get _isClassCall => (widget.classId ?? '').isNotEmpty;
  bool get _isMultiParty => _isGroupCall || _isClassCall || _forceMultiParty;

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

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final ok = await _ensurePermissions();
      if (!ok) {
        if (mounted) Navigator.pop(context);
        return;
      }
      _loadGroupMemberNames();
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

  Future<void> _loadGroupMemberNames() async {
    final classId = (widget.classId ?? '').trim();
    if (classId.isNotEmpty) {
      print('🔎 [VideoCall] classId for members: $classId');
      final ok = await _classMembersController.getClassMembers(classId);
      print('✅ [VideoCall] getClassMembers ok: $ok');
      if (!ok) return;

      final myId = StorageUtil.getData(StorageUtil.userId);
      final members = _classMembersController.groupMemnersData ?? [];
      print('👥 [VideoCall] class members count: ${members.length}');
      _nameQueue
        ..clear()
        ..addAll(
          members
              .where((m) => m.auth?.id != myId)
              .map((m) => m.auth?.person?.name ?? 'User')
              .toList(),
        );
      print('🧾 [VideoCall] class nameQueue: $_nameQueue');
      if (_nameQueue.isNotEmpty) _forceMultiParty = true;
    } else {
      var groupId = (widget.groupId ?? '').trim();
      bool resolvedClassFromChats = false;
      print('🔎 [VideoCall] groupId for members: $groupId');
      if (groupId.isEmpty && widget.name.isNotEmpty) {
        final ids = await _resolveChatIdsFromChatsByName(
            widget.name, widget.callerName);
        final resolvedClassId = ids['classId'] ?? '';
        if (resolvedClassId.isNotEmpty) {
          print('✅ [VideoCall] resolved classId from chats: $resolvedClassId');
          final ok =
              await _classMembersController.getClassMembers(resolvedClassId);
          print('✅ [VideoCall] getClassMembers ok: $ok');
          if (ok) {
            final myId = StorageUtil.getData(StorageUtil.userId);
            final members = _classMembersController.groupMemnersData ?? [];
            print('👥 [VideoCall] class members count: ${members.length}');
            _nameQueue
              ..clear()
              ..addAll(
                members
                    .where((m) => m.auth?.id != myId)
                    .map((m) => m.auth?.person?.name ?? 'User')
                    .toList(),
              );
            print('🧾 [VideoCall] class nameQueue: $_nameQueue');
            if (_nameQueue.isNotEmpty) _forceMultiParty = true;
          }
          resolvedClassFromChats = true;
        }

        groupId = ids['groupId'] ?? '';
        if (groupId.isNotEmpty) {
          print('✅ [VideoCall] resolved groupId from chats: $groupId');
        }
      }
      if (resolvedClassFromChats) {
        // Skip group fetch if class was resolved
      } else if (groupId.isEmpty) {
        await _loadNamesFromCallLog();
        return;
      } else {
        final ok = await _groupMembersController.getGroupMembers(groupId);
        print('✅ [VideoCall] getGroupMembers ok: $ok');
        if (!ok) return;

        final myId = StorageUtil.getData(StorageUtil.userId);
        final members = _groupMembersController.groupMemnersData ?? [];
        print('👥 [VideoCall] members count: ${members.length}');
        _nameQueue
          ..clear()
          ..addAll(
            members
                .where((m) => m.auth?.id != myId)
                .map((m) => m.auth?.person?.name ?? 'User')
                .toList(),
          );
        print('🧾 [VideoCall] nameQueue: $_nameQueue');
        if (_nameQueue.isNotEmpty) _forceMultiParty = true;
      }
    }

    for (final uid in _remoteUids) {
      _assignNameForUid(uid);
    }
    if (_nameQueue.isEmpty) {
      await _loadNamesFromCallLog();
    }
    if (mounted) setState(() {});
  }

  Future<Map<String, String>> _resolveChatIdsFromChatsByName(
    String groupName,
    String? callerName,
  ) async {
    String groupId = '';
    String classId = '';
    try {
      final NetworkResponse response = await Get.find<NetworkCaller>()
          .getRequest(
        '${Urls.allChatsUrl}?limit=9999',
        accessToken: StorageUtil.getData(StorageUtil.userAccessToken),
      );
      if (!response.isSuccess || response.responseData == null) {
        return {'groupId': groupId, 'classId': classId};
      }
      final responseData = response.responseData;
      if (responseData is! Map) {
        return {'groupId': groupId, 'classId': classId};
      }
      final data = responseData['data'];
      final chats = data is Map ? (data['chats'] as List? ?? []) : <dynamic>[];

      final target = groupName.trim().toLowerCase();
      final callerTarget = callerName?.trim().toLowerCase() ?? '';
      final myId = StorageUtil.getData(StorageUtil.userId);
      for (final item in chats) {
        if (item is! Map) continue;
        final type = (item['type'] ?? '').toString();

        if (type == 'CLASS') {
          final chatName = item['name']?.toString().trim().toLowerCase() ?? '';
          if (chatName.isNotEmpty && chatName == target) {
            final id = item['classId']?.toString();
            if (id != null && id.isNotEmpty) {
              classId = id;
              break;
            }
          }
        }

        final group = item['group'];
        if (group is Map) {
          final name = group['name']?.toString().trim().toLowerCase();
          if (name != null && name == target) {
            final id = group['id']?.toString();
            if (id != null && id.isNotEmpty) {
              groupId = id;
              break;
            }
          }
        }

        final community = item['community'];
        if (community is Map) {
          final name = community['name']?.toString().trim().toLowerCase();
          if (name != null && name == target) {
            final id = community['id']?.toString();
            if (id != null && id.isNotEmpty) {
              groupId = id;
              break;
            }
          }
        }

        if (type == 'CLASS') {
          final klass = item['class'];
          if (klass is Map) {
            final name = klass['name']?.toString().trim().toLowerCase();
            if (name != null && name == target) {
              final id = klass['id']?.toString();
              if (id != null && id.isNotEmpty) {
                classId = id;
                break;
              }
            }
          }
        }

        if ((groupId.isEmpty && classId.isEmpty) &&
            callerTarget.isNotEmpty &&
            (type == 'GROUP' || type == 'CLASS')) {
          final participants = item['participants'] as List? ?? [];
          bool hasCaller = false;
          bool hasMe = false;
          for (final p in participants) {
            if (p is! Map) continue;
            final auth = p['auth'];
            if (auth is! Map) continue;
            final authId = auth['id']?.toString();
            if (authId != null && authId == myId) hasMe = true;
            final person = auth['person'];
            final name = person is Map
                ? person['name']?.toString().trim().toLowerCase()
                : '';
            if (name != null && name == callerTarget) hasCaller = true;
          }
          if (hasCaller && hasMe) {
            if (type == 'CLASS') {
              final id = item['classId']?.toString();
              if (id != null && id.isNotEmpty) {
                classId = id;
                break;
              }
            }
            final id = item['groupId']?.toString();
            if (id != null && id.isNotEmpty) {
              groupId = id;
              break;
            }
          }
        }
      }
    } catch (e) {
      print('❌ [VideoCall] resolve groupId failed: $e');
    }
    return {'groupId': groupId, 'classId': classId};
  }

  void _assignNameForUid(int uid) {
    if (_uidToName.containsKey(uid)) return;
    if (_nameQueue.isEmpty) return;
    _uidToName[uid] = _nameQueue.removeAt(0);
    print('🏷️ [VideoCall] assign uid $uid -> ${_uidToName[uid]}');
  }

  String _labelForUid(int uid, String fallback) {
    return _uidToName[uid] ?? fallback;
  }

  String _fallbackLabel(int index, int uid) {
    if (!_isMultiParty && index == 0 && widget.name.isNotEmpty) {
      return widget.name;
    }
    return 'User ${index + 1}';
  }

  Future<void> _loadNamesFromCallLog() async {
    if (widget.callId.isEmpty) return;
    try {
      final NetworkResponse response = await Get.find<NetworkCaller>()
          .getRequest(
        '${Urls.myCallUrl}?limit=99999',
        accessToken: StorageUtil.getData(StorageUtil.userAccessToken),
      );
      if (!response.isSuccess || response.responseData == null) return;
      final responseData = response.responseData;
      if (responseData is! Map) return;
      final data = responseData['data'];
      final calls = data is Map ? (data['calls'] as List? ?? []) : <dynamic>[];
      final match = calls.cast<Map?>().firstWhere(
                (c) => c?['id'] == widget.callId,
                orElse: () => null,
              ) ??
          {};
      final participants = match['participants'] as List? ?? [];
      if (participants.isEmpty) return;
      if (participants.length > 1) _forceMultiParty = true;

      final myId = StorageUtil.getData(StorageUtil.userId);
      _nameQueue
        ..clear()
        ..addAll(
          participants
              .where((p) => p is Map && p['auth'] is Map)
              .map((p) => p as Map)
              .where((p) => p['auth']?['id'] != myId)
              .map<String>((p) => p['auth']?['person']?['name'] ?? 'User')
              .toList(),
        );

      for (final uid in _remoteUids) {
        _assignNameForUid(uid);
      }
      if (_nameQueue.isNotEmpty) _forceMultiParty = true;
      if (mounted) setState(() {});
      print('🧾 [VideoCall] fallback nameQueue from call log: $_nameQueue');
      if (_nameQueue.isEmpty && !_callLogRetryDone) {
        _callLogRetryDone = true;
        Future.delayed(const Duration(milliseconds: 1500), () async {
          if (!mounted) return;
          await _loadNamesFromCallLog();
        });
      }
    } catch (e) {
      print('❌ [VideoCall] fallback name load failed: $e');
    }
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
                  if (_nameQueue.isEmpty) {
                    _loadNamesFromCallLog();
                  } else {
                    _assignNameForUid(rUid);
                  }
                }
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
              setState(() {
                _remoteUids.remove(rUid);
                _uidToName.remove(rUid);
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
    print('🔁 Invalid token – refreshing...');

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
    print('✅ Token refreshed – rejoining...');

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
    callService.resetCallSignals();
    _player.dispose();
    agoraEngine.leaveChannel();
    agoraEngine.release();
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────────────
  // VIDEO TILE
  // ──────────────────────────────────────────────────────────────────
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
  // EMPTY TILE (filler for incomplete grid rows)
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
  // LAYOUT: 2 users  →  User1 fullscreen + Me small overlay top-right
  // ──────────────────────────────────────────────────────────────────
  Widget _layout2User() {
    return Stack(
      children: [
        // User1 fullscreen
        Positioned.fill(
          child: _videoTile(
            _remoteUids[0],
            label: _labelForUid(_remoteUids[0], _fallbackLabel(0, _remoteUids[0])),
            radius: 0,
          ),
        ),
        // Me – small overlay top-right
        Positioned(
          top: 20,
          right: 12,
          width: 120,
          height: 160,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 8)],
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
  // LAYOUT: 3 users  →  Top row: User1 | User2  /  Bottom: Me (full)
  // ──────────────────────────────────────────────────────────────────
  Widget _layout3User() {
    return Column(
      children: [
        // Top row – 2 remote users, equal width
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _videoTile(
                  _remoteUids[0],
                  label: _labelForUid(_remoteUids[0], _fallbackLabel(0, _remoteUids[0])),
                  radius: 0,
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: _videoTile(
                  _remoteUids[1],
                  label: _labelForUid(_remoteUids[1], _fallbackLabel(1, _remoteUids[1])),
                  radius: 0,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        // Bottom row – Me, full width
        Expanded(
          child: _videoTile(0, label: 'Me', radius: 0),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // LAYOUT: 4 users  →  Top: User1 | User2  /  Bottom: User3 | Me
  // ──────────────────────────────────────────────────────────────────
  Widget _layout4User() {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _videoTile(
                  _remoteUids[0],
                  label: _labelForUid(_remoteUids[0], _fallbackLabel(0, _remoteUids[0])),
                  radius: 0,
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: _videoTile(
                  _remoteUids[1],
                  label: _labelForUid(_remoteUids[1], _fallbackLabel(1, _remoteUids[1])),
                  radius: 0,
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
                child: _videoTile(
                  _remoteUids[2],
                  label: _labelForUid(_remoteUids[2], _fallbackLabel(2, _remoteUids[2])),
                  radius: 0,
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: _videoTile(0, label: 'Me', radius: 0),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // LAYOUT: 5 users  →  2×2 grid (User1-4)  /  Bottom: Me (centered)
  // ──────────────────────────────────────────────────────────────────
  Widget _layout5User() {
    return Column(
      children: [
        // Top 2×2 grid
        Expanded(
          flex: 2,
          child: Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _videoTile(
                        _remoteUids[0],
                        label: _labelForUid(_remoteUids[0], _fallbackLabel(0, _remoteUids[0])),
                        radius: 0,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      child: _videoTile(
                        _remoteUids[1],
                        label: _labelForUid(_remoteUids[1], _fallbackLabel(1, _remoteUids[1])),
                        radius: 0,
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
                      child: _videoTile(
                        _remoteUids[2],
                        label: _labelForUid(_remoteUids[2], _fallbackLabel(2, _remoteUids[2])),
                        radius: 0,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      child: _videoTile(
                        _remoteUids[3],
                        label: _labelForUid(_remoteUids[3], _fallbackLabel(3, _remoteUids[3])),
                        radius: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        // Bottom: Me centered (half width)
        Expanded(
          child: Row(
            children: [
              const Expanded(child: SizedBox()),
              Expanded(
                child: _videoTile(0, label: 'Me', radius: 0),
              ),
              const Expanded(child: SizedBox()),
            ],
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // LAYOUT: 6 users  →  2×2 grid (User1-4)  /  Bottom: User5 | Me
  // ──────────────────────────────────────────────────────────────────
  Widget _layout6User() {
    return Column(
      children: [
        // Top 2×2 grid
        Expanded(
          flex: 2,
          child: Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _videoTile(
                        _remoteUids[0],
                        label: _labelForUid(_remoteUids[0], _fallbackLabel(0, _remoteUids[0])),
                        radius: 0,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      child: _videoTile(
                        _remoteUids[1],
                        label: _labelForUid(_remoteUids[1], _fallbackLabel(1, _remoteUids[1])),
                        radius: 0,
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
                      child: _videoTile(
                        _remoteUids[2],
                        label: _labelForUid(_remoteUids[2], _fallbackLabel(2, _remoteUids[2])),
                        radius: 0,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      child: _videoTile(
                        _remoteUids[3],
                        label: _labelForUid(_remoteUids[3], _fallbackLabel(3, _remoteUids[3])),
                        radius: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        // Bottom: User5 | Me
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _videoTile(
                  _remoteUids[4],
                  label: _labelForUid(_remoteUids[4], _fallbackLabel(4, _remoteUids[4])),
                  radius: 0,
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: _videoTile(0, label: 'Me', radius: 0),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // LAYOUT: 7+ users  →  Auto 3-column scrollable grid, Me last cell
  //
  // Pattern:
  //   7  users (6 remote) → 3 cols × 3 rows  (last row: User6 | Me | empty)
  //   8  users (7 remote) → 3 cols × 3 rows  (last row: User6 | User7 | Me)
  //   9  users (8 remote) → 3 cols × 3 rows  (full grid, Me bottom-right)
  //   10 users (9 remote) → 3 cols × 4 rows  ...and so on
  //
  //  "Me" is always placed in the very last cell; empty filler cells
  //  are inserted before "Me" to pad incomplete rows.
  // ──────────────────────────────────────────────────────────────────
  Widget _layoutManyUsers() {
    const int columns = 3;
    final int remoteCount = _remoteUids.length;
    final int totalCount = remoteCount + 1; // remotes + me
    final int rows = (totalCount / columns).ceil();
    final int totalCells = rows * columns;
    final int fillersNeeded = totalCells - totalCount;

    // Build cell uid list: remotes … fillers (-1) … me (0)
    final List<int> allUids = [
      ..._remoteUids,
      for (int i = 0; i < fillersNeeded; i++) -1,
      0, // Me – always last
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
        final remoteIndex = _remoteUids.indexOf(uid);
        return _videoTile(
          uid,
          label: _labelForUid(uid, _fallbackLabel(remoteIndex, uid)),
          radius: 0,
        );
      },
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // LAYOUT PICKER
  // ──────────────────────────────────────────────────────────────────
  Widget _buildCallLayout() {
    final int count = _remoteUids.length; // remote users only
    if (count == 1) return _layout2User();   // 2 total: User1 + Me
    if (count == 2) return _layout3User();   // 3 total
    if (count == 3) return _layout4User();   // 4 total
    if (count == 4) return _layout5User();   // 5 total
    if (count == 5) return _layout6User();   // 6 total
    return _layoutManyUsers();               // 7+ total → 3-col grid
  }

  // ──────────────────────────────────────────────────────────────────
  // BUILD
  // ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ══════════════════════════════════════════════════════════
          // WAITING SCREEN – shown before any remote user joins
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
            // Video area (leaves room for bottom controls)
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
                      // End call
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

  // ──────────────────────────────────────────────────────────────────
  // CONTROL BUTTON
  // ──────────────────────────────────────────────────────────────────
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