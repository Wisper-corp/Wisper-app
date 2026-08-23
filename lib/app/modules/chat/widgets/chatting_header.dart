import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wisper/app/core/config/theme/light_theme_colors.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/core/utils/show_over_loading.dart';
import 'package:wisper/app/core/utils/snack_bar.dart';
import 'package:wisper/app/core/widgets/common/circle_icon.dart';
import 'package:wisper/app/core/widgets/common/initials_avatar.dart';
import 'package:wisper/app/core/widgets/common/header_icon.dart';
import 'package:wisper/app/core/widgets/common/custom_popup.dart';
import 'package:wisper/app/core/widgets/common/details_card.dart';
import 'package:wisper/app/modules/chat/controller/block_user_controller.dart';
import 'package:wisper/app/modules/chat/controller/group/delete_group_chat_controller.dart';
import 'package:wisper/app/modules/chat/controller/mute_chat_controller.dart';
import 'package:wisper/app/modules/chat/controller/mute_info_controller.dart';
import 'package:wisper/app/core/services/call/controller/call_services.dart';
import 'package:wisper/app/core/services/socket/socket_service.dart';
import 'package:wisper/app/modules/calls/controller/call_controller.dart';
import 'package:wisper/app/modules/calls/views/audio_call.dart';
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
  final CallService callService = Get.isRegistered<CallService>()
      ? Get.find<CallService>()
      : Get.put(CallService());

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

  /// Request camera + microphone permissions before starting a call
  /// Places a one-to-one call.
  ///
  /// This mirrors the group/class headers: a call row has to exist on the
  /// server and the callee has to be told about it. Previously this screen
  /// jumped straight into a call page holding a hardcoded Agora token and the
  /// fixed channel "CallDao", and never emitted `callInvite` — so the callee
  /// was never notified and the caller sat on "Calling..." forever.
  Future<void> _startCall({required bool video}) async {
    final receiverId = widget.memberId;
    if (receiverId == null || receiverId.isEmpty) {
      showSnackBarMessage(context, 'Cannot start a call with this chat.', true);
      return;
    }

    final granted = await _requestCallPermissions(video: video);
    if (!granted) return;

    final type = video ? 'VIDEO' : 'AUDIO';

    await showLoadingOverLay(
      msg: 'Please wait...',
      asyncFunction: () async {
        // 1 — create the call row (POST /calls) so both sides share a callId.
        final created = await callController.getRoom(
          callType: type,
          mode: 'ONE_TO_ONE',
          receiverUserId: receiverId,
        );
        if (!created) {
          if (mounted) {
            showSnackBarMessage(context, callController.errorMessage, true);
          }
          return;
        }

        // 2 — mint the Agora token for that room (POST /calls/token).
        callService.resetCallSignals();
        final tokenOk = await callController.getToken(
          callId: callController.callId,
          roomId: callController.roomId,
        );
        if (!tokenOk) {
          if (mounted) {
            showSnackBarMessage(context, callController.errorMessage, true);
          }
          return;
        }

        // 3 — ring the callee: socket `callIncoming` plus the FCM/VoIP push.
        socketService.socket.emit('callInvite', {
          "callId": callController.callId,
          "token": callController.token,
          "groupName": null,
          "groupImage": null,
        });

        if (!mounted) return;

        if (video) {
          Get.to(
            () => VideoCallPage(
              name: widget.name ?? '',
              photoUrl: widget.image ?? '',
              chatId: widget.chatId ?? '',
              channelName: callController.roomId,
              token: callController.token,
              uuid: callController.uuid,
              callId: callController.callId,
            ),
          );
        } else {
          Get.to(
            () => AudioCallPage(
              name: widget.name ?? '',
              photoUrl: widget.image ?? '',
              chatId: widget.chatId ?? '',
              channelName: callController.roomId,
              token: callController.token,
              uuid: callController.uuid,
              callId: callController.callId,
            ),
          );
        }
      },
    );
  }

  Future<bool> _requestCallPermissions({bool video = false}) async {
    final perms = video
        ? [Permission.camera, Permission.microphone]
        : [Permission.microphone];
    final statuses = await perms.request();
    final denied = statuses.values.any(
      (s) => s == PermissionStatus.denied || s == PermissionStatus.permanentlyDenied,
    );
    if (denied) {
      Get.snackbar(
        'Permission Required',
        video
            ? 'Camera and microphone access are needed for video calls.'
            : 'Microphone access is needed for voice calls.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        mainButton: TextButton(
          onPressed: () => openAppSettings(),
          child: const Text('Settings', style: TextStyle(color: Colors.white)),
        ),
      );
      return false;
    }
    return true;
  }

  void _showBlockUser() {
    ConfirmationBottomSheet.show(
      context: context,
      title: "Block ${widget.name}?",
      message:
          "This user will be permanently blocked.\nThis action cannot be undone.",
      deleteButtonText: 'Block',
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
            Image.asset(
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
            Image.asset(
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
      height: 92.h,
      width: double.infinity,
      child: Padding(
        // WhatsApp-style bar: bare icons, no chip backgrounds, tight to the edges.
        padding: EdgeInsets.only(left: 4.w, right: 8.w, bottom: 10.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                HeaderIcon(
                  asset: Assets.images.arrowBack.keyName,
                  size: 16,
                  onTap: () => Navigator.pop(context),
                  tooltip: 'Back',
                ),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      Get.to(
                        () => widget.isPerson == true
                            ? OthersPersonScreen(userId: widget.memberId ?? '')
                            : OthersBusinessScreen(userId: widget.memberId ?? ''),
                      );
                    },
                    child: Row(
                      children: [
                        InitialsAvatar(
                          name: widget.name ?? '',
                          imageUrl: widget.image,
                          radius: 22.r,
                          fontSize: 16,
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.name ?? 'Unknown',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 17.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  height: 1.2,
                                ),
                              ),
                              Text(
                                widget.status == true ? 'Online' : 'Offline',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w400,
                                  height: 1.3,
                                  color: widget.status == true
                                      ? Colors.green
                                      : LightThemeColors.themeGreyColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                HeaderActionGroup(
                  children: [
                    HeaderIcon(
                      asset: Assets.images.video.keyName,
                      size: 18,
                      tooltip: 'Video call',
                      onTap: () => _startCall(video: true),
                    ),
                    HeaderIcon(
                      asset: Assets.images.call.keyName,
                      size: 17,
                      tooltip: 'Voice call',
                      onTap: () => _startCall(video: false),
                    ),
                  ],
                ),
                HeaderIcon(
                  key: suffixButtonKey,
                  asset: Assets.images.moreHor.keyName,
                  size: 16,
                  tooltip: 'More options',
                  onTap: () => customPopupMenu.showMenuAtPosition(context),
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
