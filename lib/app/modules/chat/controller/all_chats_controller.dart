// app/modules/chat/controller/all_chats_controller.dart

import 'dart:convert';

import 'package:get/get.dart';
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/core/services/local_cache/chat_cache_service.dart';
import 'package:wisper/app/core/services/network_caller/network_caller.dart';
import 'package:wisper/app/core/services/socket/socket_service.dart';
import 'package:wisper/app/modules/authentication/views/sign_in_screen.dart';
import 'package:wisper/app/modules/chat/model/all_chats_model.dart';
import 'package:wisper/app/urls.dart';

class AllChatsController extends GetxController {
  final SocketService socketService = Get.find<SocketService>(); 

  final RxBool inProgress = false.obs;
  final RxString errorMessage = ''.obs;

  final Rx<AllChatsModel?> allChatsModel = Rx<AllChatsModel?>(null);

  final String myAuthId = StorageUtil.getData(StorageUtil.userId) ?? '';
  bool _listRefreshInFlight = false;

  @override
  void onInit() {
    super.onInit();
    // Load cached chat list first for instant UI (offline friendly).
    _loadCachedChats();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await socketService.init();
    _setupSocketListeners();
    await getAllChats();
  }

  void _setupSocketListeners() {
    socketService.socket.off('chatList', _handleIncomingChat);
    socketService.socket.on('chatList', _handleIncomingChat);

    // ✅ newMessage — handler সহ off করো, তাহলে শুধু এই handler টাই remove হবে
    socketService.socket.off('newMessage', _handleNewMessageForList);
    socketService.socket.on('newMessage', _handleNewMessageForList);
  }

  String _normalizeFileType(dynamic value) {
    final String normalized = (value ?? '').toString().trim();
    return normalized.isEmpty ? '' : normalized.toUpperCase();
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

  bool _isFromMe(dynamic senderId) {
    final String id = (senderId ?? '').toString();
    if (id.isEmpty) return false;
    return id == myAuthId;
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

  void _handleNewMessageForList(dynamic data) {
    print('📨 newMessage in AllChatsController');
    try {
      final String chatId = (data['chatId'] ?? data['chat'] ?? '').toString();
      if (chatId.isEmpty) return;

      final int index = socketService.socketFriendList.indexWhere(
        (e) => e['id'] == chatId,
      );

      final String text = (data['text'] ?? '').toString();
      final dynamic file = data['file'];
      final String fileType = _normalizeFileType(data['fileType']);
      final dynamic senderId =
          data['sender']?['id'] ?? data['senderId'] ?? data['sender_id'];
      final bool isFromMe = _isFromMe(senderId);
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
      } else {
        // নতুন chat এলে full refresh
        if (_listRefreshInFlight) return;
        _listRefreshInFlight = true;
        getAllChats().whenComplete(() => _listRefreshInFlight = false);
      }
    } catch (e) {
      _listRefreshInFlight = false;
      print('newMessage list update error: $e');
    }
  }

  void _handleIncomingChat(dynamic rawData) {
    print('📋 chatList received in AllChatsController');

    try {
      final Map<String, dynamic> payload = rawData is String
          ? jsonDecode(rawData)
          : rawData as Map<String, dynamic>;

      if (payload.containsKey('chats') &&
          payload['chats'] is List &&
          payload.containsKey('meta')) {
        getAllChats();
        return;
      }

      final List<dynamic> incomingChats =
          payload['chats'] is List ? payload['chats'] : [payload];

      for (var chatJson in incomingChats) {
        final chat = chatJson as Map<String, dynamic>;
        final String chatId = chat['id'] ?? '';
        if (chatId.isEmpty) continue;

        final String type = chat['type'] ?? 'INDIVIDUAL';
        final Map<String, dynamic>? latestMessage =
            (chat['messages'] is List && (chat['messages'] as List).isNotEmpty)
                ? (chat['messages'] as List).first as Map<String, dynamic>
                : null;
        final String fileType = _normalizeFileType(
          chat['fileType'] ?? latestMessage?['fileType'],
        );

        final String messageText = (latestMessage?['text'] ?? '').toString();
        final dynamic file = latestMessage?['file'];
        final dynamic senderId =
            latestMessage?['sender']?['id'] ??
            latestMessage?['senderId'] ??
            latestMessage?['sender_id'];
        final bool isFromMe = _isFromMe(senderId);
        final String lastMessage = _resolveLastMessage(
          text: messageText,
          fileType: fileType,
          file: file,
          isFromMe: isFromMe,
        );

        final String latestMessageAt = chat['latestMessageAt'] ?? '';
        final int unreadCount = chat['_count']?['messages'] ?? 0;

        final List<dynamic> participants = chat['participants'] ?? [];
        final otherParticipant = participants.firstWhere(
          (p) => p['auth']?['id'] != myAuthId,
          orElse: () => participants.isNotEmpty ? participants.first : null,
        );

        final receiverAuth = otherParticipant?['auth'];
        String receiverName = 'Unknown';
        String receiverId = '';
        bool receiverOnline = false;

        if (type == 'INDIVIDUAL' && receiverAuth != null) {
          receiverName = receiverAuth['person']?['name'] ??
              receiverAuth['business']?['name'] ??
              'Unknown';
          receiverId = receiverAuth['id'] ?? '';
          receiverOnline = otherParticipant['isOnline'] == true;
        }

        final int index = socketService.socketFriendList.indexWhere(
          (element) => element['id'] == chatId,
        );

        if (index != -1) {
          socketService.socketFriendList[index]
            ..['fileType'] = fileType
            ..['lastMessage'] = lastMessage
            ..['latestMessageAt'] = latestMessageAt
            ..['unreadMessageCount'] = unreadCount;

          if (type == 'INDIVIDUAL') {
            socketService.socketFriendList[index]
              ..['receiverId'] = receiverId
              ..['receiverOnline'] = receiverOnline;
          }
        } else {
          getAllChats();
          continue;
        }
      }

      _sortSocketList();
    } catch (e) {
      print('Error in _handleIncomingChat: $e');
    }
  }

  Future<void> getAllChats() async {
    if (inProgress.value) return;
    inProgress.value = true;

    try {
      final response = await Get.find<NetworkCaller>().getRequest(
        Urls.allChatsUrl,
        accessToken: StorageUtil.getData(StorageUtil.userAccessToken),
      );

      if (response.isSuccess && response.responseData != null) {
        errorMessage.value = '';
        final model = AllChatsModel.fromJson(response.responseData);
        allChatsModel.value = model;
 
        socketService.socketFriendList.clear(); 

        for (final chat in model.data?.chats ?? []) {
          final String type = chat.type ?? 'INDIVIDUAL';
          final Message? latestMessage =
              chat.messages.isNotEmpty ? chat.messages.first : null;
          final String fileType =
              _normalizeFileType(latestMessage?.fileType ?? '');
          final bool isFromMe = _isFromMe(latestMessage?.sender?.id);
          final String lastMessage = latestMessage != null
              ? _resolveLastMessage(
                  text: latestMessage.text ?? '',
                  fileType: fileType,
                  file: latestMessage.file,
                  isFromMe: isFromMe,
                )
              : 'No message yet';

          final otherParticipant = chat.participants.firstWhere(
            (p) => p.auth?.id != StorageUtil.getData(StorageUtil.userId),
          );

          final receiverAuth =
              (otherParticipant ?? chat.participants.first).auth;

          String displayName = 'Unknown';
          String displayImage = '';
          String receiverId = '';
          String groupId = '';
          String classId = '';
          bool isPerson = false;

          if (type == 'INDIVIDUAL') {
            isPerson = receiverAuth?.person != null;
            displayName = receiverAuth?.person?.name ??
                receiverAuth?.business?.name ??
                'Unknown';
            displayImage = receiverAuth?.person?.image ??
                receiverAuth?.business?.image ??
                '';
            receiverId = receiverAuth?.id ?? '';
          }

          if (type == 'GROUP') {
            groupId = chat.groupId ?? '';
          } else if (type == 'CLASS') {
            classId = chat.classId ?? '';
          }

          socketService.socketFriendList.add({
            "id": chat.id ?? '',
            "type": type,
            "fileType": fileType,
            "latestMessageAt": chat.latestMessageAt?.toIso8601String() ?? '',
            "lastMessage": lastMessage,
            "unreadMessageCount": chat.count?.messages ?? 0,
            "group": chat.group != null
                ? {"name": chat.group?.name, "image": chat.group?.image}
                : null,
            "groupId": groupId,
            "classId": classId,
            "chatClass": chat.chatClass != null
                ? {
                    "name": chat.chatClass?.name,
                    "image": chat.chatClass?.image,
                  }
                : null,
            "receiverName": type == 'INDIVIDUAL' ? displayName : '',
            "receiverImage": type == 'INDIVIDUAL' ? displayImage : '',
            "receiverId": type == 'INDIVIDUAL' ? receiverId : '',
            "isPerson": isPerson,
            "receiverOnline": type == 'INDIVIDUAL'
                ? (otherParticipant?.isOnline ?? false)
                : false,
          });
        }

        _sortSocketList();
        // Cache the latest chat list after successful fetch.
        await ChatCacheService.saveChats(
          socketService.socketFriendList
              .map((e) => Map<String, dynamic>.from(e))
              .toList(),
        );
      } else {
        errorMessage.value = response.errorMessage;
        if ((response.errorMessage).toLowerCase().contains('expired')) {
          Get.offAll(() => SignInScreen());
        }
      }
    } catch (e) {
      errorMessage.value = 'Error: $e';
    } finally {
      inProgress.value = false;
    }
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

  @override
  void onClose() {
    socketService.socket.off('chatList', _handleIncomingChat);
    // ✅ handler সহ off — অন্য controller এর listener নষ্ট হবে না
    socketService.socket.off('newMessage', _handleNewMessageForList);
    super.onClose();
  }

  void _loadCachedChats() {
    final cached = ChatCacheService.getCachedChats();
    if (cached.isEmpty) return;
    socketService.socketFriendList
      ..clear()
      ..addAll(cached);
    _sortSocketList();
  }
}



