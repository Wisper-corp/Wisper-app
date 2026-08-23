// app/modules/chat/controller/message_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wisper/app/modules/chat/model/offer_model.dart';
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/core/services/network_caller/network_caller.dart';
import 'package:wisper/app/core/services/socket/socket_service.dart';
import 'package:wisper/app/modules/chat/controller/image_decode_controller.dart';
import 'package:wisper/app/modules/chat/model/message_keys.dart';
import 'package:wisper/app/modules/chat/model/message_model.dart';
import 'package:wisper/app/urls.dart';

class MessageController extends GetxController {
  final SocketService socketService = Get.find<SocketService>();
  final FileDecodeController imageDecodeController =
      Get.find<FileDecodeController>(); // Added

  var isLoading = false.obs;
  var messages = <Map<String, dynamic>>[].obs; // newest first
  String _currentChatId = '';

  final ScrollController scrollController = ScrollController();
  final TextEditingController textController = TextEditingController();
  late String userAuthId;

  @override
  void onInit() {
    super.onInit();
    userAuthId = StorageUtil.getData(StorageUtil.userId) ?? "";
  }

  void setupChat({required String? chatId}) {
    _currentChatId = chatId ?? '';
    messages.clear();
    isLoading.value = true;

    getMessages(chatId: chatId ?? '').then((_) => scrollToBottom());

    // Wait for socket to be ready before attaching listeners
    _attachSocketListeners();
  }

  void _attachSocketListeners() {
    try {
      if (!socketService.isInitialized) {
        // Retry after 1 second
        Future.delayed(const Duration(seconds: 1), _attachSocketListeners);
        return;
      }
      socketService.socket.off('newMessage');
      socketService.socket.on('chatList', _handleIncomingChat);
      socketService.socket.on('newMessage', _handleIncomingMessage);
      socketService.socket.on('typingStatus', _handleTypingStatus);
    } catch (e) {
      // Socket not ready yet, retry
      Future.delayed(const Duration(seconds: 1), _attachSocketListeners);
    }
  }

  void _handleIncomingChat(dynamic rawData) {
    print(
      'Real-time chatList event received from message controller: $rawData',
    );
  }

  void _sortSocketList() {
    socketService.socketFriendList.sort((a, b) {
      final DateTime aTime =
          DateTime.tryParse(a['latestMessageAt'] ?? '') ?? DateTime(1970);
      final DateTime bTime =
          DateTime.tryParse(b['latestMessageAt'] ?? '') ?? DateTime(1970);
      return bTime.compareTo(aTime); // Latest first
    });

    socketService.socketFriendList.refresh(); // GetX UI update
  }

  void _handleTypingStatus(dynamic data) {
    print('typingStatus called');
    print(data);
  }

  void _handleIncomingMessage(dynamic data) {
    try {
      print('Real-time message event received from message controller: $data');
      final String msgId = data['id'] ?? '';
      if (messages.any((e) => e[SocketMessageKeys.id] == msgId)) return;

      // Only handle messages for THIS chat — ignore messages from other chats/groups
      final String incomingChatId = data['chatId'] ?? '';
      if (incomingChatId.isNotEmpty && _currentChatId.isNotEmpty && incomingChatId != _currentChatId) {
        print('Ignoring message from different chat: $incomingChatId (current: $_currentChatId)');
        return;
      }

      // Sender name & image (Group + Personal দুটোতেই কাজ করবে)
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
        SocketMessageKeys.chat: data['chatId'] ?? '',
        SocketMessageKeys.createdAt: (data['createdAt'] ?? DateTime.now())
            .toString(),
        SocketMessageKeys.seen: data['isRead'] ?? false,
        SocketMessageKeys.fileType: data['fileType'] ?? '',
      };

      messages.insert(0, msg);
      print('Senders Name: $senderName id : ${SocketMessageKeys.senderId}');

      scrollToBottom();
    } catch (e) {
      print("Socket parse error: $e");
    }
  }

  String _safeImageUrl(dynamic file) {
    if (file == null || file.toString() == 'null') return "";
    if (file is String && file.trim().isNotEmpty) return file.trim();
    if (file is List && file.isNotEmpty) return file.first.toString().trim();
    return "";
  }

  /// Scrolls to the newest message.
  ///
  /// Offset 0 is the newest end only for a `reverse: true` list. The group
  /// chat renders a normal (non-reversed) list, where offset 0 is the OLDEST
  /// message — which is why sending there used to jump to the top. Resolve the
  /// target from the attached viewport instead of assuming a direction.
  void scrollToBottom({bool animated = true}) {
    if (!scrollController.hasClients) return;
    final position = scrollController.position;
    final target = position.axisDirection == AxisDirection.up
        ? position.minScrollExtent // reversed list: newest sits at offset 0
        : position.maxScrollExtent; // normal list: newest sits at the end
    if (animated) {
      scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      scrollController.jumpTo(target);
    }
  }

  /// Scrolls once the newly-added message has actually been laid out.
  void scrollToBottomAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) => scrollToBottom());
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

    if (chatId.isEmpty) {
      Get.snackbar('Error', 'Chat not ready, please wait...');
      print('sendMessage: chatId is empty — cannot send');
      return;
    }

    if (!socketService.isInitialized) {
      // Socket not initialized yet — trigger init and retry send after delay
      socketService.init().then((_) {
        Future.delayed(const Duration(seconds: 2), () => sendMessage(chatId));
      });
      Get.snackbar('Connecting...', 'Please wait a moment and try again',
        backgroundColor: Colors.orange, colorText: Colors.white,
        duration: const Duration(seconds: 2));
      return;
    }

    if (!socketService.socket.connected) {
      Get.snackbar('Error', 'Not connected, please wait...',
        backgroundColor: Colors.orange, colorText: Colors.white);
      print('sendMessage: socket not connected');
      return;
    }

    final messageData = {
      "chatId": chatId,
      if (text.isNotEmpty) "text": text,
      if (fileUrl.isNotEmpty) "file": fileUrl,
      if (fileUrl.isNotEmpty) "fileType": fileType,
    };

    socketService.socket.emit('sendMessage', messageData);
    print('sendMessage emitted: chatId=$chatId text=$text');
    print('User Id : $userId');

    // Clear everything
    textController.clear();
    imageDecodeController.clearAll();

    // Land on the newest message. The echoed message arrives over the socket a
    // moment later, so scroll now (for the shrinking composer) and again once
    // the message has actually been inserted — see the messages listener.
    scrollToBottomAfterFrame();
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
              // Embed offer data if present (backend now returns this)
              if (msg.offerData != null)
                SocketMessageKeys.offerData: msg.offerData,
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

  /// Delete a message by ID — admin can delete any, user can delete own
  Future<bool> deleteMessage(String messageId) async {
    try {
      final token = StorageUtil.getData(StorageUtil.userAccessToken);
      final response = await Get.find<NetworkCaller>().deleteRequest(
        Urls.messagesById(messageId),
        accessToken: token,
      );
      if (response.isSuccess) {
        // Remove locally so UI updates instantly
        messages.removeWhere((m) => m[SocketMessageKeys.id] == messageId);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  @override
  void onClose() {
    socketService.socket.off('newMessage');
    scrollController.dispose();
    textController.dispose();
    super.onClose();
  }

  // ── Offer message helpers ────────────────────────────────────────────────

  /// Convert an OfferModel into a fake message map so it appears in the chat list
  Map<String, dynamic> offerToMessage(dynamic offer) {
    return {
      SocketMessageKeys.id: 'offer_${offer.id}',
      SocketMessageKeys.text: '',
      SocketMessageKeys.imageUrl: '',
      SocketMessageKeys.fileType: SocketMessageKeys.offerFileType,
      SocketMessageKeys.seen: true,
      SocketMessageKeys.senderId: offer.senderId,
      SocketMessageKeys.senderName: offer.senderName,
      SocketMessageKeys.senderImage: offer.senderImage,
      SocketMessageKeys.chat: offer.chatId,
      SocketMessageKeys.createdAt: offer.createdAt.toIso8601String(),
      SocketMessageKeys.offerData: offer,
    };
  }

  /// Inject or update an offer message in the chat list
  void injectOfferMessage(dynamic offer) {
    final offerId = offer is OfferModel ? offer.id : offer['id'];
    // Remove existing entry matching this offer
    messages.removeWhere((m) {
      if (m[SocketMessageKeys.id] == 'offer_$offerId') return true;
      final existing = m[SocketMessageKeys.offerData];
      if (existing is OfferModel) return existing.id == offerId;
      if (existing is Map) return existing['id'] == offerId;
      return false;
    });
    final offerMsg = offerToMessage(offer);
    messages.insert(0, offerMsg);
  }
}
