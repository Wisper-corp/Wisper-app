import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/widgets/common/circle_icon.dart';
import 'package:wisper/app/modules/chat/widgets/chatting_field.dart';
import 'package:wisper/gen/assets.gen.dart';

class MessageInputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final String chatId;
  final String receiverId;

  final RxBool isSendEnabled = false.obs;

  MessageInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    required this.chatId,
    required this.receiverId,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Card(
          color: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: ChattingFieldWidget(
                    controller: controller,
                    isSendEnabled: isSendEnabled,
                    chatId: chatId,
                    receiverId: receiverId,
                  ),
                ),
                const SizedBox(width: 8),
                Obx(
                  () => CircleIconWidget(
                    imagePath: Assets.images.send.keyName,
                    radius: 22,
                    iconRadius: 22,
                    iconColor: isSendEnabled.value ? Colors.blue : Colors.grey[600]!,
                    onTap: isSendEnabled.value ? onSend : () {},
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}