// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/utils/date_formatter.dart';
import 'package:wisper/app/core/widgets/shimmer/chat_shimmer.dart';
import 'package:wisper/app/modules/chat/controller/message_controller.dart';
import 'package:wisper/app/modules/chat/controller/seen_message_controller.dart';
import 'package:wisper/app/modules/chat/model/message_keys.dart';
import 'package:wisper/app/modules/chat/views/person/message_input_bar.dart';
import 'package:wisper/app/modules/chat/widgets/empty_group_card.dart';
import 'package:wisper/app/modules/chat/widgets/group_chatting_header.dart';
import 'package:wisper/app/modules/chat/widgets/message_bubble.dart';

class GroupChatScreen extends StatefulWidget {
  final String? groupName; 
  final String? groupImage;
  final String? chatId;
  final String? groupId;
  final bool showHeader; // false when embedded in Announcement tab

  const GroupChatScreen({
    super.key,
    this.groupName,
    this.groupImage,
    this.chatId,
    this.groupId,
    this.showHeader = true,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  late final MessageController ctrl;
  final SeenMessageController seenMessageController = SeenMessageController();

  @override
  void initState() {
    super.initState();
    // Use a unique tag when embedded to avoid conflicts with person chat controller
    final tag = widget.chatId ?? 'group';
    ctrl = Get.put(MessageController(), tag: tag);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      seenMessageController.seenMessage(widget.chatId!);
      ctrl.setupChat(chatId: widget.chatId);
    });
  }

  @override
  void dispose() {
    final tag = widget.chatId ?? 'group';
    Get.delete<MessageController>(tag: tag);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // When embedded (showHeader=false), return just the Column content
    // without a Scaffold so it fits inside the parent layout
    final content = Column(
      children: [
        if (widget.showHeader)
          GroupChatHeader(
            chatId: widget.chatId ?? '',
            groupName: widget.groupName ?? '',
            groupImage: widget.groupImage ?? '',
            groupId: widget.groupId ?? '',
          ),

        Expanded(
          child: Obx(() {
            if (ctrl.isLoading.value) {
              return const Center(child: ChatShimmerEffectWidget());
            }

            if (ctrl.messages.isEmpty) {
              return Center(
                child: EmptyGroupInfoCard(
                  isGroup: true,
                  name: widget.groupName ?? '',
                  member: '5',
                ),
              );
            }

            return ListView.builder(
              reverse: true,
              controller: ctrl.scrollController,
              padding: EdgeInsets.all(10.r),
              itemCount: ctrl.messages.length,
              itemBuilder: (context, index) {
                final msg = ctrl.messages[index];
                final isMe =
                    msg[SocketMessageKeys.senderId] == ctrl.userAuthId;

                final imageUrl = msg[SocketMessageKeys.imageUrl] ?? "";

                return MessageBubble(
                  message: msg,
                  isMe: isMe,
                  fileUrl: imageUrl,
                  fileType: msg[SocketMessageKeys.fileType] ?? '',
                  senderImage: msg[SocketMessageKeys.senderImage],
                  senderName: msg[SocketMessageKeys.senderName],
                  time: DateFormatter(
                    msg[SocketMessageKeys.createdAt],
                  ).getRelativeTimeFormat(),
                  isGroupChat: true,
                );
              },
            );
          }),
        ),

        MessageInputBar(
          controller: ctrl.textController,
          chatId: widget.chatId ?? '',
          receiverId: '',
          onSend: () => ctrl.sendMessage(widget.chatId ?? ''),
        ),
      ],
    );

    if (!widget.showHeader) {
      return content;
    }

    return Scaffold(body: content);
  }
}
