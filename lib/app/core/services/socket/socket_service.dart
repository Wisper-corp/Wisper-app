// ignore_for_file: library_prefixes, avoid_print
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/modules/calls/controller/call_controller.dart';
import 'package:wisper/app/modules/calls/views/video_call.dart';
import 'package:wisper/app/urls.dart';

class SocketService extends GetxController {
  late IO.Socket _socket;

  RxBool isLoading = false.obs;
  RxBool isConnected = false.obs;

  final _messageList = <Map<String, dynamic>>[].obs;
  final _socketFriendList = <Map<String, dynamic>>[].obs;
  final _notificationsList = <Map<String, dynamic>>[].obs;
  final _incomingCall = Rxn<Map<String, dynamic>>();

  RxList<Map<String, dynamic>> get messageList => _messageList;
  RxList<Map<String, dynamic>> get socketFriendList => _socketFriendList;
  RxList<Map<String, dynamic>> get notificationsList => _notificationsList;
  Rxn<Map<String, dynamic>> get incomingCall => _incomingCall;
  IO.Socket get socket => _socket;

  // ✅ Get.put() দিয়ে রাখো যাতে GetX manage করে
  late final CallController callController;

  Future<SocketService> init() async {
    print('🔌 Initializing socket service. Connecting...');

    // ✅ CallController এখানে initialize করো
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

    _socket.on('callDeclined', (data) {
      print('Call Declined111111111111: $data');
    });

    _socket.connect();
    return this;
  }

  void _showIncomingCallOverlay() {
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }

    Get.dialog(
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.7),
      _IncomingCallDialog(
        callerName: _incomingCall.value?['callerName'] ?? 'Unknown',
        callerImage: _incomingCall.value?['callerImage'] ?? '',
        onAccept: () => _handleAcceptCall(),
        onReject: () => _handleRejectCall(),
      ),
    );
  }

  // ✅ Accept Call — clean ও আলাদা method
  Future<void> _handleAcceptCall() async {
    final roomId = _incomingCall.value?['roomId'];
    final callId = _incomingCall.value?['callId'];
    final uToken = _incomingCall.value?['token'];
    // final callerName = _incomingCall.value?['callerName'] ?? '';
    // final callerImage = _incomingCall.value?['callerImage'] ?? '';
    // final chatId = _incomingCall.value?['chatId'] ?? '';

    // Loading দেখাও
    isLoading.value = true;

    final bool isSuccess = await callController.getToken(
      callId: callId,
      roomId: roomId,
    );

    isLoading.value = false;

    if (isSuccess) {
      // ✅ Dialog বন্ধ করো তারপর navigate করো
      Get.back();
      _socket.emit('callAccepted', {'callerId': callId});

      Get.to(
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
      // ❌ Error হলে snackbar দেখাও, dialog বন্ধ করো না
      Get.snackbar(
        'Error',
        callController.errorMessage,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  // ✅ Reject Call — clean ও আলাদা method
  void _handleRejectCall() {
    print('Call Id: ${_incomingCall.value?['callId']}');
    _socket.emit('callDecline', {'callerId': _incomingCall.value?['callId']});
    print('❌ Call rejected');
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

// ───────────────────────────────────────────
// 📞 Incoming Call Dialog Widget
// ───────────────────────────────────────────
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
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 24),

            // ✅ Pulsing Avatar
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.green, width: 2.5),
                ),
                child: CircleAvatar(
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

            // ✅ Loading indicator দেখাও accept করার পর
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
                  // ❌ Reject
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

                  // ✅ Accept
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
