import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/services/socket/socket_service.dart';
import 'package:wisper/app/core/utils/date_formatter.dart';
import 'package:wisper/app/modules/chat/controller/all_chats_controller.dart';
import 'package:wisper/app/modules/chat/views/class/class_message_screen.dart';
import 'package:wisper/app/modules/chat/views/group/group_message_screen.dart';
import 'package:wisper/app/modules/chat/widgets/member_list_title.dart';
import 'package:wisper/gen/assets.gen.dart';

// The general/announcement chat ID from the server env
const String _kGeneralChatId = '7d1256e7-ad1e-4fd9-ad4b-53dec78b6cb9';

class ChatSection extends StatefulWidget {
  const ChatSection({super.key});

  @override
  State<ChatSection> createState() => _ChatSectionState();
}

 class _ChatSectionState extends State<ChatSection> {
  final AllChatsController controller = Get.put(AllChatsController());
  final SocketService socketService = Get.find<SocketService>();

  final TextEditingController _searchController = TextEditingController();
  final RxString searchQuery = ''.obs;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.getAllChats(); // Initial load
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

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Obx(() {
        final allChats = socketService.socketFriendList;
        final query = searchQuery.value;

        // Keep GROUP, CLASS, and GENERAL chats
        var groupClassChats = allChats.where((item) {
          final type = item['type']?.toString().toUpperCase();
          return type == 'GROUP' || type == 'CLASS' || type == 'GENERAL';
        }).toList();

        // If no GENERAL chat came from API, inject the hardcoded one so
        // the Announcement tab always has something to open
        final hasGeneral = groupClassChats.any(
          (item) => item['type']?.toString().toUpperCase() == 'GENERAL',
        );
        if (!hasGeneral) {
          groupClassChats.insert(0, {
            'id': _kGeneralChatId,
            'type': 'GENERAL',
            'lastMessage': 'Tap to open announcements',
            'latestMessageAt': '',
            'unreadMessageCount': 0,
            'group': {'name': 'Announcement', 'image': ''},
          });
        }

        // Apply search filter
        final filteredList = query.isEmpty
            ? groupClassChats
            : groupClassChats.where((item) {
                final type = item['type']?.toString().toUpperCase() ?? '';
                String name = '';
                if (type == 'GROUP' || type == 'GENERAL') {
                  name = item['group']?['name']?.toString() ?? '';
                } else if (type == 'CLASS') {
                  name = item['chatClass']?['name']?.toString() ?? '';
                }
                return name.toLowerCase().contains(query);
              }).toList();

        // ── Loading state ──
        if (controller.inProgress.value && allChats.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        // ── No group/class chats at all ──
        if (filteredList.isEmpty) {
          return const Center(
            child: Text(
              'No group chat found',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          itemCount: filteredList.length,
          itemBuilder: (context, index) {
            final item = filteredList[index];

            final String chatId = item['id'] ?? '';
            final String type = (item['type'] ?? 'INDIVIDUAL').toUpperCase();

            String name = 'Unknown';
            String image = Assets.images.image.keyName;

            if (type == 'GROUP' || type == 'GENERAL') {
              name = item['group']?['name'] ?? (type == 'GENERAL' ? 'Announcement' : 'Group Chat');
              image = item['group']?['image'] ?? image;
            } else if (type == 'CLASS') {
              name = item['chatClass']?['name'] ?? 'Class Chat';
              image = item['chatClass']?['image'] ?? image;
            }

            final String lastMessage = item['lastMessage'] ?? 'No messages yet';
            final String timeStr = item['latestMessageAt'] ?? '';
            final DateTime time = DateTime.tryParse(timeStr) ?? DateTime.now();
            final String formattedTime = timeStr.isEmpty ? '' : DateFormatter(time).getRelativeTimeFormat();
            final int unread = item['unreadMessageCount'] ?? 0;

            return MemberListTile(
              isOnline: false,
              onTap: () {
                if (type == 'GENERAL' || type == 'GROUP') {
                  Get.to(
                    () => GroupChatScreen(
                      chatId: chatId,
                      groupId: item['groupId'] ?? '',
                      groupName: name,
                      groupImage: image,
                    ),
                  );
                } else if (type == 'CLASS') {
                  Get.to(
                    () => ClassChatScreen(
                      chatId: chatId,
                      classImage: image,
                      className: name,
                      classId: item['classId'] ?? '',
                    ),
                  );
                }
              },
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