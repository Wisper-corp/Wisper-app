import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/config/theme/light_theme_colors.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/core/utils/date_formatter.dart';
import 'package:wisper/app/core/utils/show_over_loading.dart';
import 'package:wisper/app/core/utils/snack_bar.dart';
import 'package:wisper/app/core/widgets/common/star_rating.dart';
import 'package:wisper/app/core/widgets/common/circle_icon.dart';
import 'package:wisper/app/core/widgets/common/custom_button.dart';
import 'package:wisper/app/core/widgets/common/line_widget.dart';
import 'package:wisper/app/modules/chat/controller/all_connection_controller.dart';
import 'package:wisper/app/modules/chat/controller/create_chat_controller.dart';
import 'package:wisper/app/modules/chat/controller/update_connection_controller.dart';
import 'package:wisper/app/modules/chat/views/person/message_screen.dart';
import 'package:wisper/app/modules/chat/widgets/location_info.dart';
import 'package:wisper/app/modules/chat/widgets/select_option_widget.dart';
import 'package:wisper/app/modules/homepage/controller/add_request_controller.dart';
import 'package:wisper/app/modules/job/views/others_job_section.dart';
import 'package:wisper/app/modules/post/views/my_post_section.dart';
import 'package:wisper/app/modules/post/views/others_post_section.dart';
import 'package:wisper/app/modules/profile/controller/buisness/buisness_controller.dart';
import 'package:wisper/app/modules/profile/controller/buisness/other_business_controller.dart';
import 'package:wisper/app/modules/profile/controller/remove_connection_controller.dart';
import 'package:wisper/app/modules/profile/widget/info_card.dart';
import 'package:wisper/gen/assets.gen.dart';

class OthersBusinessScreen extends StatefulWidget {
  final String userId;
  const OthersBusinessScreen({super.key, required this.userId});

  @override
  State<OthersBusinessScreen> createState() => _OthersBusinessScreenState();
}

class _OthersBusinessScreenState extends State<OthersBusinessScreen> {
  final OtherBusinessController controller = Get.put(OtherBusinessController());
  final CreateChatController createChatController = Get.put(
    CreateChatController(),
  );
  final AddRequestController addRequestController = Get.put(
    AddRequestController(),
  );
  final RemoveConnectionController removeConnectionController = Get.put(
    RemoveConnectionController(),
  );

  UpdateConnectionController updateConnectionController =
      UpdateConnectionController();
  final AllConnectionController connectionController = Get.put(
    AllConnectionController(),
  );

  final BusinessController businessController = Get.put(BusinessController());

  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      businessController.getMyProfile();
      print('User ID: ${widget.userId}');
      controller.getOthersProfile(widget.userId);
    });
  }

  void createChat(String? memberId, String? memberName, String? memberImage) {
    showLoadingOverLay(
      asyncFunction: () async =>
          await performCreateChat(context, memberId, memberName, memberImage),
      msg: 'Please wait...',
    );
  }

  void changeStatus(String userId, String status) {
    showLoadingOverLay(
      asyncFunction: () async => await performSubmit(context, userId, status),
      msg: 'Please wait...',
    );
  }

  Future<void> performSubmit(
    BuildContext context,
    String userId,
    String status,
  ) async {
    bool isSuccess = false;

    // Edit mode
    isSuccess = await updateConnectionController.updateConnection(
      userId: userId,
      status: status,
    );

    if (isSuccess) {
      controller.getOthersProfile(widget.userId);
      showSnackBarMessage(context, 'Request sent successfully', false);
    } else {
      showSnackBarMessage(
        context,
        updateConnectionController.errorMessage,
        true,
      );
    }
  }

  void removeConnection() {
    showLoadingOverLay(
      asyncFunction: () async => await performRemoveConnection(),
      msg: 'Removing connection...',
    );
  }

  Future<void> performRemoveConnection() async {
    final bool isSuccess = await removeConnectionController.deleteConnection(
      connectionMemberId: widget.userId,
    );

    if (isSuccess && mounted) {
      controller.getOthersProfile(widget.userId); // রিফ্রেশ প্রোফাইল
      showSnackBarMessage(context, 'Connection removed', false);
      Get.back(); // bottom sheet বন্ধ
    } else if (mounted) {
      showSnackBarMessage(context, 'Failed to remove connection', true);
    }
  }

  Future<void> performCreateChat(
    BuildContext context,
    String? memberId,
    String? memberName,
    String? memberImage,
  ) async {
    final bool isSuccess = await createChatController.createChat(
      memberId: widget.userId,
    );

    if (isSuccess) {
      var chatId = createChatController.chatId;
      Get.to(
        () => ChatScreen(
          chatId: chatId,
          receiverId: memberId ?? '',
          receiverImage: memberImage ?? '',
          receiverName: memberName ?? '',
        ),
      );
    } else {
      showSnackBarMessage(context, createChatController.errorMessage, true);
    }
  }

  void addRequest() {
    showLoadingOverLay(
      asyncFunction: () async => await performAddRequest(),
      msg: 'Sending request...',
    );
  }

  Future<void> performAddRequest() async {
    final bool isSuccess = await addRequestController.addRequest(
      receiverId: widget.userId,
    );

    if (isSuccess && mounted) {
      controller.getOthersProfile(widget.userId);
      showSnackBarMessage(context, 'Request sent successfully', false);
    } else if (mounted) {
      showSnackBarMessage(context, addRequestController.errorMessage, true);
    }
  }

  // রিমুভ কানেকশন কনফার্মেশন
  void _showRemoveConnection() {
    ConfirmationBottomSheet.show(
      context: context,
      title: "Remove Connection?",
      message:
          "Are you sure you want to remove this connection?\nThis action cannot be undone.",
      onDelete: () {
        removeConnection();
      },
      // deleteText: "Remove Now", // optional customization
      // cancelText: "Keep",       // optional
    );
  }

  @override
  void dispose() {
    controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Obx(() {
          // Show loading while data is being fetched
          if (controller.inProgress) {
            return const Center(child: CircularProgressIndicator());
          }

          // Data is loaded — now safe to access without fear of null
          final business = controller.profileData?.auth?.business;
          final createdAt = controller.profileData?.auth?.createdAt;
          final DateFormatter dateFormatter = createdAt != null
              ? DateFormatter(createdAt)
              : DateFormatter(DateTime.now());

          final String? connectionId = controller.profileData?.connection?.id;
          return Column(
            children: [
              SizedBox(height: 30.h),
              InfoCard(
                isBack: true,
                isEditImage: false,
                isTrailing: false,
                trailingOnTap: () {},
                imagePath: Assets.images.person.keyName,
                editOnTap: () {},
                title: business?.name ?? 'No Name',
                memberInfo: business?.industry ?? 'No Industry',
                ratingWidget: StarRating(
                  rating: controller.profileData?.avgRating ?? 0.0,
                  count: controller.profileData?.ratingCount ?? 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleIconWidget(
                      imagePath: Assets.images.call.keyName,
                      onTap: () {},
                      radius: 15,
                      color: LightThemeColors.blueColor,
                      iconColor: Colors.white,
                    ),
                    SizedBox(width: 10.w),
                    if (controller.profileData?.auth?.id ==
                        StorageUtil.getData(StorageUtil.userId))
                      const SizedBox()
                    else if (controller.profileData?.connection?.status ==
                            'PENDING' &&
                        controller.profileData?.connection?.requesterId !=
                            StorageUtil.getData(StorageUtil.userId))
                      Row(
                        children: [
                          SizedBox(
                            height: 31.h,
                            width: 90.w,
                            child: CustomElevatedButton(
                              color: Colors.green,
                              textSize: 12,
                              title: 'Accept',
                              onPress: () {
                                changeStatus(connectionId ?? '', 'ACCEPTED');
                              },
                            ),
                          ),
                          widthBox10,
                          SizedBox(
                            height: 31.h,
                            width: 90.w,
                            child: CustomElevatedButton(
                              color: Colors.red,
                              textSize: 12,
                              title: 'Reject',
                              onPress: () {
                                changeStatus(connectionId ?? '', 'REJECTED');
                              },
                            ),
                          ),
                        ],
                      )
                    else
                      SizedBox(
                        height: 31.h,
                        width: 116.w,
                        child: CustomElevatedButton(
                          color:
                              controller.profileData!.connection?.status == null
                              ? LightThemeColors.blueColor
                              : LightThemeColors.themeGreyColor,
                          textSize: 12,
                          title:
                              controller.profileData!.connection?.status ==
                                  'ACCEPTED'
                              ? 'Added'
                              : controller.profileData!.connection?.status ==
                                    'PENDING'
                              ? 'Pending'
                              : controller.profileData!.connection?.status ==
                                    'REJECTED'
                              ? 'Rejected'
                              : controller.profileData!.connection?.status ==
                                    'BLOCKED'
                              ? 'Blocked'
                              : 'Add',
                          onPress:
                              controller.profileData!.connection?.status ==
                                  'ACCEPTED'
                              ? _showRemoveConnection
                              : controller.profileData!.connection?.status ==
                                    null
                              ? addRequest
                              : null,
                          borderRadius: 50,
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 10.h),
              LocationInfo(
                location: business?.address ?? 'No Address',
                date: dateFormatter.getShortDateFormat(),
              ),
              SizedBox(height: 20.h),
              const StraightLiner(height: 0.4, color: Color(0xff454545)),
              SizedBox(height: 10.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => selectedIndex = 0),
                    child: SelectOptionWidget(
                      currentIndex: 0,
                      selectedIndex: selectedIndex,
                      title: 'Post',
                      lineColor: const Color.fromARGB(255, 255, 255, 255),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => selectedIndex = 1),
                    child: SelectOptionWidget(
                      currentIndex: 1,
                      selectedIndex: selectedIndex,
                      title: 'Job',
                      lineColor: const Color.fromARGB(255, 255, 255, 255),
                    ),
                  ),
                ],
              ),
              const StraightLiner(height: 0.4, color: Color(0xff454545)),
              SizedBox(height: 10.h),
              Expanded(
                child: selectedIndex == 0
                    ? OthersPostSection(userId: widget.userId)
                    : OthersJobSection(userId: widget.userId),
              ),
            ],
          );
        }),
      ),
    );
  }
}
