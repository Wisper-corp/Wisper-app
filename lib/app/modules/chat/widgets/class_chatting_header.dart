// ignore_for_file: use_build_context_synchronously

import 'package:camera/camera.dart';
import 'package:crash_safe_image/crash_safe_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/core/services/socket/socket_service.dart';
import 'package:wisper/app/core/services/socket/call_services.dart';
import 'package:wisper/app/core/utils/show_over_loading.dart';
import 'package:wisper/app/core/utils/snack_bar.dart';
import 'package:wisper/app/core/widgets/common/circle_icon.dart';
import 'package:wisper/app/core/widgets/common/custom_popup.dart';
import 'package:wisper/app/core/widgets/common/details_card.dart';
import 'package:wisper/app/modules/calls/controller/call_controller.dart';
import 'package:wisper/app/modules/calls/views/audio_call.dart';
import 'package:wisper/app/modules/calls/views/video_call.dart';
import 'package:wisper/app/modules/chat/controller/class/class_member_controller.dart';
import 'package:wisper/app/modules/chat/controller/group/delete_group_chat_controller.dart';
import 'package:wisper/app/modules/chat/controller/mute_chat_controller.dart';
import 'package:wisper/app/modules/chat/controller/mute_info_controller.dart';
import 'package:wisper/app/modules/chat/views/class/class_info.dart';
import 'package:wisper/app/modules/dashboard/views/dashboard_screen.dart';
import 'package:wisper/app/modules/post/views/my_post_section.dart';
import 'package:wisper/gen/assets.gen.dart';

class ClassChatHeader extends StatefulWidget {
  final String className;
  final String classImage;
  final String classId;
  final String chatId;

  const ClassChatHeader({
    super.key,
    required this.className,
    required this.classImage,
    required this.classId,
    required this.chatId,
  });

  @override
  State<ClassChatHeader> createState() => _ClassChatHeaderState();
}

class _ClassChatHeaderState extends State<ClassChatHeader> {
  List<CameraDescription>? cameras;

  final DeleteGroupController deleteGroupController = DeleteGroupController();
  final ClassMembersController classMembersController = Get.put(
    ClassMembersController(),
  );
  final GetMuteInfoController getMuteInfoController = Get.put(
    GetMuteInfoController(),
  );
  final MuteChatController muteChatController = MuteChatController();
  final CallController callController = CallController();
  final SocketService socketService = Get.find<SocketService>();
  final CallService callService = Get.isRegistered<CallService>() ? Get.put(CallService()) : Get.put(CallService());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getMuteInfoController.getMuteInfo(widget.chatId);
      classMembersController.getClassMembers(widget.classId);
    });
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final availableCamerasList = await availableCameras();
    setState(() {
      cameras = availableCamerasList;
    });
  }

  // âœ… à¦†à¦®à¦¾à¦° à¦¨à¦¿à¦œà§‡à¦° ID à¦¬à¦¾à¦¦ à¦¦à¦¿à¦¯à¦¼à§‡ à¦¬à¦¾à¦•à¦¿ à¦¸à¦¬ member à¦à¦° participants list à¦¬à¦¾à¦¨à¦¾à¦“
  List<Map<String, dynamic>> _buildParticipants() { 
    final myId = StorageUtil.getData(StorageUtil.userId);
    final members = classMembersController.groupMemnersData ?? [];

    return members
        .where((member) => member.auth?.id != myId)
        .map((member) => {"id": member.auth?.id, "status": "INCOMING"})
        .toList();
  }

  // âœ… Step 1 â€” Room à¦¤à§ˆà¦°à¦¿ à¦•à¦°à§‹
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
    final participants = _buildParticipants();

    if (participants.isEmpty) {
      showSnackBarMessage(context, 'No members found to call.', true);
      return;
    }

    final bool isSuccess = await callController.getRoomWithParticipants(
      callType: type,
      mode: medium,
      participants: participants,
    );

    if (isSuccess) {
      getCallToken(callController.roomId, callController.callId, type, medium);
    } else {
      showSnackBarMessage(context, callController.errorMessage, true);
    }
  }

  // âœ… Step 2 â€” Token à¦¨à¦¾à¦“
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
    callService.resetCallSignals();

    final bool isSuccess = await callController.getToken(
      callId: callId,
      roomId: roomId, 
    );

    if (isSuccess) {
      socketService.socket.emit('callInvite', {
        "callId": callId,
        "token": callController.token,
        "groupName": widget.className,
        "groupImage": widget.classImage,
        "classId": widget.classId,
        "class_id": widget.classId,
      });

      if (type == 'VIDEO') {
        Get.to(
          VideoCallPage(
            name: widget.className,
            photoUrl: widget.classImage,
            chatId: widget.chatId,
            channelName: callController.roomId,
            token: callController.token,
            uuid: callController.uuid,
            callId: callController.callId,
            classId: widget.classId,
            isGroupCall: true,
          ),
        );
      } else {
        Get.to(
          AudioCallPage(
            name: widget.className,
            photoUrl: widget.classImage,
            chatId: widget.chatId,
            channelName: callController.roomId,
            token: callController.token,
            uuid: callController.uuid,
            callId: callController.callId,
            classId: widget.classId,
            isGroupCall: true,
          ),
        );
      }
    } else {
      showSnackBarMessage(context, callController.errorMessage, true);
    }
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
            final errorMsg = "Operation failed. Please try again.";
            if (onError != null) {
              onError(errorMsg);
            } else {
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

  void deleteChat() {
    executeWithLoading(
      loadingMessage: 'Please wait...',
      action: () => deleteGroupController.deleteGroup(groupId: widget.chatId),
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
        await getMuteInfoController.getMuteInfo(widget.chatId);
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
      title: "Leave Group?",
      message:
          "This conversation will be permanently removed.\nThis action cannot be undone.",
      onDelete: deleteChat,
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
      onTap: () {
        muteChat(value);
      },
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
          'Class Info',
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
            () =>
                ClassInfoScreen(classId: widget.classId, chatId: widget.chatId),
          );
        },
        '1': _showMutePopup,
        '2': _showDeleteConversation,
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
                      () => ClassInfoScreen(
                        classId: widget.classId,
                        chatId: widget.chatId,
                      ),
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
                      widget.classImage.isEmpty
                          ? CrashSafeImage(
                              Assets.images.education.keyName,
                              color: const Color(0xff11AE46),
                              height: 20.h,
                            )
                          : CircleAvatar(
                              backgroundColor: Colors.grey,
                              backgroundImage: NetworkImage(widget.classImage),
                              radius: 20,
                            ),
                      widthBox10,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.className,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    // âœ… Audio call â€” GROUP mode
                    CircleIconWidget(
                      imagePath: Assets.images.call.keyName,
                      onTap: () {
                        //print('Audio Call pressed');
                        getRoomId('AUDIO', 'GROUP');
                      },
                      radius: 15,
                      iconColor: Colors.white,
                    ),
                    widthBox10,
                    // âœ… Video call â€” GROUP mode
                    CircleIconWidget(
                      imagePath: Assets.images.video.keyName,
                      onTap: () {
                        // print('Video Call pressed');
                        getRoomId('VIDEO', 'GROUP');
                      },
                      radius: 15,
                    ),
                    widthBox10,
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
                  padding: const EdgeInsets.all(10.0),
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
