import 'package:camera/camera.dart';
import 'package:crash_safe_image/crash_safe_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wisper/app/core/config/theme/light_theme_colors.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/core/services/socket/socket_service.dart';
import 'package:wisper/app/core/utils/show_over_loading.dart';
import 'package:wisper/app/core/utils/snack_bar.dart';
import 'package:wisper/app/core/widgets/common/circle_icon.dart';
import 'package:wisper/app/core/widgets/common/custom_popup.dart';
import 'package:wisper/app/core/widgets/common/details_card.dart';
import 'package:wisper/app/modules/calls/controller/call_controller.dart';
import 'package:wisper/app/modules/calls/views/audio_call.dart';
import 'package:wisper/app/modules/chat/controller/block_user_controller.dart';
import 'package:wisper/app/modules/chat/controller/group/delete_group_chat_controller.dart';
import 'package:wisper/app/modules/chat/controller/mute_chat_controller.dart';
import 'package:wisper/app/modules/chat/controller/mute_info_controller.dart';
import 'package:wisper/app/modules/calls/views/video_call.dart';
import 'package:wisper/app/modules/dashboard/views/dashboard_screen.dart';
import 'package:wisper/app/modules/post/views/my_post_section.dart';
import 'package:wisper/app/modules/profile/views/business/others_business_screen.dart';
import 'package:wisper/app/modules/profile/views/person/others_person_screen.dart';
import 'package:wisper/gen/assets.gen.dart';

class ChatHeader extends StatefulWidget {
  final String? name;
  final String? image;
  final bool? status;
  final String? memberId;
  final String? chatId;
  final bool? isPerson;

  const ChatHeader({
    super.key,
    this.name,
    this.image,
    this.status,
    this.memberId,
    this.chatId,
    this.isPerson,
  });

  @override
  State<ChatHeader> createState() => _ChatHeaderState();
}

class _ChatHeaderState extends State<ChatHeader> {
  List<CameraDescription>? cameras;
 
  final BlockUnblockMemberController blockUnblockMemberController =
      BlockUnblockMemberController();
  final GetMuteInfoController getMuteInfoController = Get.put(
    GetMuteInfoController(),
  );
  final DeleteGroupController deleteGroupController = DeleteGroupController();
  final MuteChatController muteChatController = MuteChatController();
  final CallController callController = CallController();
  final SocketService socketService = Get.find<SocketService>();

  void getRoomId(String? type, String? medium) {
    showLoadingOverLay(
      asyncFunction: () async => await performRoomId(context, type, medium),
      msg: 'Please wait...',
    );
  }

  Future<void> performRoomId(
    BuildContext context,
    String? type,
    String? medium,
  ) async {
    final bool isSuccess = await callController.getRoom(
      callType: type,
      mode: medium,
      receiverUserId: widget.memberId,
    );

    if (isSuccess) {
      getCallToken(callController.roomId, callController.callId, type, medium);
    } else {
      showSnackBarMessage(context, callController.errorMessage, true);
    }
  }

  void getCallToken( 
    String? roomId,
    String? callId,
    String? type,
    String? medium,
  ) {
    showLoadingOverLay(
      asyncFunction: () async =>
          await performCallToken(context, roomId, callId, type, medium),
      msg: 'Please wait...',
    );
  }

  Future<void> performCallToken(
    BuildContext context,
    String? roomId,
    String? callId,
    String? type, 
    String? medium,
  ) async {
    final bool isSuccess = await callController.getToken(
      callId: callId,
      roomId: roomId,
    );

    if (isSuccess) {
      // Get.snackbar('Success', callController.token);
      socketService.socket.emit('callInvite', {
        "callId": callId,
        "token": callController.token,
        "groupName": null,
      });

      if (type == 'VIDEO') {
        Get.to(
          VideoCallPage(
            name: widget.name ?? '',
            photoUrl: widget.image ?? '',
            chatId: widget.chatId ?? '',
            channelName: callController.roomId,
            token: callController.token,
            uuid: callController.uuid,
            callId: callController.callId,
            isGroupCall: false,
          ),
        );
      } else {
        Get.to(
          AudioCallPage(
            name: widget.name ?? '',
            photoUrl: widget.image ?? '',
            chatId: widget.chatId ?? '',
            channelName: callController.roomId,
            token: callController.token,
            uuid: callController.uuid,
            callId: callController.callId,
            isGroupCall: false,
          ),
        );
      }
    } else {
      showSnackBarMessage(context, callController.errorMessage, true);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getMuteInfoController.getMuteInfo(widget.chatId ?? '');
    });
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final availableCamerasList = await availableCameras();
    setState(() {
      cameras = availableCamerasList;
    });
  }

  Future<void> executeWithLoading({
    required Future<bool> Function() action,
    required String loadingMessage,
    required Future<void> Function() onSuccess,
    void Function(String error)? onError,
  }) async {
    showLoadingOverLay(
      asyncFunction: () async {
        try {
          final success = await action();
          if (success) {
            await onSuccess();
          } else {
            final errorMsg = onError != null
                ? null
                : "Operation failed. Please try again.";
            if (errorMsg != null) {
              showSnackBarMessage(context, errorMsg, true);
            }
          }
        } catch (e) {
          final errorMsg = e.toString().replaceAll('Exception: ', '').trim();
          if (onError != null) {
            onError(errorMsg);
          } else {
            showSnackBarMessage(context, errorMsg, true);
          }
        }
      },
      msg: loadingMessage,
    );
  }

  void blockMember(String? chatId, String? memberId) {
    executeWithLoading(
      loadingMessage: 'Please wait...',
      action: () => blockUnblockMemberController.blockMember(
        chatId: chatId,
        memberId: memberId,
      ),
      onSuccess: () async {
        setState(() {});
        showSnackBarMessage(context, 'Blocked successfully', false);
      },
      onError: (error) {
        showSnackBarMessage(
          context,
          blockUnblockMemberController.errorMessage ?? error,
          true,
        );
      },
    );
  }

  void deleteChat() {
    executeWithLoading(
      loadingMessage: 'Please wait...',
      action: () =>
          deleteGroupController.deleteGroup(groupId: widget.chatId ?? ''),
      onSuccess: () async {
        Get.to(() => MainButtonNavbarScreen());
      },
      onError: (error) {
        showSnackBarMessage(
          context,
          deleteGroupController.errorMessage ?? error,
          true,
        );
      },
    );
  }

  void muteChat(String? muteFor) {
    if (muteFor == null) return;

    executeWithLoading(
      loadingMessage: 'Please wait...',
      action: () =>
          muteChatController.muteChat(chatId: widget.chatId, muteFor: muteFor),
      onSuccess: () async {
        await getMuteInfoController.getMuteInfo(widget.chatId ?? '');
        if (context.mounted) {
          Navigator.pop(context);
        }
      },
      onError: (error) {
        showSnackBarMessage(
          context,
          muteChatController.errorMessage ?? error,
          true,
        );
      },
    );
  }

  void _showDeleteConversation() {
    ConfirmationBottomSheet.show(
      context: context,
      title: "Delete Conversation?",
      message:
          "This conversation will be permanently removed.\nThis action cannot be undone.",
      onDelete: deleteChat,
    );
  }

  void _showBlockUser() {
    ConfirmationBottomSheet.show(
      context: context,
      title: "Block ${widget.name}?",
      message:
          "This user will be permanently blocked.\nThis action cannot be undone.",
      onDelete: () => blockMember(widget.chatId, widget.memberId),
    );
  }

  Widget _buildMuteOption(
    BuildContext context, {
    required String label,
    required String value,
    required String? currentMuteFor,
  }) {
    final isSelected = currentMuteFor == value;
    return GestureDetector(
      onTap: () => muteChat(value),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w400),
          ),
          const Spacer(),
          if (isSelected)
            const Icon(Icons.check, color: Colors.white, size: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final GlobalKey suffixButtonKey = GlobalKey();

    final customPopupMenu = CustomPopupMenu(
      targetKey: suffixButtonKey,
      options: [
        Text(
          'View Profile',
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
        ),
        Text(
          'Mute Notifications',
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
        ),
        Row(
          children: [
            CrashSafeImage(
              Assets.images.alert.keyName,
              height: 16.h,
              width: 16,
            ),
            widthBox10,
            Text(
              'Block User',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w400,
                color: Colors.white,
              ),
            ),
          ],
        ),
        Row(
          children: [
            CrashSafeImage(
              Assets.images.delete.keyName,
              height: 16.h,
              width: 16,
            ),
            widthBox10,
            Text(
              'Delete Conversation',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w400,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ],
      optionActions: {
        '0': () {
          Get.to(
            () => widget.isPerson!
                ? OthersPersonScreen(userId: widget.memberId ?? '')
                : OthersBusinessScreen(userId: widget.memberId ?? ''),
          );
        },
        '1': _showMutePopup,
        '2': _showBlockUser,
        '3': _showDeleteConversation,
      },
      menuWidth: 200,
      menuHeight: 30,
    );

    return SizedBox(
      height: 100,
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    Get.to(
                      () => widget.isPerson!
                          ? OthersPersonScreen(userId: widget.memberId ?? '')
                          : OthersBusinessScreen(userId: widget.memberId ?? ''),
                    );
                  },
                  child: Row(
                    children: [
                      CircleIconWidget(
                        imagePath: Assets.images.arrowBack.keyName,
                        onTap: () => Navigator.pop(context),
                        radius: 13,
                      ),
                      widthBox10,
                      CircleAvatar(
                        backgroundImage: NetworkImage(widget.image ?? ''),
                        radius: 20,
                      ),
                      widthBox10,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.name ?? 'Unknown',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            widget.status == true ? 'Online' : 'Offline',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                              color: widget.status == true
                                  ? Colors.green
                                  : LightThemeColors.themeGreyColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    CircleIconWidget(
                      imagePath: Assets.images.call.keyName,
                      onTap: () {
                        getRoomId('AUDIO', 'ONE_TO_ONE');
                      },
                      radius: 15,
                    ),
                    widthBox4,
                    CircleIconWidget(
                      imagePath: Assets.images.video.keyName,
                      onTap: () {
                        getRoomId('VIDEO', 'ONE_TO_ONE');
                      },
                      radius: 15,
                    ),
                    widthBox4,
                    CircleIconWidget(
                      key: suffixButtonKey,
                      imagePath: Assets.images.moreHor.keyName,
                      onTap: () => customPopupMenu.showMenuAtPosition(context),
                      radius: 15,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showMutePopup() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      builder: (BuildContext sheetContext) {
        return Container(
          height: MediaQuery.of(sheetContext).size.height * 0.32,
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 10),
                  Text(
                    'Mute notifications',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  CircleIconWidget(
                    imagePath: Assets.images.cross.keyName,
                    onTap: () => Navigator.pop(sheetContext),
                    radius: 15,
                  ),
                ],
              ),
              heightBox10,
              DetailsCard(
                bgColor: const Color(0xff181818),
                borderColor: const Color(0xff181818),
                child: Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Text(
                    'Other members will not see that you muted this chat, and you will still be notified if you are mentioned.',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              heightBox12,
              DetailsCard(
                width: double.infinity,
                bgColor: const Color(0xff181818),
                borderColor: const Color(0xff181818),
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Obx(() {
                    if (getMuteInfoController.inProgress) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final muteFor = getMuteInfoController.muteInfoData?.muteFor;
                    return Column(
                      children: [
                        _buildMuteOption(
                          sheetContext,
                          label: '8 Hours',
                          value: 'EIGHT_HOURS',
                          currentMuteFor: muteFor,
                        ),
                        heightBox8,
                        _buildMuteOption(
                          sheetContext,
                          label: '1 Week',
                          value: 'ONE_WEEK',
                          currentMuteFor: muteFor,
                        ),
                        heightBox8,
                        _buildMuteOption(
                          sheetContext,
                          label: 'Always',
                          value: 'ALWAYS',
                          currentMuteFor: muteFor,
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
