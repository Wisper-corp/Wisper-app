// ignore_for_file: library_prefixes, avoid_print
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/core/widgets/common/circle_icon.dart';
import 'package:wisper/app/modules/calls/controller/call_controller.dart';
import 'package:wisper/app/modules/calls/views/audio_call.dart';
import 'package:wisper/app/modules/calls/views/video_call.dart';
import 'package:wisper/app/urls.dart';
import 'package:wisper/gen/assets.gen.dart';

class SocketService extends GetxController {
  late IO.Socket _socket;

  RxBool isLoading = false.obs;
  RxBool isConnected = false.obs;

  final _messageList = <Map<String, dynamic>>[].obs;
  final _socketFriendList = <Map<String, dynamic>>[].obs;
  final _notificationsList = <Map<String, dynamic>>[].obs;
  final _incomingCall = Rxn<Map<String, dynamic>>();

  // VideoCallPage এই observable watch করবে
  final RxBool callDeclinedSignal = false.obs;
  final RxBool callEndedSignal = false.obs;

  RxList<Map<String, dynamic>> get messageList => _messageList;
  RxList<Map<String, dynamic>> get socketFriendList => _socketFriendList;
  RxList<Map<String, dynamic>> get notificationsList => _notificationsList;
  Rxn<Map<String, dynamic>> get incomingCall => _incomingCall;
  IO.Socket get socket => _socket;

  late final CallController callController;

  Future<SocketService> init() async {
    print('🔌 Initializing socket service. Connecting...');

    callController = Get.put(CallController());

    final token = StorageUtil.getData(StorageUtil.userAccessToken);
    final userId = StorageUtil.getData(StorageUtil.userId);

    print('Token: $token');
    print('User ID: $userId');

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
      print('✅ Successfully connected to the server!');
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
      print('🔴 Socket disconnected');
      isConnected.value = false;
    });

    _socket.onReconnect((attempt) {
      print('🟢 Reconnected successfully! Attempt: $attempt');
      isConnected.value = true;
      _socket.emit("connection", userId);
    });

    _socket.on('checking_notification', (data) {
      print('🔔 Notification data received:');
      print(data);
    });

    // 📞 Incoming Call Event
    _socket.on('callIncoming', (data) {
      print('📞 Incoming call data: $data');
      _incomingCall.value = data as Map<String, dynamic>;
      _showIncomingCallOverlay();
    });

    // ✅ callDeclined — Caller এর VideoCallPage বন্ধ করার signal
    _socket.on('callDeclined', (data) {
      print('📵 callDeclined received in SocketService: $data');
      callDeclinedSignal.value = true;

      // Incoming ringing dialog open থাকলে বন্ধ করো
      if (_incomingCall.value != null) {
        _incomingCall.value = null;
        if (Get.isDialogOpen ?? false) {
          Get.back();
        }
      }
    });

    // ✅ callEnded — VideoCallPage বন্ধ করার signal
    _socket.on('callEnded', (data) {
      print('📵 callEnded received in SocketService: $data');
      callEndedSignal.value = true;
    });

    // ✅ callCanceled — Caller cancel করলে Receiver এর incoming dialog বন্ধ হবে
    _socket.on('callCanceled', (data) {
      print('📵 callCanceled received in SocketService: $data');

      // VideoCallPage open থাকলে signal দাও
      callEndedSignal.value = true;

      // ✅ Incoming call dialog realtime বন্ধ করো
      if (_incomingCall.value != null) {
        _incomingCall.value = null;

        // Dialog open থাকলে বন্ধ করো
        if (Get.isDialogOpen ?? false) {
          Get.back();
        }

        // Receiver কে জানাও
        Get.snackbar(
          'Call Cancelled',
          'The caller has cancelled the call.',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      }
    });

    _socket.connect();
    return this;
  }

  // Signal reset করো — VideoCallPage dispose হলে call করবে
  void resetCallSignals() {
    callDeclinedSignal.value = false;
    callEndedSignal.value = false;
  }

  void _showIncomingCallOverlay() {
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }

    Get.dialog(
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.7),
      _IncomingCallDialog(
        callerName: _incomingCall.value?['groupName'] != null
            ? _incomingCall.value!['groupName']
            : _incomingCall.value?['callerName'],
        callerImage: _incomingCall.value?['groupName'] != null
            ? 'group'
            : _incomingCall.value?['callerImage'],
        onAccept: () => _handleAcceptCall(),
        onReject: () => _handleRejectCall(),
      ),
    );
  }

  Future<void> _handleAcceptCall() async {
    final roomId = _incomingCall.value?['roomId'];
    final callId = _incomingCall.value?['callId'];
    final type = _incomingCall.value?['type'];

    isLoading.value = true;

    final bool isSuccess = await callController.getToken(
      callId: callId,
      roomId: roomId,
    );

    isLoading.value = false;

    if (isSuccess) {
      Get.back();
      _socket.emit('callAccepted', {'callId': callId});

      // Signal reset করো নতুন call এর আগে
      resetCallSignals();

      type == 'AUDIO'
          ? Get.to(
              () => AudioCallPage(
                name: '',
                photoUrl: '',
                chatId: '',
                channelName: roomId,
                token: callController.token,
                uuid: callController.uuid,
                callId: callController.callId,
              ),
            )
          : Get.to(
              () => VideoCallPage(
                name: '',
                photoUrl: '',
                chatId: '',
                channelName: roomId,
                token: callController.token,
                uuid: callController.uuid,
                callId: callController.callId,
              ),
            );

      _incomingCall.value = null;
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
    print('Trying to reject call. Call Id: $callId');

    if (_socket.connected) {
      print('Socket connected → using emitWithAck');
      _socket.emitWithAck(
        'callDecline',
        {'callId': callId},
        ack: (response) {
          print('Server acknowledged: $response');
        },
      );
    } else {
      print('❌ Socket not connected → cannot emit');
    }

    print('❌ Call rejected (local)');
    _incomingCall.value = null;
    Get.back();
  }

  void disconnect() {
    if (_socket.connected || isConnected.value) {
      _socket.disconnect();
      print('🔌 Socket manually disconnected');
    }
    _socket.clearListeners();
    isConnected.value = false;
  }

  @override
  void onClose() {
    disconnect();
    super.onClose();
  }
}

class _IncomingCallDialog extends StatefulWidget {
  final String callerName;
  final String callerImage;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _IncomingCallDialog({
    required this.callerName,
    required this.callerImage,
    required this.onAccept,
    required this.onReject,
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
                        color: Color(0xff051B33),
                        iconColor: Color(0xff1F7DE9),
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
