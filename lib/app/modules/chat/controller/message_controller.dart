// app/modules/chat/controller/message_controller.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/core/services/local_cache/chat_cache_service.dart';
import 'package:wisper/app/core/services/network_caller/network_caller.dart';
import 'package:wisper/app/core/services/socket/socket_service.dart';
import 'package:wisper/app/core/utils/connectivity_services.dart';
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

  /// Setup chat — now async so ChatListScreen can await it
  Future<void> setupChat({required String? chatId}) async {
    if (chatId == null || chatId.isEmpty) return;

    // Avoid duplicate setup for the same chat
    if (currentChatId == chatId) {
      print('Already setup for chat $chatId → skipping duplicate');
      return;
    }

    currentChatId = chatId;
    _lastChatListLatestAt = null;
    messages.clear();
    isLoading.value = true;

    // Load cached messages first for instant UI (offline friendly).
    final cached = ChatCacheService.getCachedMessages(chatId);
    if (cached.isNotEmpty) {
      messages.assignAll(cached);
    }

    // Wait for socket connection
    await socketService.waitUntilConnected(timeout: const Duration(seconds: 5));
    socketService.emitConnection();

    // Join the chat room (multiple variants — depending on backend)
    print('Joining chat room for chatId: $currentChatId');
    socketService.socket.emit('join', {'chatId': currentChatId});
    socketService.socket.emit('joinChat', {'chatId': currentChatId});
    socketService.socket.emit('join_room', currentChatId);

    // IMPORTANT: Remove previous listeners first, then add new ones
    // This prevents stacking listeners when switching chats
    socketService.socket.off('newMessage', _handleIncomingMessage);
    socketService.socket.off('typingStatus', _handleTypingStatus);
    socketService.socket.off('chatList', _handleChatListSync);

    socketService.socket.on('newMessage', _handleIncomingMessage);
    socketService.socket.on('typingStatus', _handleTypingStatus);
    socketService.socket.on('chatList', _handleChatListSync);

    // Fetch historical messages
    await getMessages(chatId: chatId);

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
    print('typingStatus received: $data');
    // You can add typing indicator logic here later
  }

  void _handleIncomingMessage(dynamic data) {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('newMessage EVENT RECEIVED for currentChatId: $currentChatId');
    print('Raw data: $data');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📨 newMessage received in MessageController');

    try {
      // Handle possible string payload
      if (data is String) {
        data = jsonDecode(data);
      }
      if (data is! Map) return;

      final String msgId = data['id'] ?? '';
      final String msgChatId = (data['chatId'] ?? data['chat'] ?? '').toString();

      // If message belongs to different chat → just update list, don't add to messages
      if (currentChatId != null &&
          msgChatId.isNotEmpty &&
          msgChatId != currentChatId) {
        _upsertChatListFromMessage(data);
        return;
      }

      // Avoid duplicate messages
      if (messages.any((e) => e[SocketMessageKeys.id] == msgId)) return;

      String senderName = 'Unknown';
      String? senderImage;
      String senderType = 'PERSON';

      if (data['sender'] != null) {
        final sender = data['sender'];
        if (sender['person'] != null) {
          senderName = sender['person']['name'] ?? 'Unknown';
          senderImage = sender['person']['image'];
          senderType = 'PERSON';
        } else if (sender['business'] != null) {
          senderName = sender['business']['name'] ?? 'Unknown';
          senderImage = sender['business']['image'];
          senderType = 'BUSINESS';
        }
      } else {
        final rawType = (data['senderType'] ??
                data['sender_role'] ??
                data['senderRole'] ??
                data['role'])
            ?.toString()
            .toUpperCase();
        if (rawType == 'BUSINESS') {
          senderType = 'BUSINESS';
        }
      }

      final msg = {
        SocketMessageKeys.id: msgId,
        SocketMessageKeys.text: (data['text'] ?? "").toString(),
        SocketMessageKeys.imageUrl: _safeImageUrl(data['file']),
        SocketMessageKeys.senderId:
            data['sender']?['id'] ?? data['senderId'] ?? '',
        SocketMessageKeys.senderName: senderName,
        SocketMessageKeys.senderImage: senderImage,
        SocketMessageKeys.senderType: senderType,
        SocketMessageKeys.chat: msgChatId,
        SocketMessageKeys.createdAt: (data['createdAt'] ?? DateTime.now())
            .toString(),
        SocketMessageKeys.seen: data['isRead'] ?? false,
        SocketMessageKeys.fileType: data['fileType'] ?? '',
      };

      messages.add(msg);
      messages.sort((a, b) {
        final DateTime aTime =
            DateTime.tryParse(a[SocketMessageKeys.createdAt] ?? '') ??
                DateTime(1970);
        final DateTime bTime =
            DateTime.tryParse(b[SocketMessageKeys.createdAt] ?? '') ??
                DateTime(1970);
        return aTime.compareTo(bTime); // oldest -> newest
      });
      _upsertChatListFromMessage(data);
      scrollToBottom();
      // Cache updated messages when realtime arrives.
      if (currentChatId != null && currentChatId!.isNotEmpty) {
        ChatCacheService.saveMessages(
          currentChatId!,
          messages.map((e) => Map<String, dynamic>.from(e)).toList(),
        );
      }
    } catch (e) {
      print("Error parsing newMessage: $e");
    }
  }

  void _handleChatListSync(dynamic rawData) {
    // ... তোমার আগের কোড একই রাখা যায়, পরিবর্তনের দরকার নেই ...
    try {
      if (currentChatId == null || currentChatId!.isEmpty) return;

      dynamic data = rawData;
      if (data is String) data = jsonDecode(data);
      if (data is! Map) return;

      final payload = Map<String, dynamic>.from(data);

      final List<dynamic> chats = payload['chats'] is List
          ? payload['chats']
          : (payload['id'] != null ? [payload] : []);

      final chat = chats.firstWhere(
        (c) => c is Map && (c['id']?.toString() ?? '') == currentChatId,
        orElse: () => null,
      );

      if (chat == null || chat is! Map) return;

      final latestAt = (chat['latestMessageAt'] ?? '').toString();
      if (latestAt.isEmpty) return;

      if (_lastChatListLatestAt == latestAt) return;
      _lastChatListLatestAt = latestAt;

      if (_chatListSyncInFlight) return;
      _chatListSyncInFlight = true;
      getMessages(chatId: currentChatId!).whenComplete(() {
        _chatListSyncInFlight = false;
      });
    } catch (e) {
      _chatListSyncInFlight = false;
      print('chatList sync error: $e');
    }
  }

  String _safeImageUrl(dynamic file) {
    if (file == null || file.toString() == 'null') return "";
    if (file is String && file.trim().isNotEmpty) return file.trim();
    if (file is List && file.isNotEmpty) return file.first.toString().trim();
    return "";
  }

  String _normalizeFileType(dynamic value) {
    final String normalized = (value ?? '').toString().trim();
    return normalized.isEmpty ? '' : normalized.toUpperCase();
  }

  bool _shouldUseFilename(String fileType) {
    switch (fileType) {
      case 'DOC':
      case 'DOCX':
      case 'PDF':
      case 'XLS':
      case 'XLSX':
      case 'PPT':
      case 'PPTX':
      case 'TXT':
        return true;
      default:
        return false;
    }
  }

  String _extractFileName(dynamic file) {
    if (file == null) return '';
    String url = '';
    if (file is String) {
      url = file.trim();
    } else if (file is List && file.isNotEmpty) {
      url = file.first.toString().trim();
    } else {
      url = file.toString().trim();
    }
    if (url.isEmpty) return '';
    final uri = Uri.tryParse(url);
    if (uri != null && uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.last;
    }
    if (url.contains('/')) {
      return url.split('/').last;
    }
    return url;
  }

  String _fileTypeLabel(String fileType) {
    switch (fileType) {
      case 'IMAGE':
        return 'Photo';
      case 'VIDEO':
        return 'Video';
      case 'AUDIO':
        return 'Audio';
      default:
        return 'File';
    }
  }

  String _applySenderPrefix(String message, bool isFromMe) {
    if (!isFromMe) return message;
    if (message.isEmpty || message == 'No messages') return message;
    return 'You: $message';
  }

  String _resolveLastMessage({
    required String text,
    required String fileType,
    dynamic file,
    required bool isFromMe,
  }) {
    final String trimmedText = text.trim();
    if (trimmedText.isNotEmpty) {
      return _applySenderPrefix(trimmedText, isFromMe);
    }

    final String normalizedFileType = _normalizeFileType(fileType);
    if (normalizedFileType.isNotEmpty) {
      if (_shouldUseFilename(normalizedFileType)) {
        final fileName = _extractFileName(file);
        if (fileName.isNotEmpty) {
          return _applySenderPrefix(fileName, isFromMe);
        }
      }
      return _applySenderPrefix(_fileTypeLabel(normalizedFileType), isFromMe);
    }

    final String fileValue = (file ?? '').toString().trim();
    if (fileValue.isNotEmpty) return _applySenderPrefix('File', isFromMe);

    return _applySenderPrefix('No messages', isFromMe);
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  /// Main change is here — handling new chat creation via ack
  void sendMessage(String chatId) {
    final ConnectivityService connectivityService =
        Get.find<ConnectivityService>();
    if (!connectivityService.isOnline.value) {
      Get.snackbar(
        'No Internet',
        'You are offline. Message cannot be sent.',
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    final text = textController.text.trim();
    final fileUrl = imageDecodeController.imageUrl.trim();
    final fileType = imageDecodeController.currentFileType;
    final userId = StorageUtil.getData(StorageUtil.userId) ?? '';

    if (text.isEmpty && fileUrl.isEmpty) {
      Get.snackbar('Error', 'Message or attachment required');
      return;
    }

    socketService.ensureRegistered();

    final messageData = {
      "chatId": chatId,
      if (text.isNotEmpty) "text": text,
      if (fileUrl.isNotEmpty) "file": fileUrl,
      if (fileUrl.isNotEmpty) "fileType": fileType,
    };

    print('sendMessage payload: $messageData');
    // ────────────────────────────────────────────────
    // KEY FIX: Wait for server acknowledgment
    // ────────────────────────────────────────────────
    socketService.socket.emitWithAck(
      'sendMessage',
      messageData,
      ack: (response) async {
        print('sendMessage ACK: $response');

        try {
          dynamic resp = response;
          if (resp is String) {
            resp = jsonDecode(resp);
          }
          if (resp is! Map<String, dynamic>) return;

          // Try to extract new chatId from different possible keys
          final String? newChatId = resp['chatId'] ??
              resp['id'] ??
              resp['chat']?.toString() ??
              resp['newChatId'];

          if (newChatId != null &&
              newChatId.isNotEmpty &&
              newChatId != currentChatId) {
            print('→ New chat created! Switching to chatId: $newChatId');

            currentChatId = newChatId;

            // Immediately join the new chat room
            socketService.socket.emit('join', {'chatId': newChatId});
            socketService.socket.emit('joinChat', {'chatId': newChatId});
            socketService.socket.emit('join_room', newChatId);

            // Full setup (fetch messages + ensure listeners)
            await setupChat(chatId: newChatId);
          }

          // Fallback: always refresh chat list after send
          if (Get.isRegistered<AllChatsController>()) {
            await Get.find<AllChatsController>().getAllChats();
          }
        } catch (e) {
          print('Error in sendMessage ack handler: $e');
        }
      },
    );

    print('Sending message → text: "$text", file: $fileUrl ($fileType)');

    // Optimistic update
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
          for (final msg in model.data!.messages) {
            String senderName = 'Unknown';
            String? senderImage;
            String senderType = 'PERSON';

            if (msg.sender != null) {
              if (msg.sender!.person != null) {
                senderName = msg.sender!.person!.name ?? 'Unknown';
                senderImage = msg.sender!.person!.image;
                senderType = 'PERSON';
              } else if (msg.sender!.business != null) {
                senderName = msg.sender!.business!.name ?? 'Unknown';
                senderImage = msg.sender!.business!.image;
                senderType = 'BUSINESS';
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
              SocketMessageKeys.senderType: senderType,
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
        messages.sort((a, b) {
          final DateTime aTime =
              DateTime.tryParse(a[SocketMessageKeys.createdAt] ?? '') ??
                  DateTime(1970);
          final DateTime bTime =
              DateTime.tryParse(b[SocketMessageKeys.createdAt] ?? '') ??
                  DateTime(1970);
          return aTime.compareTo(bTime); // oldest -> newest
        });
        // Cache latest messages after API success.
        await ChatCacheService.saveMessages(
          chatId,
          messages.map((e) => Map<String, dynamic>.from(e)).toList(),
        );
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
      final String fileType = _normalizeFileType(data['fileType']);
      final dynamic senderId =
          data['sender']?['id'] ?? data['senderId'] ?? data['sender_id'];
      final bool isFromMe = senderId?.toString() == userAuthId;
      final String lastMessage = _resolveLastMessage(
        text: text,
        fileType: fileType,
        file: file,
        isFromMe: isFromMe,
      );

      final String createdAt =
          (data['createdAt'] ?? DateTime.now().toIso8601String()).toString();

      if (index != -1) {
        socketService.socketFriendList[index]
          ..['lastMessage'] = lastMessage
          ..['fileType'] = fileType
          ..['latestMessageAt'] = createdAt;
        _sortSocketList();
        return;
      }

      // New chat → refresh full list (with debounce)
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
 
