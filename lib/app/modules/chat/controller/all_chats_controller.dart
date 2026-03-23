// app/modules/chat/controller/all_chats_controller.dart

import 'dart:convert';

import 'package:get/get.dart';
import 'package:wisper/app/core/others/get_storage.dart';
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
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await socketService.init();
    _setupSocketListeners();
    await getAllChats();
  }

  void _setupSocketListeners() {
    // IMPORTANT: never call `off(event)` without a handler — it removes other
    // listeners too (e.g. MessageController / SocketService), breaking realtime.
    socketService.socket.off('chatList', _handleIncomingChat);
    socketService.socket.off('newMessage', _handleNewMessageForList);

    socketService.socket.on('chatList', _handleIncomingChat);
    socketService.socket.on('newMessage', _handleNewMessageForList);
  }

  // void _handleIncomingChat(dynamic rawData) {
  //   print('Real-time chatList event received: $rawData');

  //   try {
  //     // rawData কে Map এ কনভার্ট করা
  //     final Map<String, dynamic> data = rawData is String
  //         ? jsonDecode(rawData)
  //         : rawData as Map<String, dynamic>;

  //     for (var element in rawData['chats']) {
  //       print(
  //         'Chat Element : ${element['type']}, ${element['type']}, ${element['type']}',
  //       );
  //       String lastMessage = '';
  //       bool isOnline = false;

  //       if (element['messages'] != null) {
  //         lastMessage = element['messages'][0]['text'] ?? '';
  //         print('Last Message: $lastMessage');
  //       }

  //       socketService.socketFriendList.add({"lastMessage": lastMessage});
  //     }
  //     // চ্যাট আইডি বের করা

  //     // লিস্টটা আবার sort করা যাতে latest message উপরে আসে
  //     getAllChats();
  //     _sortSocketList();
  //   } catch (e) {
  //     print('Error handling incoming chatList event: $e');
  //   }
  // }

  void _handleIncomingChat(dynamic rawData) {
    print('Real-time chatList event received from chat controller: $rawData');

    try {
      // rawData কে Map এ কনভার্ট
      final Map<String, dynamic> payload = rawData is String
          ? jsonDecode(rawData)
          : rawData as Map<String, dynamic>;

      // যদি full list আসে (meta + chats থাকে), তাহলে reload করো
      if (payload.containsKey('chats') &&
          payload['chats'] is List &&
          payload.containsKey('meta')) {
        getAllChats();
        return;
      }

      // single chat বা multiple chats array
      final List<dynamic> incomingChats = payload['chats'] is List
          ? payload['chats']
          : [payload];

      for (var chatJson in incomingChats) {
        final chat = chatJson as Map<String, dynamic>;
 
        final String chatId = chat['id'] ?? ''; 
        if (chatId.isEmpty) continue;

        final String type = chat['type'] ?? 'INDIVIDUAL';

        // last message
        final String lastMessage =
            chat['messages'] != null && (chat['messages'] as List).isNotEmpty
            ? (chat['messages'].first['text'] ?? '')
            : 'No messages';

        // latest time
        final String latestMessageAt = chat['latestMessageAt'] ?? '';

        // unread count
        final int unreadCount = chat['_count']?['messages'] ?? 0;

        // participant থেকে অন্যজন বের করা (ঠিক getAllChats-এর মতো)
        final List<dynamic> participants = chat['participants'] ?? [];
        final otherParticipant = participants.firstWhere(
          (p) => p['auth']?['id'] != myAuthId,
          orElse: () => participants.isNotEmpty ? participants.first : null,
        );

        // receiver এর তথ্য
        final receiverAuth = otherParticipant?['auth'];

        String receiverName = 'Unknown';

        String receiverId = '';
        bool receiverOnline = false;

        if (type == 'INDIVIDUAL' && receiverAuth != null) {
          receiverName =
              receiverAuth['person']?['name'] ??
              receiverAuth['business']?['name'] ??
              'Unknown';

          receiverId = receiverAuth['id'] ?? '';
          receiverOnline = otherParticipant['isOnline'] == true;
        }

        // socketFriendList-এ খুঁজে দেখা
        final int index = socketService.socketFriendList.indexWhere(
          (element) => element['id'] == chatId,
        );

        if (index != -1) {
          // Existing chat → শুধু আপডেট করো
          socketService.socketFriendList[index]
            ..['lastMessage'] = lastMessage == '' ? '📷 photo' : lastMessage
            ..['latestMessageAt'] = latestMessageAt
            ..['unreadMessageCount'] = unreadCount;

          // Individual হলে receiver info + online আপডেট করো
          if (type == 'INDIVIDUAL') {
            socketService.socketFriendList[index]
              ..['receiverId'] = receiverId
              ..['receiverOnline'] = receiverOnline; // নতুন ফিল্ড যোগ করলাম
          }
        } else {
          // New chat ? payload incomplete, do a full refresh
          if (!_isChatPayloadComplete(chat)) {
            getAllChats();
            continue;
          }

          // Payload complete ? build list item and add
          socketService.socketFriendList.add(_buildListItemFromSocket(chat));
        }
      }

      // সব শেষে sort করো যাতে নতুন মেসেজ উপরে আসে
      _sortSocketList();
    } catch (e) {
      print('Error in _handleIncomingChat: $e');
    }
  }

  void _handleNewMessageForList(dynamic data) {
    try {
      if (data is String) {
        data = jsonDecode(data);
      }
      if (data is! Map) return;

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

      if (_listRefreshInFlight) return;
      _listRefreshInFlight = true;
      getAllChats().whenComplete(() => _listRefreshInFlight = false);
    } catch (e) {
      _listRefreshInFlight = false;
      print('Error in _handleNewMessageForList: $e');
    }
  }

  bool _isChatPayloadComplete(Map<String, dynamic> chat) {
    final String type = chat['type'] ?? 'INDIVIDUAL';
    if (type == 'INDIVIDUAL') {
      final participants = chat['participants'];
      return participants is List && participants.isNotEmpty;
    }
    return true;
  }

  Map<String, dynamic> _buildListItemFromSocket(Map<String, dynamic> chat) {
    final String type = chat['type'] ?? 'INDIVIDUAL';
    final String chatId = chat['id'] ?? '';

    final List<dynamic> messages = chat['messages'] is List
        ? chat['messages'] as List<dynamic>
        : <dynamic>[];

    String lastMessage = 'No message yet';
    if (messages.isNotEmpty && messages.first is Map) {
      final Map first = messages.first as Map;
      final String text = first['text']?.toString() ?? '';
      final String file = first['file']?.toString() ?? '';
      if (text.isNotEmpty) {
        lastMessage = text;
      } else if (file.isNotEmpty) {
        lastMessage = 'photo';
      } else {
        lastMessage = 'file';
      }
    }

    String latestMessageAt = chat['latestMessageAt']?.toString() ?? '';
    if (latestMessageAt.isEmpty && messages.isNotEmpty && messages.first is Map) {
      final Map first = messages.first as Map;
      latestMessageAt =
          (first['createdAt'] ?? first['updatedAt'] ?? '').toString();
    }
    if (latestMessageAt.isEmpty) {
      latestMessageAt = DateTime.now().toIso8601String();
    }

    int unreadCount = 0;
    final count = chat['_count'];
    if (count is Map && count['messages'] != null) {
      unreadCount = count['messages'] is int
          ? count['messages'] as int
          : int.tryParse(count['messages'].toString()) ?? 0;
    }

    String receiverName = 'Unknown';
    String receiverImage = '';
    String receiverId = '';
    bool receiverOnline = false;
    bool isPerson = false;

    if (type == 'INDIVIDUAL') {
      final List<dynamic> participants = chat['participants'] is List
          ? chat['participants'] as List<dynamic>
          : <dynamic>[];
      final otherParticipant = participants.firstWhere(
        (p) => p is Map && p['auth']?['id'] != myAuthId,
        orElse: () => participants.isNotEmpty ? participants.first : null,
      );

      if (otherParticipant is Map) {
        final receiverAuth = otherParticipant['auth'];
        if (receiverAuth is Map) {
          final person = receiverAuth['person'];
          final business = receiverAuth['business'];

          if (person is Map) {
            receiverName = person['name']?.toString() ?? receiverName;
            receiverImage = person['image']?.toString() ?? receiverImage;
            isPerson = true;
          } else if (business is Map) {
            receiverName = business['name']?.toString() ?? receiverName;
            receiverImage = business['image']?.toString() ?? receiverImage;
            isPerson = false;
          }

          receiverId = receiverAuth['id']?.toString() ?? '';
        }

        receiverOnline = otherParticipant['isOnline'] == true;
      }
    }

    String groupId = '';
    String classId = '';
    Map<String, dynamic>? group;
    Map<String, dynamic>? chatClass;

    if (type == 'GROUP') {
      final g = chat['group'];
      if (g is Map) {
        group = {"name": g['name'], "image": g['image']};
        groupId = g['id']?.toString() ?? '';
      }
      groupId = chat['groupId']?.toString() ?? groupId;
    }

    if (type == 'CLASS') {
      final c = chat['chatClass'] ?? chat['class'];
      if (c is Map) {
        chatClass = {"name": c['name'], "image": c['image']};
        classId = c['id']?.toString() ?? '';
      }
      classId = chat['classId']?.toString() ?? classId;
    }

    return {
      "id": chatId,
      "type": type,
      "latestMessageAt": latestMessageAt,
      "lastMessage": lastMessage,
      "unreadMessageCount": unreadCount,
      "group": group,
      "groupId": groupId,
      "classId": classId,
      "chatClass": chatClass,
      "receiverName": type == 'INDIVIDUAL' ? receiverName : '',
      "receiverImage": type == 'INDIVIDUAL' ? receiverImage : '',
      "receiverId": type == 'INDIVIDUAL' ? receiverId : '',
      "isPerson": isPerson,
      "receiverOnline": type == 'INDIVIDUAL' ? receiverOnline : false,
    };
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

        print(
          'Socket List length initial : ${socketService.socketFriendList.length}',
        );

        for (final chat in model.data?.chats ?? []) {
          final String type = chat.type ?? 'INDIVIDUAL';
          print('type: $type');

          // // অন্য participant বের করা
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
            receiverAuth?.person != null ? isPerson = true : isPerson = false;
          }

          if (type == 'INDIVIDUAL') {
            displayName =
                receiverAuth?.person?.name ??
                receiverAuth?.business?.name ??
                'Unknown';
            displayImage =
                receiverAuth?.person?.image ??
                receiverAuth?.business?.image ??
                '';
            receiverId = receiverAuth?.id ?? '';
          }

          String tileName = '';
          if (type == 'GROUP') {
            tileName = chat.group?.name ?? 'Group Chat';
            groupId = chat.groupId ?? '';
          } else if (type == 'CLASS') {
            tileName = chat.chatClass?.name ?? 'Class Chat';
            classId = chat.classId ?? '';
          }

          print(
            'Socket List length before adding: ${socketService.socketFriendList.length}',
          );

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
                ? {"name": chat.chatClass?.name, "image": chat.chatClass?.image}
                : null,
            "receiverName": type == 'INDIVIDUAL' ? displayName : '',
            "receiverImage": type == 'INDIVIDUAL' ? displayImage : '',
            "receiverId": type == 'INDIVIDUAL' ? receiverId : '',
            "isPerson": isPerson,
            "receiverOnline": type == 'INDIVIDUAL'
                ? (otherParticipant?.isOnline ?? false)
                : false,
          });

          print(
            'Socket List length after adding: ${socketService.socketFriendList.length}',
          );
        }

        _sortSocketList();
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
      return bTime.compareTo(aTime); // Latest first
    });

    socketService.socketFriendList.refresh(); // GetX UI update
  }

  @override
  void onClose() {
    socketService.socket.off('chatList', _handleIncomingChat);
    socketService.socket.off('newMessage', _handleNewMessageForList);
    super.onClose();
  }
}
