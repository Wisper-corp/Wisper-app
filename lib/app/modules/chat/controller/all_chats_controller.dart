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

        final String lastMessage =
            chat['messages'] != null && (chat['messages'] as List).isNotEmpty
                ? (chat['messages'].first['text'] ?? '')
                : 'No messages';

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
            ..['lastMessage'] = lastMessage == '' ? '📷 photo' : lastMessage
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
            "latestMessageAt": chat.latestMessageAt?.toIso8601String() ?? '',
            "lastMessage": chat.messages.isNotEmpty
                ? chat.messages.first.text ?? '📁 file'
                : 'No message yet',
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
