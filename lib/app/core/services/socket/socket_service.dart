// ignore_for_file: library_prefixes, avoid_print

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/core/widgets/common/circle_icon.dart';
import 'package:wisper/app/modules/calls/controller/call_controller.dart';
import 'package:wisper/app/modules/calls/views/audio_call.dart';
import 'package:wisper/app/modules/calls/views/video_call.dart';
import 'package:wisper/app/modules/chat/controller/group/group_info_controller.dart';
import 'package:wisper/app/urls.dart';
import 'package:wisper/gen/assets.gen.dart';
import 'dart:async';

class SocketService extends GetxController {
  late IO.Socket _socket;

  final AudioPlayer _incomingRingPlayer = AudioPlayer();

  RxBool isLoading = false.obs;
  RxBool isConnected = false.obs;

  final _messageList = <Map<String, dynamic>>[].obs;
  final _socketFriendList = <Map<String, dynamic>>[].obs;
  final _notificationsList = <Map<String, dynamic>>[].obs;
  final Rxn<Map<String, dynamic>> _incomingCall = Rxn<Map<String, dynamic>>();

  final RxBool callDeclinedSignal = false.obs;
  final RxBool callEndedSignal = false.obs;

  RxList<Map<String, dynamic>> get messageList => _messageList;
  RxList<Map<String, dynamic>> get socketFriendList => _socketFriendList;
  RxList<Map<String, dynamic>> get notificationsList => _notificationsList;
  Rxn<Map<String, dynamic>> get incomingCall => _incomingCall;

  IO.Socket get socket => _socket;

  CallController? _callController;
  CallController get callController => _callController!;

  bool _initialized = false;
  bool _callkitHandled = false;
  final Map<String, Map<String, dynamic>> _callInfoCache = {};
  final Set<String> _callkitShownKeys = {};
  bool _callkitShowing = false;

  // Pending call data — dashboard banner + incoming dialog এর জন্য
  final Rxn<Map<String, dynamic>> pendingCall = Rxn<Map<String, dynamic>>();

  @override
  void onInit() {
    super.onInit();

    // Restore pending call from storage (app launched from CallKit accept)
    final storedPending = StorageUtil.getData(StorageUtil.pendingCallKey);
    if (storedPending is Map) {
      try {
        final data = Map<String, dynamic>.from(storedPending);
        print('pendingCall restored from storage');
        _navigateToCallPageDirectFromData(data);
      } catch (e) {
        print('Failed to restore pendingCall: $e');
      }
    }

    // pendingCall এর মান যখনই সেট হবে, তখনই চেক করবে
    ever(pendingCall, (callData) {
      print('pendingCall CHANGED → exists? ${callData != null}');
      if (callData != null) {
        final currentState = SchedulerBinding.instance.lifecycleState;
        print('pendingCall set হয়েছে। Current lifecycle: $currentState');

        if (currentState == AppLifecycleState.resumed) {
          print('resumed state + pendingCall → dialog দেখানোর চেষ্টা করছি');
          checkAndShowPendingCallDialogIfNeeded();
        } else {
          print('pendingCall সেট হয়েছে কিন্তু resumed নয় → resume হলে দেখাবে');
        }
      }
    });
  }

  Future<SocketService> init() async {
    if (_initialized) {
      print('⚠️ SocketService already initialized — skipping');
      return this;
    }
    _initialized = true;

    print('🔌 Initializing socket service. Connecting...');

    await _incomingRingPlayer.setReleaseMode(ReleaseMode.loop);

    _callController = Get.put(CallController());

    final token = StorageUtil.getData(StorageUtil.userAccessToken);
    final userId = StorageUtil.getData(StorageUtil.userId);

    if (token == null || userId == null) {
      print('🔴 Token or User ID is missing!');
      return this;
    }

    _socket = IO.io(
      Urls.socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .enableAutoConnect()
          .setTimeout(10000)
          .build(),
    );

    _socket.onConnect((_) {
      print('✅ Connected!');
      isConnected.value = true;
      _socket.emit("connection", userId);
    });

    _socket.onConnectError((err) {
      print('🔴 Connection error: $err');
      isConnected.value = false;
    });

    _socket.onError((err) {
      print('🔴 Socket error: $err');
      isConnected.value = false;
    });

    _socket.onDisconnect((_) {
      print('🔴 Disconnected');
      isConnected.value = false;
    });

    _socket.onReconnect((attempt) {
      print('🟢 Reconnected! Attempt: $attempt');
      isConnected.value = true;
      _socket.emit("connection", userId);
    });

    _socket.on('callIncoming', (data) async {
      print('📞 Incoming call: $data');
      final normalized =
          await _normalizeCallDataAsync(data as Map<String, dynamic>);
      final callKey = _getCallKey(normalized);

      if (callKey.isNotEmpty && _callInfoCache.containsKey(callKey)) {
        // Keep previously resolved group name/image (avoid name flip)
        final cached = _callInfoCache[callKey]!;
        if (cached['groupName'] != null &&
            cached['groupName'].toString().isNotEmpty) {
          normalized['groupName'] = cached['groupName'];
        }
        if (cached['groupImage'] != null &&
            cached['groupImage'].toString().isNotEmpty) {
          normalized['groupImage'] = cached['groupImage'];
        }
      }

      if (callKey.isNotEmpty) {
        _callInfoCache[callKey] = Map<String, dynamic>.from(normalized);
      }

      // If we already have a group name for this call, do not downgrade to caller name
      final existing = _incomingCall.value;
      if (existing != null &&
          existing['groupName'] != null &&
          existing['groupName'].toString().isNotEmpty &&
          (normalized['groupName'] == null ||
              normalized['groupName'].toString().isEmpty)) {
        print('⚠️ Keeping existing groupName to avoid name flip');
        _incomingCall.value = {
          ...normalized,
          'groupName': existing['groupName'],
          'groupImage': existing['groupImage'] ?? normalized['groupImage'],
        };
      } else {
        _incomingCall.value = normalized;
      }

      final appState = SchedulerBinding.instance.lifecycleState;
      final isAppForeground = appState == AppLifecycleState.resumed;

      print('📱 App state: $appState | foreground: $isAppForeground');

      if (isAppForeground) {
        _startIncomingRingtone();
        _showIncomingCallOverlay();
      } else {
        await _showCallkitFromSocketData(normalized);
      }
    });

    _socket.on('callDeclined', (data) {
      print('📵 callDeclined: $data');
      callDeclinedSignal.value = true;
      _clearCallStates();
    });

    _socket.on('callEnded', (data) {
      print('📵 callEnded: $data');
      callEndedSignal.value = true;
      _clearCallStates();
    });

    _socket.on('callCanceled', (data) {
      print('📵 callCanceled: $data');
      callEndedSignal.value = true;
      _clearCallStates();

      Get.snackbar(
        'Call Cancelled',
        'The caller has cancelled the call.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    });

    _setupCallkitListeners();

    _socket.connect();

    return this;
  }

  // Pending call থেকে dialog দেখানোর ফাংশন
  void checkAndShowPendingCallDialogIfNeeded() {
    print('checkAndShowPendingCallDialogIfNeeded() কল হয়েছে');

    if (pendingCall.value == null) {
      print('কোনো pending call নেই → রিটার্ন করছি');
      return;
    }

    final callData = pendingCall.value!;
    final currentState = SchedulerBinding.instance.lifecycleState;
    print('Current lifecycle state: $currentState');

    if (currentState != AppLifecycleState.resumed) {
      print('resumed state-এ নেই → dialog দেখাচ্ছি না');
      return;
    }

    print('🔔 Incoming call dialog দেখাচ্ছি (pendingCall থেকে)');

    _startIncomingRingtone();

    Get.dialog(
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.7),
      _IncomingCallDialog(
        isGroup: false,
        callerName: callData['callerName'] ?? 'Unknown',
        callerImage: callData['callerImage'] ?? '',
        onAccept: () => _joinCallFromPending(callData),
        onReject: () {
          if (_socket.connected) {
            _socket.emit('callDecline', {'callId': callData['callId']});
          }
          _clearCallStates();
        },
      ),
    ).then((_) {
      print('Dialog বন্ধ হয়েছে');
    });
  }

  void _joinCallFromPending(Map<String, dynamic> callData) {
    print('Accept করা হয়েছে (pending dialog থেকে)');
    _clearCallStates();

    final callType = callData['callType'] ?? 'AUDIO';

    if (callType == 'VIDEO') {
      Get.to(() => VideoCallPage(
            name: callData['callerName'] ?? '',
            photoUrl: callData['callerImage'] ?? '',
            chatId: '',
            channelName: callData['channelName'] ?? '',
            token: callData['token'] ?? '',
            uuid: callData['uuid'] ?? 0,
            callId: callData['callId'] ?? '',
            groupId: callData['groupId'],
            classId: callData['classId'],
            isGroupCall: callData['isGroupCall'] == true,
            callerName: callData['callerName'],
          ));
    } else {
      Get.to(() => AudioCallPage(
            name: callData['callerName'] ?? '',
            photoUrl: callData['callerImage'] ?? '',
            chatId: '',
            channelName: callData['channelName'] ?? '',
            token: callData['token'] ?? '',
            uuid: callData['uuid'] ?? 0,
            callId: callData['callId'] ?? '',
            groupId: callData['groupId'],
            classId: callData['classId'],
            isGroupCall: callData['isGroupCall'] == true,
            callerName: callData['callerName'],
          ));
    }
  }

  void _clearCallStates() {
    print('Clearing all call states');
    pendingCall.value = null;
    _incomingCall.value = null;
    StorageUtil.deleteData(StorageUtil.pendingCallKey);
    _callInfoCache.clear();
    _callkitShownKeys.clear();
    _callkitShowing = false;
    _stopIncomingRingtone();
    FlutterCallkitIncoming.endAllCalls();
    if (Get.isDialogOpen ?? false) Get.back();
  }

  // ──────────────────────────────────────────────────────────
  // বাকি সব ফাংশন (আগের মতোই রাখা হয়েছে)
  // ──────────────────────────────────────────────────────────

  void _showIncomingCallOverlay() {
    if (Get.isDialogOpen ?? false) Get.back();

    Get.dialog(
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.7),
      _IncomingCallDialog(
        isGroup: _incomingCall.value?['groupName'] != null,
        callerName: _incomingCall.value?['groupName'] != null
            ? _incomingCall.value!['groupName']
            : _incomingCall.value?['callerName'],
        callerImage: _incomingCall.value?['groupName'] != null &&
                _incomingCall.value?['groupImage'] == null
            ? 'group'
            : _incomingCall.value?['groupName'] != null &&
                    _incomingCall.value?['groupImage'] != null
                ? _incomingCall.value!['groupImage']
                : _incomingCall.value?['callerImage'],
        onAccept: () => _handleAcceptCall(),
        onReject: () => _handleRejectCall(),
      ),
    );
  }

  Future<void> _showCallkitFromSocketData(Map<String, dynamic> data) async {
    if (_callkitShowing) {
      print('⚠️ Callkit already showing — skipping');
      return;
    }

    final callKey = _getCallKey(data);
    if (callKey.isNotEmpty && _callkitShownKeys.contains(callKey)) {
      print('⚠️ Callkit already shown for $callKey — skipping');
      return;
    }

    final callId = data['callId'] ?? data['call_id'] ?? '';
    final callerName = data['groupName'] ?? data['callerName'] ?? 'Unknown';
    final callerImage = data['groupImage'] ?? data['callerImage'] ?? '';
    final callType = data['type'] == 'VIDEO' ? 1 : 0;
    final roomId = data['roomId'] ?? '';

    final params = CallKitParams(
      id: callId,
      nameCaller: callerName,
      appName: 'Wisper',
      avatar: callerImage.isNotEmpty ? callerImage : null,
      handle: callerName,
      type: callType,
      textAccept: 'Accept',
      textDecline: 'Decline',
      missedCallNotification: const NotificationParams(
        showNotification: true,
        isShowCallback: true,
        subtitle: 'Missed call',
        callbackText: 'Call back',
      ),
      duration: 45000,
      extra: {
        'call_id': callId,
        'channel_name': roomId,
        'agora_token': data['token'] ?? '',
        'call_type': data['type'] ?? 'AUDIO',
        'caller_id': data['callerId'] ?? '',
        'caller_name': callerName,
        'caller_image': callerImage,
        'group_id': data['groupId'] ?? '',
        'class_id': data['classId'] ?? '',
        'group_name': data['groupName'] ?? '',
        'mode': data['mode'] ?? '',
      },
      android: const AndroidParams(
        isCustomNotification: true,
        isShowLogo: false,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#1E1E1E',
        actionColor: '#4CAF50',
        textColor: '#ffffff',
        isShowCallID: false,
      ),
      ios: const IOSParams(
        iconName: 'AppIcon',
        handleType: 'generic',
        supportsVideo: true,
        maximumCallGroups: 1,
        maximumCallsPerCallGroup: 1,
        audioSessionMode: 'default',
        audioSessionActive: true,
        audioSessionPreferredSampleRate: 44100.0,
        audioSessionPreferredIOBufferDuration: 0.005,
        supportsDTMF: true,
        supportsHolding: true,
        supportsGrouping: false,
        supportsUngrouping: false,
        ringtonePath: 'system_ringtone_default',
      ),
    );

    await FlutterCallkitIncoming.showCallkitIncoming(params);
    if (callKey.isNotEmpty) _callkitShownKeys.add(callKey);
    _callkitShowing = true;
    print('📞 Callkit shown: $callerName | callId: $callId | roomId: $roomId');
  }

  Future<Map<String, dynamic>> _normalizeCallDataAsync(
    Map<String, dynamic> data,
  ) async {
    final map = Map<String, dynamic>.from(data);

    final mode = (map['mode'] ??
            map['callMode'] ??
            map['call_mode'] ??
            '')
        .toString();

    final groupId = (map['groupId'] ??
            map['group_id'] ??
            map['groupID'] ??
            (map['group'] is Map ? map['group']['id'] : null) ??
            (map['groupInfo'] is Map ? map['groupInfo']['id'] : null) ??
            (map['community'] is Map ? map['community']['id'] : null))
        ?.toString();
    final classId = (map['classId'] ??
            map['class_id'] ??
            (map['class'] is Map ? map['class']['id'] : null))
        ?.toString();
    final className = map['className'] ??
        map['class_name'] ??
        (map['class'] is Map ? map['class']['name'] : null);
    final classImage = map['classImage'] ??
        map['class_image'] ??
        (map['class'] is Map ? map['class']['image'] : null);

    final groupName = map['groupName'] ??
        map['group_name'] ??
        (map['group'] is Map ? map['group']['name'] : null) ??
        (map['groupInfo'] is Map ? map['groupInfo']['name'] : null);

    final groupImage = map['groupImage'] ??
        map['group_image'] ??
        (map['group'] is Map ? map['group']['image'] : null) ??
        (map['groupInfo'] is Map ? map['groupInfo']['image'] : null);

    if (groupName != null) map['groupName'] = groupName;
    if (groupImage != null) map['groupImage'] = groupImage;
    if (groupId != null && groupId.isNotEmpty) map['groupId'] = groupId;
    if (classId != null && classId.isNotEmpty) map['classId'] = classId;
    if ((map['groupName'] == null || map['groupName'].toString().isEmpty) &&
        className != null) {
      map['groupName'] = className;
    }
    if ((map['groupImage'] == null || map['groupImage'].toString().isEmpty) &&
        classImage != null) {
      map['groupImage'] = classImage;
    }

    // If group info missing but groupId exists, fetch from API
    if ((mode == 'GROUP' || mode == 'GROUP_CALL') &&
        (map['groupName'] == null || map['groupName'].toString().isEmpty) &&
        groupId != null &&
        groupId.isNotEmpty) {
      try {
        final controller = Get.put(GroupInfoController());
        final ok = await controller
            .getGroupInfo(groupId)
            .timeout(const Duration(seconds: 2), onTimeout: () => false);
        if (ok) {
          final info = controller.groupInfoData;
          if (info?.name != null && info!.name!.isNotEmpty) {
            map['groupName'] = info.name;
          }
          if (info?.image != null && info!.image!.isNotEmpty) {
            map['groupImage'] = info.image;
          }
        }
      } catch (_) {}
    }

    final bool isGroup = (mode == 'GROUP' || mode == 'GROUP_CALL') ||
        (mode == 'CLASS' || mode == 'CLASS_CALL') ||
        (classId != null && classId.isNotEmpty) ||
        (map['groupName'] != null && map['groupName'].toString().isNotEmpty) ||
        (map['groupImage'] != null &&
            map['groupImage'].toString().isNotEmpty);

    if (isGroup &&
        (map['groupName'] == null || map['groupName'].toString().isEmpty)) {
      map['groupName'] = 'Group Call';
    }

    // If this is a group call, always prefer group name over caller name
    if (isGroup &&
        map['groupName'] != null &&
        map['groupName'].toString().isNotEmpty) {
      map['mode'] = 'GROUP_CALL';
      map['callerName'] = map['groupName'];
    }

    return map;
  }

  String _getCallKey(Map<String, dynamic> data) {
    final callId = (data['callId'] ?? data['call_id'] ?? '').toString();
    if (callId.isNotEmpty) return callId;
    final roomId = (data['roomId'] ?? data['room_id'] ?? '').toString();
    return roomId;
  }

  void _setupCallkitListeners() {
    FlutterCallkitIncoming.onEvent.listen((CallEvent? event) async {
      if (event == null) return;
      print('📞 Callkit event: ${event.event} | body: ${event.body}');

      switch (event.event) {
        case Event.actionCallAccept:
          _callkitShowing = false;
          await _handleCallkitAccept(event.body);
          break;

        case Event.actionCallDecline:
          _callkitShowing = false;
          _handleCallkitDecline(event.body);
          break;

        case Event.actionCallTimeout:
          _callkitShowing = false;
          _stopIncomingRingtone();
          _incomingCall.value = null;
          pendingCall.value = null;
          break;

        case Event.actionDidUpdateDevicePushTokenVoip:
          final newToken = event.body['deviceTokenVoIP'];
          if (newToken != null) {
            print('📱 VoIP token updated: $newToken');
          }
          break;

        default:
          break;
      }
    });
  }

  Future<void> _handleCallkitAccept(Map<String, dynamic> body) async {
    if (_callkitHandled) {
      print('⚠️ Callkit already handled — skipping duplicate accept');
      return;
    }
    _callkitHandled = true;

    print('✅ Callkit accept raw body: $body');

    final rawExtra = body['extra'];
    final Map<String, dynamic> extra = rawExtra != null
        ? Map<String, dynamic>.from(rawExtra as Map)
        : {};

    print('📦 Extra: $extra');

    final callId = (extra['call_id'] ?? body['id'] ?? '').toString();
    final channelName = (extra['channel_name'] ?? '').toString();
    final callType = (extra['call_type'] ?? 'AUDIO').toString();
    final callerName =
        (extra['caller_name'] ?? body['nameCaller'] ?? '').toString();
    final callerImage =
        (extra['caller_image'] ?? body['avatar'] ?? '').toString();
    final groupId =
        (extra['group_id'] ?? extra['groupId'] ?? '').toString();
    final classId =
        (extra['class_id'] ?? extra['classId'] ?? '').toString();
    final bool isGroupCall =
        (extra['mode'] ?? '').toString() == 'GROUP' ||
        (extra['mode'] ?? '').toString() == 'GROUP_CALL' ||
        groupId.isNotEmpty ||
        classId.isNotEmpty ||
        (extra['group_name'] ?? extra['groupName'] ?? '').toString().isNotEmpty;

    print('📞 Parsed → callId: $callId | channelName: $channelName | type: $callType');

    if (callId.isEmpty || channelName.isEmpty) {
      print('❌ callId or channelName is empty — cannot proceed');
      FlutterCallkitIncoming.endAllCalls();
      _callkitHandled = false;
      return;
    }

    isLoading.value = true;

    final agoraTokenFromExtra = (extra['agora_token'] ?? '').toString();

    String tokenToUse = '';
    int uuidToUse = 0;

    // Always request a fresh token for the receiver to avoid uid mismatch/expiry
    await _waitForSocketConnection();

    final bool isSuccess = await callController.getToken(
      callId: callId,
      roomId: channelName,
    );

    if (!isSuccess) {
      // Fallback to extra token if API fails
      if (agoraTokenFromExtra.isNotEmpty) {
        print('⚠️ getToken failed — falling back to extra token');
        tokenToUse = agoraTokenFromExtra;
        uuidToUse = callController.uuid;
      } else {
        print('❌ getToken failed: ${callController.errorMessage}');
        isLoading.value = false;
        FlutterCallkitIncoming.endAllCalls();
        _callkitHandled = false;
        return;
      }
    } else {
      tokenToUse = callController.token;
      uuidToUse = callController.uuid;
    }

    if (_socket.connected) {
      _socket.emit('callAccepted', {'callId': callId});
      print('✅ callAccepted emitted');
    }

    isLoading.value = false;

    if (tokenToUse.isEmpty) {
      print('❌ No token available — cannot navigate');
      FlutterCallkitIncoming.endAllCalls();
      _callkitHandled = false;
      return;
    }

    _stopIncomingRingtone();

    resetCallSignals();
    _callkitHandled = false;
    _incomingCall.value = null;

    print('🚀 Navigating to ${callType == 'VIDEO' ? 'Video' : 'Audio'}CallPage');
    print('   room: $channelName');
    print('   token: $tokenToUse');
    print('   uuid: $uuidToUse');
    print('   callId: $callId');

    final data = {
      'callType': callType,
      'callerName': callerName,
      'callerImage': callerImage,
      'channelName': channelName,
      'token': tokenToUse,
      'uuid': uuidToUse,
      'callId': callId,
      'groupId': groupId,
      'classId': classId,
      'isGroupCall': isGroupCall,
    };

    // Save in storage for cold-start resume flow
    StorageUtil.saveData(StorageUtil.pendingCallKey, data);

    await _navigateToCallPageDirectFromData(data);
  }

  void _handleCallkitDecline(Map<String, dynamic> body) {
    print('❌ Callkit decline: $body');

    final rawExtra = body['extra'];
    final Map<String, dynamic> extra = rawExtra != null
        ? Map<String, dynamic>.from(rawExtra as Map)
        : {};

    final callId = (extra['call_id'] ?? body['id'] ?? '').toString();

    if (_socket.connected) {
      _socket.emitWithAck(
        'callDecline',
        {'callId': callId},
        ack: (response) => print('callDecline ack: $response'),
      );
    }

    _clearCallStates();
  }

  Future<void> handleCallkitAcceptFromTerminated(Map<String, dynamic> body) async {
    print('📞 Callkit accept from terminated state');
    await _handleCallkitAccept(body);
  }

  Future<void> _handleAcceptCall() async {
    final roomId = _incomingCall.value?['roomId'];
    final callId = _incomingCall.value?['callId'];
    final type = _incomingCall.value?['type'];
    final callerName = _incomingCall.value?['groupName'] ??
        _incomingCall.value?['callerName'] ??
        '';
    final callerImage = _incomingCall.value?['groupImage'] ??
        _incomingCall.value?['callerImage'] ??
        '';
    final groupId = _incomingCall.value?['groupId'];
    final classId = _incomingCall.value?['classId'];
    final bool isGroupCall = (_incomingCall.value?['mode'] == 'GROUP' ||
        _incomingCall.value?['mode'] == 'GROUP_CALL' ||
        groupId != null ||
        classId != null ||
        (_incomingCall.value?['groupName'] ?? '').toString().isNotEmpty);

    isLoading.value = true;

    final bool isSuccess = await callController.getToken(
      callId: callId,
      roomId: roomId,
    );

    isLoading.value = false;

    if (isSuccess) {
      await _stopIncomingRingtone();
      Get.back();
      _socket.emit('callAccepted', {'callId': callId});
      resetCallSignals();

      type == 'AUDIO'
          ? Get.to(
              () => AudioCallPage(
                name: callerName,
                photoUrl: callerImage,
                chatId: '',
                channelName: roomId,
                token: callController.token,
                uuid: callController.uuid,
                callId: callController.callId,
                groupId: groupId,
                classId: classId,
                isGroupCall: isGroupCall,
                callerName: callerName,
              ),
            )
          : Get.to(
              () => VideoCallPage(
                name: callerName,
                photoUrl: callerImage,
                chatId: '',
                channelName: roomId,
                token: callController.token,
                uuid: callController.uuid,
                callId: callController.callId,
                groupId: groupId,
                classId: classId,
                isGroupCall: isGroupCall,
                callerName: callerName,
              ),
            );

      _incomingCall.value = null;
      pendingCall.value = null;
    } else {
      Get.snackbar(
        'Error',
        callController.errorMessage,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  void _handleRejectCall() {
    final callId = _incomingCall.value?['callId'];
    print('❌ Rejecting call. callId: $callId');

    if (_socket.connected) {
      _socket.emitWithAck(
        'callDecline',
        {'callId': callId},
        ack: (response) => print('callDecline ack: $response'),
      );
    }

    _clearCallStates();
  }

  Future<void> _startIncomingRingtone() async {
    try {
      await _incomingRingPlayer.play(AssetSource('IncomingCallRingtone.mp3'));
      print('🔔 Ringtone started');
    } catch (e) {
      print('Ringtone error: $e');
    }
  }

  Future<void> _stopIncomingRingtone() async {
    try {
      await _incomingRingPlayer.stop();
      print('🔕 Ringtone stopped');
    } catch (e) {
      print('Stop ringtone error: $e');
    }
  }

  void resetCallSignals() {
    callDeclinedSignal.value = false;
    callEndedSignal.value = false;
  }

  Future<void> _waitForSocketConnection() async {
    if (_socket.connected) return;
    print('⏳ Waiting for socket connection...');
    for (int i = 0; i < 10; i++) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (_socket.connected) return;
    }
    print('⚠️ Socket not connected after 5s');
  }

  Future<void> _navigateToCallPageDirectFromData(
    Map<String, dynamic> data,
  ) async {
    final callType = (data['callType'] ?? 'AUDIO').toString();
    final callerName = (data['callerName'] ?? '').toString();
    final callerImage = (data['callerImage'] ?? '').toString();
    final channelName = (data['channelName'] ?? '').toString();
    final token = (data['token'] ?? '').toString();
    final uuid = data['uuid'] is int ? data['uuid'] as int : 0;
    final callId = (data['callId'] ?? '').toString();
    final groupId = (data['groupId'] ?? '').toString();
    final classId = (data['classId'] ?? '').toString();
    final bool isGroupCall = data['isGroupCall'] == true;

    // Wait for app to be resumed and Navigator ready (cold start from CallKit)
    for (int i = 0; i < 20; i++) {
      final state = SchedulerBinding.instance.lifecycleState;
      final isResumed = state == AppLifecycleState.resumed;
      if (isResumed && Get.context != null) break;
      await Future.delayed(const Duration(milliseconds: 300));
    }

    if (Get.context == null ||
        SchedulerBinding.instance.lifecycleState != AppLifecycleState.resumed) {
      // Fallback: keep pendingCall so UI can show banner/dialog if needed
      pendingCall.value = {
        'callType': callType,
        'callerName': callerName,
        'callerImage': callerImage,
        'channelName': channelName,
        'token': token,
        'uuid': uuid,
        'callId': callId,
        'groupId': groupId,
        'classId': classId,
        'isGroupCall': isGroupCall,
      };
      StorageUtil.saveData(StorageUtil.pendingCallKey, pendingCall.value);
      print('⚠️ Navigator not ready — pendingCall fallback set');
      return;
    }

    // Clear any pending state so no banner/dialog appears
    pendingCall.value = null;
    StorageUtil.deleteData(StorageUtil.pendingCallKey);

    if (callType == 'VIDEO') {
      Get.to(() => VideoCallPage(
            name: callerName,
            photoUrl: callerImage,
            chatId: '',
            channelName: channelName,
            token: token,
            uuid: uuid,
            callId: callId,
            groupId: groupId.isEmpty ? null : groupId,
            classId: classId.isEmpty ? null : classId,
            isGroupCall: isGroupCall,
            callerName: callerName,
          ));
    } else {
      Get.to(() => AudioCallPage(
            name: callerName,
            photoUrl: callerImage,
            chatId: '',
            channelName: channelName,
            token: token,
            uuid: uuid,
            callId: callId,
            groupId: groupId.isEmpty ? null : groupId,
            classId: classId.isEmpty ? null : classId,
            isGroupCall: isGroupCall,
            callerName: callerName,
          ));
    }
  }

  void disconnect() {
    if (_socket.connected || isConnected.value) {
      _socket.disconnect();
      print('🔌 Socket disconnected');
    }
    _socket.clearListeners();
    isConnected.value = false;
  }

  @override
  void onClose() {
    _stopIncomingRingtone();
    _incomingRingPlayer.dispose();
    disconnect();
    super.onClose();
  }
}

// Incoming Call Dialog Widget (আগের মতোই রাখা হয়েছে)
class _IncomingCallDialog extends StatefulWidget {
  final String callerName;
  final String callerImage;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final bool isGroup;

  const _IncomingCallDialog({
    required this.callerName,
    required this.callerImage,
    required this.onAccept,
    required this.onReject,
    required this.isGroup,
  });

  @override
  State<_IncomingCallDialog> createState() => _IncomingCallDialogState();
}

class _IncomingCallDialogState extends State<_IncomingCallDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xff1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Incoming Call...',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.green, width: 2.5),
                ),
                child: widget.callerImage == 'group'
                    ? CircleIconWidget(
                        color: const Color(0xff051B33),
                        iconColor: const Color(0xff1F7DE9),
                        iconRadius: 35,
                        radius: 35,
                        imagePath: Assets.images.userGroup.keyName,
                        onTap: () {},
                      )
                    : CircleAvatar(
                        radius: 45,
                        backgroundColor: const Color(0xff2A2A2A),
                        backgroundImage: widget.callerImage.isNotEmpty
                            ? NetworkImage(widget.callerImage)
                            : null,
                        child: widget.callerImage.isEmpty
                            ? const Icon(
                                Icons.person,
                                size: 45,
                                color: Colors.white70,
                              )
                            : null,
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.callerName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            widget.isGroup
                ? const Text(
                    'Group',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  )
                : const SizedBox.shrink(),
            const SizedBox(height: 8),
            const Text(
              'is calling you...',
              style: TextStyle(color: Colors.white38, fontSize: 13),
            ),
            const SizedBox(height: 36),
            Obx(() {
              final socketService = Get.find<SocketService>();
              if (socketService.isLoading.value) {
                return const Column(
                  children: [
                    CircularProgressIndicator(color: Colors.green),
                    SizedBox(height: 12),
                    Text(
                      'Connecting...',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ],
                );
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      GestureDetector(
                        onTap: widget.onReject,
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.call_end,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Decline',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      GestureDetector(
                        onTap: widget.onAccept,
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.call,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Accept',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
