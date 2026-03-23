// app/modules/chat/controller/message_controller.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/core/services/network_caller/network_caller.dart';
import 'package:wisper/app/core/services/socket/socket_service.dart';
import 'package:wisper/app/modules/chat/controller/all_chats_controller.dart';
import 'package:wisper/app/modules/chat/controller/image_decode_controller.dart';
import 'package:wisper/app/modules/chat/model/message_keys.dart';
import 'package:wisper/app/modules/chat/model/message_model.dart';
import 'package:wisper/app/urls.dart';

class MessageController extends GetxController {
  final SocketService socketService = Get.find<SocketService>();
  final FileDecodeController imageDecodeController =
      Get.find<FileDecodeController>();

  var isLoading = false.obs;
  var messages = <Map<String, dynamic>>[].obs; // newest first

  final ScrollController scrollController = ScrollController();
  final TextEditingController textController = TextEditingController();
  late String userAuthId;
  bool _chatListRefreshInFlight = false;
  String? currentChatId;
  String? _lastChatListLatestAt;
  bool _chatListSyncInFlight = false;

  @override
  void onInit() {
    super.onInit();
    userAuthId = StorageUtil.getData(StorageUtil.userId) ?? "";
  }

  // ✅ Now async — ChatListScreen can await this before navigating
  Future<void> setupChat({required String? chatId}) async {
    currentChatId = chatId;
    _lastChatListLatestAt = null;
    messages.clear();
    isLoading.value = true;

    // Some backends require joining a room to receive newMessage events.
    // These emits are safe no-ops if the server doesn't implement them.
    await socketService.waitUntilConnected(timeout: const Duration(seconds: 5));
    socketService.emitConnection();
    if (currentChatId != null && currentChatId!.isNotEmpty) {
      socketService.socket.emit('join', {'chatId': currentChatId});
      socketService.socket.emit('joinChat', {'chatId': currentChatId});
      socketService.socket.emit('join_room', currentChatId);
    }

    // Register socket listeners first
    // IMPORTANT: never call `off(event)` without a handler — it removes other
    // listeners too (e.g. chat-list updates in SocketService), breaking realtime.
    socketService.socket.off('newMessage', _handleIncomingMessage);
    socketService.socket.off('typingStatus', _handleTypingStatus);
    // Fallback: some servers only broadcast chat list updates to receivers.
    socketService.socket.off('chatList', _handleChatListSync);

    socketService.socket.on('newMessage', _handleIncomingMessage);
    socketService.socket.on('typingStatus', _handleTypingStatus);
    socketService.socket.on('chatList', _handleChatListSync);

    // ✅ Await the actual message fetch — so caller knows when data is ready
    await getMessages(chatId: chatId ?? '');

    scrollToBottom();
  }

  void _sortSocketList() {
    socketService.socketFriendList.sort((a, b) {
      final DateTime aTime =
          DateTime.tryParse(a['latestMessageAt'] ?? '') ?? DateTime(1970);
      final DateTime bTime =
          DateTime.tryParse(b['latestMessageAt'] ?? '') ?? DateTime(1970);
      return bTime.compareTo(aTime);
    });

    socketService.socketFriendList.refresh();
  }

  void _handleTypingStatus(dynamic data) {
    print('typingStatus called');
    print(data);
  }

  void _handleIncomingMessage(dynamic data) {
    print('📨📨 newMessage called from message controller');
    try {
      // Some servers send JSON string payloads via Socket.IO.
      if (data is String) {
        data = jsonDecode(data);
      }
      if (data is! Map) return;

      print(
        '📲📲 Real-time message event received from message controller: $data',
      );

      final String msgId = data['id'] ?? '';
      final String msgChatId = (data['chatId'] ?? data['chat'] ?? '')
          .toString();
      if (currentChatId != null &&
          msgChatId.isNotEmpty &&
          msgChatId != currentChatId) {
        _upsertChatListFromMessage(data);
        return;
      }
      if (messages.any((e) => e[SocketMessageKeys.id] == msgId)) return;

      String senderName = 'Unknown';
      String? senderImage;

      if (data['sender'] != null) {
        final sender = data['sender'];
        if (sender['person'] != null) {
          senderName = sender['person']['name'] ?? 'Unknown';
          senderImage = sender['person']['image'];
        } else if (sender['business'] != null) {
          senderName = sender['business']['name'] ?? 'Unknown';
          senderImage = sender['business']['image'];
        }
      }

      final msg = {
        SocketMessageKeys.id: msgId,
        SocketMessageKeys.text: (data['text'] ?? "").toString(),
        SocketMessageKeys.imageUrl: _safeImageUrl(data['file']),
        SocketMessageKeys.senderId:
            data['sender']['id'] ?? data['senderId'] ?? '',
        SocketMessageKeys.senderName: senderName,
        SocketMessageKeys.senderImage: senderImage,
        SocketMessageKeys.chat: msgChatId,
        SocketMessageKeys.createdAt: (data['createdAt'] ?? DateTime.now())
            .toString(),
        SocketMessageKeys.seen: data['isRead'] ?? false,
        SocketMessageKeys.fileType: data['fileType'] ?? '',
      };

      messages.insert(0, msg);
      _upsertChatListFromMessage(data);
      scrollToBottom();
    } catch (e) {
      print("Socket parse error: $e");
    }
  }

  void _handleChatListSync(dynamic rawData) {
    try {
      if (currentChatId == null || currentChatId!.isEmpty) return;

      dynamic data = rawData;
      if (data is String) {
        data = jsonDecode(data);
      }
      if (data is! Map) return;

      final payload = Map<String, dynamic>.from(data as Map);

      final List<dynamic> chats = payload['chats'] is List
          ? payload['chats'] as List<dynamic>
          : (payload['id'] != null ? [payload] : <dynamic>[]);

      final chat = chats.cast<dynamic>().firstWhere(
        (c) => c is Map && (c['id']?.toString() ?? '') == currentChatId,
        orElse: () => null,
      );

      if (chat == null || chat is! Map) return;

      final latestAt = (chat['latestMessageAt'] ?? '').toString();
      if (latestAt.isEmpty) return;
 
      // Debounce repeated chatList payloads.
      if (_lastChatListLatestAt == latestAt) return;
      _lastChatListLatestAt = latestAt;

      // If we didn’t receive `newMessage`, sync messages from REST.
      if (_chatListSyncInFlight) return;
      _chatListSyncInFlight = true;
      getMessages(chatId: currentChatId!).whenComplete(() {
        _chatListSyncInFlight = false;
      });
    } catch (e) {
      _chatListSyncInFlight = false;
      print('chatList sync failed: $e');
    }
  }

  String _safeImageUrl(dynamic file) {
    if (file == null || file.toString() == 'null') return "";
    if (file is String && file.trim().isNotEmpty) return file.trim();
    if (file is List && file.isNotEmpty) return file.first.toString().trim();
    return "";
  }

  void scrollToBottom() {
    if (!scrollController.hasClients) return;
    scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void sendMessage(String chatId) {
    final text = textController.text.trim();
    final fileUrl = imageDecodeController.imageUrl.trim();
    final fileType = imageDecodeController.currentFileType;
    final userId = StorageUtil.getData(StorageUtil.userId) ?? '';

    if (text.isEmpty && fileUrl.isEmpty) {
      Get.snackbar('Error', 'Message or attachment required');
      return;
    }

    final messageData = {
      "chatId": chatId,
      if (text.isNotEmpty) "text": text,
      if (fileUrl.isNotEmpty) "file": fileUrl,
      if (fileUrl.isNotEmpty) "fileType": fileType,
    };

    socketService.socket.emitWithAck(
      'sendMessage',
      messageData,
      ack: (response) => print('📲✅ sendMessage ack: $response'),
    );
    print('File type : $fileType'); 
    print('User Id : $userId');
    print('Message Done sending message from sendMessage(){}');

    // Optimistically update chat list for instant UI feedback.
    _upsertChatListFromMessage({
      'chatId': chatId,
      'text': text,
      'file': fileUrl,
      'fileType': fileType,
      'createdAt': DateTime.now().toIso8601String(),
      'senderId': userId,
    });

    textController.clear();
    imageDecodeController.clearAll();
  }

  Future<void> getMessages({required String chatId}) async {
    isLoading(true);
    try {
      final token = await StorageUtil.getData(StorageUtil.userAccessToken);
      final response = await Get.find<NetworkCaller>().getRequest(
        Urls.messagesById(chatId),
        accessToken: token,
        queryParams: {"sort": "createdAt", "limit": "9999"},
      );

      if (response.isSuccess && response.responseData != null) {
        final model = MessageModel.fromJson(response.responseData);
        messages.clear();

        if (model.data?.messages != null) {
          for (final msg in model.data!.messages.reversed) {
            String senderName = 'Unknown';
            String? senderImage;

            if (msg.sender != null) {
              if (msg.sender!.person != null) {
                senderName = msg.sender!.person!.name ?? 'Unknown';
                senderImage = msg.sender!.person!.image;
              } else if (msg.sender!.business != null) {
                senderName = msg.sender!.business!.name ?? 'Unknown';
                senderImage = msg.sender!.business!.image;
              }
            }

            final mapMsg = {
              SocketMessageKeys.id: msg.id ?? "",
              SocketMessageKeys.text: msg.text ?? "",
              SocketMessageKeys.imageUrl: _safeImageUrl(msg.file),
              SocketMessageKeys.fileType: msg.fileType ?? "",
              SocketMessageKeys.seen: msg.isRead ?? false,
              SocketMessageKeys.senderId: msg.sender?.id ?? "",
              SocketMessageKeys.senderName: senderName,
              SocketMessageKeys.senderImage: senderImage,
              SocketMessageKeys.chat: msg.chatId ?? "",
              SocketMessageKeys.createdAt:
                  msg.createdAt?.toIso8601String() ??
                  DateTime.now().toIso8601String(),
            };

            if (!messages.any(
              (e) => e[SocketMessageKeys.id] == mapMsg[SocketMessageKeys.id],
            )) {
              messages.add(mapMsg);
            }
          }
        }
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to load messages");
    } finally {
      isLoading(false);
      scrollToBottom();
    }
  }

  @override
  void onClose() {
    socketService.socket.off('newMessage', _handleIncomingMessage);
    socketService.socket.off('typingStatus', _handleTypingStatus);
    socketService.socket.off('chatList', _handleChatListSync);

    // Best-effort leave room.
    if (currentChatId != null && currentChatId!.isNotEmpty) {
      socketService.socket.emit('leave', {'chatId': currentChatId});
      socketService.socket.emit('leaveChat', {'chatId': currentChatId});
      socketService.socket.emit('leave_room', currentChatId);
    }
    scrollController.dispose();
    textController.dispose();
    super.onClose();
  }

  void _upsertChatListFromMessage(dynamic data) {
    try {
      final String chatId = (data['chatId'] ?? data['chat'] ?? '').toString();
      if (chatId.isEmpty) return;

      final int index = socketService.socketFriendList.indexWhere(
        (element) => element['id'] == chatId,
      );

      final String text = (data['text'] ?? '').toString();
      final dynamic file = data['file'];
      final String lastMessage = text.isNotEmpty
          ? text
          : (file == null || file.toString().isEmpty)
          ? '📎 file'
          : '📷 photo';

      final String createdAt =
          (data['createdAt'] ?? DateTime.now().toIso8601String()).toString();

      if (index != -1) {
        socketService.socketFriendList[index]
          ..['lastMessage'] = lastMessage
          ..['latestMessageAt'] = createdAt;
        _sortSocketList();
        return;
      }

      // If chat not found yet (new conversation), refresh the whole list once.
      if (_chatListRefreshInFlight) return;
      _chatListRefreshInFlight = true;

      if (Get.isRegistered<AllChatsController>()) {
        Get.find<AllChatsController>().getAllChats().whenComplete(
          () => _chatListRefreshInFlight = false,
        );
      } else {
        _chatListRefreshInFlight = false;
      }
    } catch (e) {
      _chatListRefreshInFlight = false;
      print('Chat list update failed: $e');
    }
  }
}
