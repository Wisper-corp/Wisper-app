// app/modules/chat/views/chat_list_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/services/socket/socket_service.dart';
import 'package:wisper/app/core/utils/date_formatter.dart';
import 'package:wisper/app/modules/chat/controller/all_chats_controller.dart';
import 'package:wisper/app/modules/chat/controller/message_controller.dart';
import 'package:wisper/app/modules/chat/views/class/class_message_screen.dart';
import 'package:wisper/app/modules/chat/views/group/group_message_screen.dart';
import 'package:wisper/app/modules/chat/views/person/message_screen.dart';
import 'package:wisper/app/modules/chat/widgets/chat_list_widget.dart';
import 'package:wisper/app/modules/chat/widgets/member_list_title.dart';
import 'package:wisper/gen/assets.gen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final AllChatsController controller = Get.put(AllChatsController());
  final SocketService socketService = Get.find<SocketService>();

  final TextEditingController _searchController = TextEditingController();
  final RxString searchQuery = ''.obs;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.getAllChats();
    });

    _searchController.addListener(() {
      searchQuery.value = _searchController.text.toLowerCase();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Helper to safely read a key from a dynamic map value
  String _mapVal(dynamic map, String key, [String fallback = '']) {
    if (map == null) return fallback;
    return (map as Map<String, dynamic>)[key]?.toString() ?? fallback;
  }

  Future<void> _navigateToChat(Map<String, dynamic> item) async {
    final String chatId = item['id'] ?? '';
    final String type = item['type'] ?? 'INDIVIDUAL';

    if (Get.isRegistered<MessageController>()) {
      await Get.delete<MessageController>(force: true);
    }

    final MessageController msgCtrl = Get.put(MessageController());
    await msgCtrl.setupChat(chatId: chatId);

    if (type == 'GROUP') {
      Get.to(
            () => GroupChatScreen(
          chatId: chatId,
          groupId: item['groupId'] ?? '',
          groupName: _mapVal(item['group'], 'name', 'Group Chat'),
          groupImage: _mapVal(item['group'], 'image'),
        ),
        preventDuplicates: false,
      );
    } else if (type == 'CLASS') {
      Get.to(
            () => ClassChatScreen(
          chatId: chatId,
          classImage: _mapVal(item['chatClass'], 'image'),
          className: _mapVal(item['chatClass'], 'name', 'Class Chat'),
          classId: item['classId'] ?? '',
        ),
        preventDuplicates: false,
      );
    } else {
      Get.to(
            () => ChatScreen(
          isOnline: item['receiverOnline'] ?? false,
          isPerson: item['isPerson'] == true,
          chatId: chatId,
          receiverName: item['receiverName']?.toString() ?? '',
          receiverId: item['receiverId'] ?? '',
          receiverImage: item['receiverImage'] ?? Assets.images.image.keyName,
        ),
        preventDuplicates: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(160),
        child: ChatListHeader(
          searchController: _searchController,
          onSearchChanged: () {
            searchQuery.value = _searchController.text.toLowerCase();
          },
        ),
      ),
      body: Obx(() {
        final list = socketService.socketFriendList;
        final query = searchQuery.value;

        final filteredList = query.isEmpty
            ? list
            : list.where((item) {
          final String name =
          (item['receiverName'] ?? '').toString().toLowerCase();
          return name.contains(query);
        }).toList();

        if (controller.inProgress.value && list.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (filteredList.isEmpty) {
          return const Center(
            child: Text(
              'No Chats Found',
              style: TextStyle(fontSize: 18, color: Colors.white70),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          itemCount: filteredList.length,
          itemBuilder: (context, index) {
            final item = filteredList[index];

            final String type = item['type'] ?? 'INDIVIDUAL';

            final String name = type == 'INDIVIDUAL'
                ? item['receiverName']?.toString() ?? ''
                : type == 'GROUP'
                ? _mapVal(item['group'], 'name')
                : type == 'CLASS'
                ? _mapVal(item['chatClass'], 'name', 'Unknown')
                : '';

            final String image =
                item['receiverImage'] ?? Assets.images.image.keyName;
            final String lastMessage = item['lastMessage'] ?? 'No messages yet';
            final String timeStr = item['latestMessageAt'] ?? '';
            final DateTime time = DateTime.tryParse(timeStr) ?? DateTime.now();
            final String formattedTime =
            DateFormatter(time).getRelativeTimeFormat();
            final int unread = item['unreadMessageCount'] ?? 0;

            return MemberListTile(
              isOnline: item['receiverOnline'] ?? false,
              onTap: () => _navigateToChat(item),
              isGroup: type == 'GROUP',
              isClass: type == 'CLASS',
              imagePath: image,
              name: name,
              message: lastMessage,
              time: formattedTime,
              unreadMessageCount: unread > 0 ? unread.toString() : '',
            );
          },
        );
      }),
    );
  }
}