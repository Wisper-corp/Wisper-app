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
  final CallService callService = Get.isRegistered<CallService>() ? Get.put(CallService()) : Get.put(CallService());
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
      print('ðŸ”Ž [VideoCall] classId for members: $classId');
      final ok = await _classMembersController.getClassMembers(classId);
      print('âœ… [VideoCall] getClassMembers ok: $ok');
      if (!ok) return;

      final myId = StorageUtil.getData(StorageUtil.userId);
      final members = _classMembersController.groupMemnersData ?? [];
      print('ðŸ‘¥ [VideoCall] class members count: ${members.length}');
      _nameQueue
        ..clear()
        ..addAll(
          members
              .where((m) => m.auth?.id != myId)
              .map((m) => m.auth?.person?.name ?? 'User')
              .toList(),
        );
      print('ðŸ§¾ [VideoCall] class nameQueue: $_nameQueue');
      if (_nameQueue.isNotEmpty) _forceMultiParty = true;
    } else {
      var groupId = (widget.groupId ?? '').trim();
      bool resolvedClassFromChats = false;
      print('ðŸ”Ž [VideoCall] groupId for members: $groupId');
      if (groupId.isEmpty && widget.name.isNotEmpty) {
        final ids =
            await _resolveChatIdsFromChatsByName(widget.name, widget.callerName);
        final resolvedClassId = ids['classId'] ?? '';
        if (resolvedClassId.isNotEmpty) {
          print('âœ… [VideoCall] resolved classId from chats: $resolvedClassId');
          final ok = await _classMembersController.getClassMembers(
            resolvedClassId,
          );
          print('âœ… [VideoCall] getClassMembers ok: $ok');
          if (ok) {
            final myId = StorageUtil.getData(StorageUtil.userId);
            final members = _classMembersController.groupMemnersData ?? [];
            print('ðŸ‘¥ [VideoCall] class members count: ${members.length}');
            _nameQueue
              ..clear()
              ..addAll(
                members
                    .where((m) => m.auth?.id != myId)
                    .map((m) => m.auth?.person?.name ?? 'User')
                    .toList(),
              );
            print('ðŸ§¾ [VideoCall] class nameQueue: $_nameQueue');
            if (_nameQueue.isNotEmpty) _forceMultiParty = true;
          }
          resolvedClassFromChats = true;
        }

        groupId = ids['groupId'] ?? '';
        if (groupId.isNotEmpty) {
          print('âœ… [VideoCall] resolved groupId from chats: $groupId');
        }
      }
      if (resolvedClassFromChats) {
        // Skip group fetch if class was resolved
      } else if (groupId.isEmpty) {
        await _loadNamesFromCallLog();
        return;
      } else {
        final ok = await _groupMembersController.getGroupMembers(groupId);
        print('âœ… [VideoCall] getGroupMembers ok: $ok');
        if (!ok) return;

        final myId = StorageUtil.getData(StorageUtil.userId);
        final members = _groupMembersController.groupMemnersData ?? [];
        print('ðŸ‘¥ [VideoCall] members count: ${members.length}');
        _nameQueue
          ..clear() 
          ..addAll(
            members
                .where((m) => m.auth?.id != myId)
                .map((m) => m.auth?.person?.name ?? 'User')
                .toList(),
          );
        print('ðŸ§¾ [VideoCall] nameQueue: $_nameQueue');
        if (_nameQueue.isNotEmpty) _forceMultiParty = true;
      }
    }

    // Assign names to already-joined uids (if any)
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

        // CLASS by classId in chat list + name match (from item.name)
        if (type == 'CLASS') {
          final chatName =
              item['name']?.toString().trim().toLowerCase() ?? '';
          if (chatName.isNotEmpty && chatName == target) {
            final id = item['classId']?.toString();
            if (id != null && id.isNotEmpty) {
              classId = id;
              break;
            }
          }
        }

        // GROUP
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

        // COMMUNITY (some APIs use community for group)
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

        // CLASS
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

        // Fallback: match by participants when name match fails
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
            final name =
                person is Map ? person['name']?.toString().trim().toLowerCase() : '';
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
      print('âŒ [VideoCall] resolve groupId failed: $e');
    }
    return {'groupId': groupId, 'classId': classId};
  }

  void _assignNameForUid(int uid) {
    if (_uidToName.containsKey(uid)) return;
    if (_nameQueue.isEmpty) return;
    _uidToName[uid] = _nameQueue.removeAt(0);
    print('ðŸ·ï¸ [VideoCall] assign uid $uid -> ${_uidToName[uid]}');
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
      print('ðŸ§¾ [VideoCall] fallback nameQueue from call log: $_nameQueue');
      if (_nameQueue.isEmpty && !_callLogRetryDone) {
        _callLogRetryDone = true;
        Future.delayed(const Duration(milliseconds: 1500), () async {
          if (!mounted) return;
          await _loadNamesFromCallLog();
        });
      }
    } catch (e) {
      print('âŒ [VideoCall] fallback name load failed: $e');
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
    print('ðŸ” Invalid token â€” refreshing...');

    final bool ok = await _callController.getToken(
      callId: widget.callId,
      roomId: widget.channelName,
    );

    if (!ok) {
      print('âŒ Token refresh failed: ${_callController.errorMessage}');
      _tokenRefreshing = false;
      return;
    }

    _currentToken = _callController.token;
    print('âœ… Token refreshed â€” rejoining...');

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

  // â”€â”€â”€ Video tile helper â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
        ],
      ),
    );
  }

  // â”€â”€â”€ "Me" small overlay â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _meOverlay() {
    return Positioned(
      top: 20,
      right: 12,
      width: 120,
      height: 160,
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

  // â”€â”€â”€ LAYOUT: 2 User (1 remote + me) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // Sketch: User full screen, me small top-right
  Widget _layout2User() {
    return Stack(
      children: [
        Positioned.fill(
          child: _videoTile(
            _remoteUids[0],
            label: _labelForUid(
              _remoteUids[0],
              _fallbackLabel(0, _remoteUids[0]),
            ),
          ),
        ),
        _meOverlay(),
      ],
    );
  }

  // â”€â”€â”€ LAYOUT: 3 User (2 remote + me) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // Sketch: User1 top big, User2 bottom half, me small top-right
  Widget _layout3User() {
    return Stack(
      children: [
        Column(
          children: [
            // User1 â€” top 60%
            Expanded(
              flex: 6,
              child: SizedBox(
                width: double.infinity,
                child: _videoTile(
                  _remoteUids[0],
                  label: _labelForUid(
                    _remoteUids[0],
                    _fallbackLabel(0, _remoteUids[0]),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),
            // User2 â€” bottom 40%
            Expanded(
              flex: 4,
              child: SizedBox(
                width: double.infinity,
                child: _videoTile(
                  _remoteUids[1],
                  label: _labelForUid(_remoteUids[1], _fallbackLabel(1, _remoteUids[1])),
                ),
              ),
            ),
          ],
        ),
        _meOverlay(),
      ],
    );
  }

  // â”€â”€â”€ LAYOUT: 4 User (3 remote + me) â€” 2x2 grid â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // Sketch: User1 | User2 / User3 | Me â€” à¦¸à¦¬ equal
  Widget _layout4User() {
    final allUids = [..._remoteUids.take(3), 0]; // 3 remote + local (me)
    final labels = [
      _labelForUid(_remoteUids[0], _fallbackLabel(0, _remoteUids[0])),
      _labelForUid(_remoteUids[1], _fallbackLabel(1, _remoteUids[1])),
      _labelForUid(_remoteUids[2], _fallbackLabel(2, _remoteUids[2])),
      'Me',
    ];

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

  // â”€â”€â”€ LAYOUT: 5+ User â€” scrollable grid â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
        final label = allUids[index] == 0
            ? 'Me'
            : _labelForUid(allUids[index], _fallbackLabel(index, allUids[index]));
        return _videoTile(allUids[index], label: label, radius: 0);
      },
    );
  }

  // â”€â”€â”€ Pick correct layout based on user count â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
          // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
          // WAITING SCREEN â€” call start à¦¹à¦“à¦¯à¦¼à¦¾à¦° à¦†à¦—à§‡
          // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
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
                      // Local preview
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

          // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
          // CALL LAYOUT â€” call à¦šà¦²à¦¾à¦•à¦¾à¦²à§€à¦¨
          // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
          if (hasRemoteUser && !callProgress) ...[
            // Video area â€” controls à¦à¦° à¦‰à¦ªà¦°à§‡ à¦ªà¦°à§à¦¯à¦¨à§à¦¤
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 90,
              child: _buildCallLayout(),
            ),

            // â”€â”€â”€ TIMER: bottom center over caller canvas â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
                        horizontal: 8,
                        vertical: 3,
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
                            size: 4,
                          ),
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

            // â”€â”€â”€ BOTTOM CONTROLS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
                      // End call â€” bigger
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
