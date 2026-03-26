import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/core/utils/date_formatter.dart';
import 'package:wisper/app/core/utils/image_picker.dart';
import 'package:wisper/app/core/utils/show_over_loading.dart';
import 'package:wisper/app/core/utils/snack_bar.dart';
import 'package:wisper/app/core/widgets/common/circle_icon.dart';
import 'package:wisper/app/core/widgets/common/custom_button.dart';
import 'package:wisper/app/core/widgets/common/custom_popup.dart';
import 'package:wisper/app/core/widgets/common/line_widget.dart';
import 'package:wisper/app/modules/chat/controller/group/add_group_member.dart';
import 'package:wisper/app/modules/chat/controller/all_connection_controller.dart';
import 'package:wisper/app/modules/chat/controller/class/class_info_controller.dart';
import 'package:wisper/app/modules/chat/controller/class/class_member_controller.dart';
import 'package:wisper/app/modules/chat/views/class/edit_class_screen.dart';
import 'package:wisper/app/modules/chat/views/doc_info.dart';
import 'package:wisper/app/modules/chat/views/link_info.dart';
import 'package:wisper/app/modules/chat/views/media_info.dart';
import 'package:wisper/app/modules/chat/widgets/location_info.dart';
import 'package:wisper/app/modules/chat/widgets/select_option_widget.dart';
import 'package:wisper/app/modules/profile/controller/upload_photo_controller.dart';
import 'package:wisper/app/modules/profile/widget/info_card.dart';
import 'package:wisper/gen/assets.gen.dart';

class ClassInfoScreen extends StatefulWidget {
  const ClassInfoScreen({super.key, this.classId, required this.chatId});
  final String? classId;
  final String chatId;

  @override
  State<ClassInfoScreen> createState() => _ClassInfoScreenState();
}

class _ClassInfoScreenState extends State<ClassInfoScreen> {
  final ClassInfoController classInfoController = Get.put(
    ClassInfoController(),
  );

  final ClassMembersController classMembersController = Get.put(
    ClassMembersController(),
  );

  final AllConnectionController allConnectionController =
      Get.put(AllConnectionController());

  final ProfilePhotoController photoController =
      Get.find<ProfilePhotoController>();

  final AddMemberController addMemberController = AddMemberController();
  final RxString currentImagePath = ''.obs;
  @override
  void initState() {
    _updateProfileImage();
    _getProfileImage();
    classInfoController.getClassInfo(widget.classId);
    classMembersController.getClassMembers(widget.classId);
    allConnectionController.getAllConnection('ACCEPTED', '');
    super.initState();
  }

  int selectedIndex = 0;

  void addMember(String? memberId, String? groupId) {
    showLoadingOverLay(
      asyncFunction: () async =>
          await performAddMember(context, memberId, groupId),
      msg: 'Please wait...',
    );
  }

  Future<void> performAddMember(
    BuildContext context,
    String? memberId,
    String? groupId,
  ) async {
    final bool isSuccess = await addMemberController.addRequest(
      groupId: groupId,
      memberId: memberId,
    );

    if (isSuccess) {
      final AllConnectionController allConnectionController = Get.put(
        AllConnectionController(),
      );
      await allConnectionController.getAllConnection('ACCEPTED', '');
      setState(() {});
      showSnackBarMessage(context, 'Added successfully', false);
    } else {
      showSnackBarMessage(context, addMemberController.errorMessage, true);
    }
  }

  Future<void> _getProfileImage() async {
    print('Called get image');
    await classInfoController.getClassInfo(widget.classId);

    currentImagePath.value = classInfoController.groupInfoData?.image ?? '';
  }

  void _updateProfileImage() {
    String? imageUrl;

    imageUrl = classInfoController.groupInfoData?.image;

    currentImagePath.value = imageUrl?.isNotEmpty == true
        ? imageUrl!
        : Assets.images.person.keyName;
  }

  void _onImagePicked(File imageFile) async {
    currentImagePath.value = imageFile.path;

    final bool success = await photoController.uploadClassPhoto(
      imageFile,
      widget.classId!,
    );

    if (success) {
      classInfoController.getClassInfo(widget.classId);
      ();

      await Future.delayed(const Duration(milliseconds: 800));
      _updateProfileImage();
      showSnackBarMessage(context, 'Group photo updated!', false);
    } else {
      showSnackBarMessage(context, 'Failed to upload image', true);
      _updateProfileImage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final GlobalKey suffixButtonKey = GlobalKey();
    return Scaffold(
      body: Obx(() {
        if (classInfoController.inProgress) {
          return const Center(child: CircularProgressIndicator());
        } else {
          DateFormatter dateFormatter = DateFormatter(
            classInfoController.groupInfoData!.createdAt!,
          );
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              children: [
                heightBox30,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircleIconWidget(
                      color: const Color(0xff353434),
                      iconColor: const Color.fromARGB(255, 255, 255, 255),
                      iconRadius: 15,
                      radius: 14,
                      imagePath: Assets.images.arrowBack.keyName,
                      onTap: () => Navigator.pop(context),
                    ),
                    Text(
                      'Class Info',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 35.h, width: 35.h),
                  ],
                ),
                heightBox10,
                InfoCard(
                  trailingKey: suffixButtonKey,
                  trailingOnTap: () => CustomPopupMenu(
                    targetKey: suffixButtonKey,
                    options: [
                      Text(
                        'Edit Class',
                        style: TextStyle(fontSize: 12.sp, color: Colors.white),
                      ),
                    ],
                    optionActions: {
                      '0': () => Get.to(
                        () => EditClassScreen(
                          isPublic: false,
                          isAllowInvitation: false,
                          classId: classInfoController.groupInfoData?.id ?? '',
                          className:
                              classInfoController.groupInfoData?.name ?? '',
                          classCaption:
                              classInfoController.groupInfoData?.description ??
                              '',
                        ),
                      ),
                    },
                    menuWidth: 200,
                    menuHeight: 40,
                  ).showMenuAtPosition(context),
                  imagePath: currentImagePath.value,
                  editOnTap: () => ImagePickerHelper().showAlertDialog(
                    context,
                    _onImagePicked,
                  ),

                  showMember: _showMemberInfo,
                  title: classInfoController.groupInfoData?.name ?? '',
                  memberInfo: 'Group • 3 members',

                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 31.h,
                        width: 116.w,
                        child: CustomElevatedButton(
                          textSize: 12,
                          title: 'Share Profile',
                          onPress: () {},
                          borderRadius: 50,
                        ),
                      ),
                      widthBox10,
                      SizedBox(
                        height: 31.h,
                        width: 116.w,
                        child: CustomElevatedButton(
                          textSize: 12,
                          title: 'Add Members',
                          onPress: () {
                            _showConnectionInfo(widget.classId);
                          },
                          borderRadius: 50,
                        ),
                      ),
                    ],
                  ),
                ),
                heightBox20,
                LocationInfo(date: dateFormatter.getFullDateFormat()),
                heightBox20,
                StraightLiner(height: 0.4, color: const Color(0xff454545)),
                heightBox10,
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedIndex = 0;
                        });
                      },
                      child: SelectOptionWidget(
                        currentIndex: 0,
                        selectedIndex: selectedIndex,
                        title: 'Media',
                        lineColor: const Color.fromARGB(255, 255, 255, 255),
                      ),
                    ),
                    widthBox50,
                    widthBox50,
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedIndex = 1;
                        });
                      },
                      child: SelectOptionWidget(
                        currentIndex: 1,
                        selectedIndex: selectedIndex,
                        title: 'Docs',
                        lineColor: const Color.fromARGB(255, 255, 255, 255),
                      ),
                    ),
                  ],
                ),
                const StraightLiner(height: 0.4, color: Color(0xff454545)),
                heightBox10,

                if (selectedIndex == 0) MediaInfo(chatId: widget.chatId),
                if (selectedIndex == 1) DocInfoSection(chatId: widget.chatId),
              ],
            ),
          );
        }
      }),
    );
  }

  void _showMemberInfo() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          color: Colors.black,
          height: 240.h,
          child: Obx(() {
            if (classInfoController.inProgress) {
              return const Center(child: CircularProgressIndicator());
            } else {
              return ListView.builder(
                itemCount: classMembersController.groupMemnersData!.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 6.0,
                      horizontal: 20,
                    ),
                    child: Row(
                      children: [
                        widthBox10,
                        CircleAvatar(
                          radius: 18.r,
                          backgroundImage: AssetImage(
                            Assets.images.image.keyName,
                          ),
                        ),
                        widthBox10,
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              classMembersController
                                      .groupMemnersData![index]
                                      .auth!
                                      .person
                                      ?.name ??
                                  '',
                            ),
                            heightBox4,
                            Text(
                              classMembersController
                                          .groupMemnersData![index]
                                          .role ==
                                      'ADMIN'
                                  ? 'Admin'
                                  : 'Member',
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: const Color.fromARGB(255, 255, 255, 255),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            }
          }),
        );
      },
    );
  }

  void _showConnectionInfo(String? groupId) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          color: Colors.black,
          height: 240.h,
          child: Obx(() {
            if (allConnectionController.inProgress) {
              return const Center(child: CircularProgressIndicator());
            } else {
              // Step 1: Existing member user IDs collect করি
              final Set<String?> existingMemberIds = classMembersController
                  .groupMemnersData!
                  .map(
                    (member) => member.auth?.id,
                  ) // <--- যদি path অন্য হয় তাহলে change করো
                  .toSet();

              final filteredConnections = allConnectionController
                  .allConnectionData!
                  .where(
                    (connection) =>
                        !existingMemberIds.contains(connection.partner?.id),
                  )
                  .toList();

              // যদি কোনো eligible connection না থাকে
              if (filteredConnections.isEmpty) {
                return const Center(
                  child: Text(
                    'No more connections to add',
                    style: TextStyle(color: Colors.white70),
                  ),
                );
              }

              return ListView.builder(
                itemCount: filteredConnections.length,
                itemBuilder: (context, index) {
                  final connection =
                      filteredConnections[index]; // filtered item

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 6.0,
                      horizontal: 20.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18.r,
                              backgroundImage: AssetImage(
                                Assets.images.image.keyName,
                              ),
                            ),
                            widthBox10,
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(connection.partner?.person?.name ?? ''),
                                heightBox4,
                                Text(
                                  connection.partner?.person?.title ?? '',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color.fromARGB(255, 255, 255, 255),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(
                          width: 100.w,
                          height: 30.h,
                          child: CustomElevatedButton(
                            title: 'Add Member',
                            textSize: 10.sp,
                            onPress: () {
                              addMember(connection.partner?.id, groupId);
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }
          }),
        );
      },
    );
  }
}
