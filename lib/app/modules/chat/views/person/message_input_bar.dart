import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wisper/app/modules/chat/widgets/chatting_field.dart';

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
                  () => GestureDetector(
                    onTap: isSendEnabled.value ? onSend : null,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isSendEnabled.value
                            ? const Color(0xFF168DE1)
                            : const Color(0xFF2A2A2A),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.arrow_upward_rounded,
                          color: isSendEnabled.value
                              ? Colors.white
                              : Colors.grey[600],
                          size: 22,
                        ),
                      ),
                    ),
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