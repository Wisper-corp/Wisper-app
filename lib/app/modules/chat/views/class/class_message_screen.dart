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
import 'package:wisper/app/modules/chat/widgets/class_chatting_header.dart';
import 'package:wisper/app/modules/chat/widgets/empty_group_card.dart';
import 'package:wisper/app/modules/chat/widgets/message_bubble.dart';

class ClassChatScreen extends StatefulWidget {
  final String? className;
  final String? classImage;
  final String? chatId;
  final String? classId;
  final bool? isOnline;

  const ClassChatScreen({
    super.key,
    this.className,
    this.classImage,
    this.chatId,
    this.classId,
    this.isOnline,
  });

  @override
  State<ClassChatScreen> createState() => _ClassChatScreenState();
}

class _ClassChatScreenState extends State<ClassChatScreen> {
  // ✅ Use Get.find — controller was already created & loaded in ChatListScreen
  final MessageController ctrl = Get.put(MessageController());
  final SeenMessageController seenMessageController = SeenMessageController();

  @override
  void initState() {
    super.initState();
    // ✅ Only mark as seen — setupChat already ran before navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      seenMessageController.seenMessage(widget.chatId!);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ClassChatHeader(
            chatId: widget.chatId ?? '',
            className: widget.className ?? '',
            classImage: widget.classImage ?? '',
            classId: widget.classId ?? '',
          ),

          Expanded(
            child: Obx(() {
              if (ctrl.isLoading.value) {
                return const Center(child: ChatShimmerEffectWidget());
              }

              if (ctrl.messages.isEmpty) {
                return Center(
                  child: EmptyGroupInfoCard(
                    isGroup: false,
                    name: widget.className ?? '',
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
                    isGroupChat: false,
                  );
                },
              );
            }),
          ),

          MessageInputBar(
            controller: ctrl.textController,
            onSend: () => ctrl.sendMessage(widget.chatId ?? ''),
          ),
        ],
      ),
    );
  }
}