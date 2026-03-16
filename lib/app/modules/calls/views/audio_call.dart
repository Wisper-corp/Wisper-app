import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wisper/app/modules/calls/controller/call_controller.dart';
import 'package:wisper/app/core/services/socket/socket_service.dart';
import 'package:wisper/app/modules/chat/controller/group/all_group_member_controller.dart';
import 'package:wisper/app/modules/chat/controller/class/class_member_controller.dart';
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/core/services/network_caller/network_caller.dart';
import 'package:wisper/app/core/services/network_caller/network_response.dart';
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
  bool _speakerEnabled = true;

  // ✅ Single remoteUid এর বদলে list — group call support
  final List<int> _remoteUids = [];

  String engineLog = 'Initializing...';
  bool callProgress = true;
  bool _isLeavingCall = false;

  DateTime? _callStartTime;

  SocketService socketService = Get.find<SocketService>();
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

  // ✅ কেউ join করেছে কিনা
  bool get hasRemoteUser => _remoteUids.isNotEmpty;
  bool get _isGroupCall =>
      (widget.groupId ?? '').isNotEmpty || widget.isGroupCall;
  bool get _isClassCall => (widget.classId ?? '').isNotEmpty;
  bool get _isMultiParty => _isGroupCall || _isClassCall || _forceMultiParty;

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
      _loadGroupMemberNames();
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

  Future<void> _loadGroupMemberNames() async {
    final classId = (widget.classId ?? '').trim();
    if (classId.isNotEmpty) {
      print('🔎 [AudioCall] classId for members: $classId');
      final ok = await _classMembersController.getClassMembers(classId);
      print('✅ [AudioCall] getClassMembers ok: $ok');
      if (!ok) return;

      final myId = StorageUtil.getData(StorageUtil.userId);
      final members = _classMembersController.groupMemnersData ?? [];
      print('👥 [AudioCall] class members count: ${members.length}');
      _nameQueue
        ..clear()
        ..addAll(
          members
              .where((m) => m.auth?.id != myId)
              .map((m) => m.auth?.person?.name ?? 'User')
              .toList(),
        );
      print('🧾 [AudioCall] class nameQueue: $_nameQueue');
      if (_nameQueue.isNotEmpty) _forceMultiParty = true;
    } else {
      var groupId = (widget.groupId ?? '').trim();
      bool resolvedClassFromChats = false;
      print('🔎 [AudioCall] groupId for members: $groupId');
      if (groupId.isEmpty && widget.name.isNotEmpty) {
        final ids =
            await _resolveChatIdsFromChatsByName(widget.name, widget.callerName);
        final resolvedClassId = ids['classId'] ?? '';
        if (resolvedClassId.isNotEmpty) {
          print('✅ [AudioCall] resolved classId from chats: $resolvedClassId');
          final ok = await _classMembersController.getClassMembers(
            resolvedClassId,
          );
          print('✅ [AudioCall] getClassMembers ok: $ok');
          if (ok) {
            final myId = StorageUtil.getData(StorageUtil.userId);
            final members = _classMembersController.groupMemnersData ?? [];
            print('👥 [AudioCall] class members count: ${members.length}');
            _nameQueue
              ..clear()
              ..addAll(
                members
                    .where((m) => m.auth?.id != myId)
                    .map((m) => m.auth?.person?.name ?? 'User')
                    .toList(),
              );
            print('🧾 [AudioCall] class nameQueue: $_nameQueue');
            if (_nameQueue.isNotEmpty) _forceMultiParty = true;
          }
          resolvedClassFromChats = true;
        }

        groupId = ids['groupId'] ?? '';
        if (groupId.isNotEmpty) {
          print('✅ [AudioCall] resolved groupId from chats: $groupId');
        }
      }
      if (resolvedClassFromChats) {
        // Skip group fetch if class was resolved
      } else if (groupId.isEmpty) {
        await _loadNamesFromCallLog();
        return;
      } else {
        final ok = await _groupMembersController.getGroupMembers(groupId);
        print('✅ [AudioCall] getGroupMembers ok: $ok');
        if (!ok) return;

        final myId = StorageUtil.getData(StorageUtil.userId);
        final members = _groupMembersController.groupMemnersData ?? [];
        print('👥 [AudioCall] members count: ${members.length}');
        _nameQueue
          ..clear()
          ..addAll(
            members
                .where((m) => m.auth?.id != myId)
                .map((m) => m.auth?.person?.name ?? 'User')
                .toList(),
          );
        print('🧾 [AudioCall] nameQueue: $_nameQueue');
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
      print('❌ [AudioCall] resolve groupId failed: $e');
    }
    return {'groupId': groupId, 'classId': classId};
  }

  void _assignNameForUid(int uid) {
    if (_uidToName.containsKey(uid)) return;
    if (_nameQueue.isEmpty) return;
    _uidToName[uid] = _nameQueue.removeAt(0);
    print('🏷️ [AudioCall] assign uid $uid -> ${_uidToName[uid]}');
  }

  String _labelForUid(int uid) {
    return _uidToName[uid] ?? 'User $uid';
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
      print('🧾 [AudioCall] fallback nameQueue from call log: $_nameQueue');
      if (_nameQueue.isEmpty && !_callLogRetryDone) {
        _callLogRetryDone = true;
        Future.delayed(const Duration(milliseconds: 1500), () async {
          if (!mounted) return;
          await _loadNamesFromCallLog();
        });
      }
    } catch (e) {
      print('❌ [AudioCall] fallback name load failed: $e');
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
                  if (_nameQueue.isEmpty) {
                    _loadNamesFromCallLog();
                  } else {
                    _assignNameForUid(rUid);
                  }
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
                _uidToName.remove(rUid);
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
                final label = (!_isMultiParty &&
                        idx == 0 &&
                        widget.name.isNotEmpty)
                    ? widget.name
                    : _labelForUid(uid);
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
