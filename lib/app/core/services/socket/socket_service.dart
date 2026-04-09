// ignore_for_file: library_prefixes, avoid_print

import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/core/services/call/controller/call_services.dart';
import 'package:wisper/app/core/services/call/controller/call_socket.dart';
import 'package:wisper/app/modules/chat/controller/all_chats_controller.dart';
import 'package:wisper/app/urls.dart';

class SocketService extends GetxController {
  late IO.Socket _socket;

  RxBool isConnected = false.obs;
 
  final _messageList = <Map<String, dynamic>>[].obs;
  final _socketFriendList = <Map<String, dynamic>>[].obs;
  final _notificationsList = <Map<String, dynamic>>[].obs;

  RxList<Map<String, dynamic>> get messageList => _messageList;
  RxList<Map<String, dynamic>> get socketFriendList => _socketFriendList;
  RxList<Map<String, dynamic>> get notificationsList => _notificationsList;

  IO.Socket get socket => _socket;

  bool _initialized = false;
  String? _activeToken;
  String? _activeUserId;
  bool _listRefreshInFlight = false;

  Future<SocketService> init() async {
    final token = StorageUtil.getData(StorageUtil.userAccessToken);
    final userId = StorageUtil.getData(StorageUtil.userId);

    if (token == null || userId == null) {
      print('Token or User ID is missing!');
      _initialized = false;
      return this;
    }

    // If already initialized for the same auth, just ensure connection.
    if (_initialized) {
      if (_activeToken == token && _activeUserId == userId) {
        if (!_socket.connected) {
          print('Socket initialized but disconnected — reconnecting');
          _socket.connect();
        }
        return this;
      }

      // Auth changed (fresh login / switch account) → rebuild socket with new headers.
      print('Socket auth changed reinitializing');
      disconnect();
      _initialized = false;
    }

    print('Initializing socket service. Connecting...');

    _socket = IO.io(
      Urls.socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .enableAutoConnect()
          .enableForceNew()
          .setTimeout(10000)
          .build(),
    );
    _initialized = true;
    _activeToken = token.toString();
    _activeUserId = userId.toString();

    _socket.onConnect((_) {
      print('✅ Socket Connected!');
      print('Socket ID: ${_socket.id}');
      isConnected.value = true;
      emitConnection();
      ensureRegistered();
    });

    _socket.onConnectError((err) {
      print('Connection error: $err');
      isConnected.value = false;
    });

    _socket.onError((err) {
      print('Socket error: $err');
      isConnected.value = false;
    });

    _socket.onDisconnect((_) {
      print('Disconnected');
      isConnected.value = false;
    });

    _socket.onAny((event, data) {
      print('🛰️ onAny event: $event | data: $data');
    });

    _socket.on('newMessage', _handleNewMessageForList);

    final callService = Get.isRegistered<CallService>()
        ? Get.put(CallService())
        : Get.put(CallService());
    callService.attachSocket(_socket);
    CallSocket.bind(_socket, callService);

    _socket.onReconnect((attempt) {
      print('Reconnected! Attempt: $attempt');
      isConnected.value = true;
      emitConnection();
      ensureRegistered();
    });

    _socket.connect();

    return this;
  }

  /// Wait until socket becomes connected (use after login before opening chats).
  Future<bool> waitUntilConnected({
    Duration timeout = const Duration(seconds: 8),
    Duration pollInterval = const Duration(milliseconds: 100),
  }) async {
    final end = DateTime.now().add(timeout);
    while (!isConnected.value && DateTime.now().isBefore(end)) {
      await Future.delayed(pollInterval);
    }
    return isConnected.value;
  }

  /// Emit "connection" with the latest stored user id.
  /// Some backends use this as the authoritative mapping for realtime delivery.
  void emitConnection() {
    if (!_initialized) return;
    final uid = StorageUtil.getData(StorageUtil.userId);
    final aid = StorageUtil.getData(StorageUtil.userAuthId);
    final userId = uid?.toString().trim();
    final authId = aid?.toString().trim();
    if ((userId == null || userId.isEmpty) &&
        (authId == null || authId.isEmpty)) {
      return;
    }
    try {
      void emitFor(String id, String label) {
        _socket.emit('connection', id);
        _socket.emit('connection', {'userId': id});
        _socket.emit('connection', {'id': id});
        print('emit connection $label -> $id');
      }

      if (userId != null && userId.isNotEmpty) {
        emitFor(userId, 'userId');
      }
      if (authId != null && authId.isNotEmpty && authId != userId) {
        emitFor(authId, 'authId');
      }
    } catch (e) {
      print('emit connection failed: $e');
    }
  }

  /// Best-effort: retry connection registration (helps right-after-login races).
  Future<void> ensureRegistered({
    int attempts = 5,
    Duration interval = const Duration(milliseconds: 250),
  }) async {
    final ok = await waitUntilConnected(timeout: const Duration(seconds: 8));
    if (!ok) return;
    for (int i = 0; i < attempts; i++) {
      emitConnection();
      await Future.delayed(interval);
    }
  }

  void _handleNewMessageForList(dynamic data) {
    print('📨📨 newMessage called from socket services');
    try {
      final String chatId = (data['chatId'] ?? data['chat'] ?? '').toString();
      if (chatId.isEmpty) return;

      final int index = _socketFriendList.indexWhere(
        (element) => element['id'] == chatId,
      );

      final String text = (data['text'] ?? '').toString();
      final dynamic file = data['file'];
      final String lastMessage = text.isNotEmpty
          ? text
          : (file == null || file.toString().isEmpty)
              ? 'file'
              : 'photo';

      final String createdAt =
          (data['createdAt'] ?? DateTime.now().toIso8601String()).toString();

      if (index != -1) {
        _socketFriendList[index]
          ..['lastMessage'] = lastMessage
          ..['latestMessageAt'] = createdAt;
        _socketFriendList.sort((a, b) {
          final DateTime aTime =
              DateTime.tryParse(a['latestMessageAt'] ?? '') ?? DateTime(1970);
          final DateTime bTime =
              DateTime.tryParse(b['latestMessageAt'] ?? '') ?? DateTime(1970);
          return bTime.compareTo(aTime);
        });
        _socketFriendList.refresh();
        return;
      }

      if (_listRefreshInFlight) return;
      _listRefreshInFlight = true;
      if (Get.isRegistered<AllChatsController>()) {
        Get.find<AllChatsController>().getAllChats().whenComplete(
              () => _listRefreshInFlight = false,
            );
      } else {
        _listRefreshInFlight = false;
      }
    } catch (e) {
      _listRefreshInFlight = false;
      print('SocketService newMessage list update failed: $e');
    }
  }

  void disconnect() {
    if (!_initialized) {
      isConnected.value = false;
      _activeToken = null;
      _activeUserId = null;
      return;
    }

    if (_socket.connected || isConnected.value) {
      _socket.disconnect();
      print('❌ Socket disconnected');
    }
    _socket.clearListeners();
    isConnected.value = false;
    _initialized = false;
    _activeToken = null;
    _activeUserId = null;
  }

  @override
  void onClose() {
    disconnect();
    super.onClose();
  }
}
