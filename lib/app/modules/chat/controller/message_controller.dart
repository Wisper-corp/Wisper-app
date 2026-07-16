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

  final ScrollController scrollController = ScrollController();
  final TextEditingController textController = TextEditingController();
  late String userAuthId;

  @override
  void onInit() {
    super.onInit();
    userAuthId = StorageUtil.getData(StorageUtil.userId) ?? "";
  }

  void setupChat({required String? chatId}) {
    messages.clear();
    isLoading.value = true;

    getMessages(chatId: chatId ?? '').then((_) => scrollToBottom());

    // Socket listener (একবারই on করা)
    socketService.socket.off('newMessage');
    socketService.socket.on('chatList', _handleIncomingChat);
    socketService.socket.on('newMessage', _handleIncomingMessage);
    socketService.socket.on('typingStatus', _handleTypingStatus);
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
    final fileType = imageDecodeController.currentFileType; // নতুন
    final userId = StorageUtil.getData(StorageUtil.userId) ?? '';

    if (text.isEmpty && fileUrl.isEmpty) {
      Get.snackbar('Error', 'Message or attachment required');
      return;
    }

    final messageData = {
      "chatId": chatId,
      if (text.isNotEmpty) "text": text,
      if (fileUrl.isNotEmpty) "file": fileUrl,
      if (fileUrl.isNotEmpty) "fileType": fileType, // সঠিক টাইপ যাবে
    };

    socketService.socket.emit('sendMessage', messageData);
    print('File type : $fileType');
    print('User Id : $userId');
    print('Message Done sending message');

    // Clear everything
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
