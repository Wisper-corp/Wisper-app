import 'package:get/get.dart';
import 'package:wisper/app/core/utils/show_over_loading.dart';
import 'package:wisper/app/core/utils/snack_bar.dart';
import 'package:wisper/app/modules/chat/controller/create_chat_controller.dart';
import 'package:wisper/app/modules/chat/views/person/message_screen.dart';

/// Opens the one-to-one chat with someone, creating it if this is the first
/// message between them.
///
/// The server returns the existing chat when there already is one, so this is
/// safe to call every time rather than checking first.
Future<void> openDirectChat({
  required String? userId,
  String? name,
  String? image,
}) async {
  if (userId == null || userId.trim().isEmpty) return;

  await showLoadingOverLay(
    msg: 'Opening chat...',
    asyncFunction: () async {
      final controller = Get.isRegistered<CreateChatController>()
          ? Get.find<CreateChatController>()
          : Get.put(CreateChatController());

      final ok = await controller.createChat(memberId: userId);
      if (!ok) {
        final reason = controller.errorMessage.trim();
        // Get.context is read fresh here rather than captured before the
        // await, so it cannot outlive the screen that was on top.
        final context = Get.context;
        if (context != null && context.mounted) {
          showSnackBarMessage(
            context,
            reason.isEmpty
                ? 'Could not open that chat. Please try again.'
                : reason,
            true,
          );
        }
        return;
      }

      // A contact tapped from a sheet leaves the sheet behind otherwise, and
      // going back from the chat would land on it again.
      if (Get.isBottomSheetOpen ?? false) Get.back();

      Get.to(
        () => ChatScreen(
          chatId: controller.chatId,
          receiverId: userId,
          receiverImage: image ?? '',
          receiverName: name ?? '',
        ),
      );
    },
  );
}
