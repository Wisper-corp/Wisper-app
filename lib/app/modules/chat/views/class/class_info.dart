import 'dart:io';

import 'package:crash_safe_image/crash_safe_image.dart';
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
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/modules/chat/controller/all_connection_controller.dart';
import 'package:wisper/app/modules/chat/controller/class/class_info_controller.dart';
import 'package:wisper/app/modules/chat/controller/class/class_member_controller.dart';
import 'package:wisper/app/modules/chat/views/class/edit_class_screen.dart';
import 'package:wisper/app/modules/chat/views/link_info.dart';
import 'package:wisper/app/modules/chat/views/media_info.dart';
import 'package:wisper/app/modules/chat/widgets/select_option_widget.dart';
import 'package:wisper/app/modules/post/views/my_post_section.dart';
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

  final AllConnectionController allConnectionController = Get.put(
    AllConnectionController(),
  );

  final ProfilePhotoController photoController =
      Get.find<ProfilePhotoController>();

  final ClassMembersController addMemberController = ClassMembersController();
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
    String? classId,
  ) async {
    final bool isSuccess = await addMemberController.addRequest(
      classId: classId,
      memberId: memberId,
    );

    if (isSuccess) {
      final AllConnectionController allConnectionController = Get.put(
        AllConnectionController(),
      );
      await allConnectionController.getAllConnection('ACCEPTED', '');
      await classMembersController.getClassMembers(classId);
      setState(() {});
      showSnackBarMessage(context, 'Added successfully', false);
    } else {
      showSnackBarMessage(context, addMemberController.errorMessage, true);
    }
  }

  void removeMember(String? memberId, String? groupId) {
    showLoadingOverLay(
      asyncFunction: () async =>
          await performRemoveMember(context, memberId, groupId),
      msg: 'Please wait...',
    );
  }

  Future<void> performRemoveMember(
    BuildContext context,
    String? memberId,
    String? groupId,
  ) async {
    final bool isSuccess = await addMemberController.removeRequest(
      chatId: widget.chatId,
      memberId: memberId,
    );

    if (isSuccess) {
      final AllConnectionController allConnectionController = Get.put(
        AllConnectionController(),
      );
      await allConnectionController.getAllConnection('ACCEPTED', '');
      await classMembersController.getClassMembers(groupId);
      setState(() {});
      showSnackBarMessage(context, 'Removed successfully', false);
    } else {
      showSnackBarMessage(context, addMemberController.errorMessage, true);
    }
  }

  void _showRemoveMember(String? memberId, String? groupId) {
    ConfirmationBottomSheet.show(
      context: context,
      title: "Remove Member?",
      deleteButtonText: "Remove",
      message:
          "This member will be permanently removed.\nThis action cannot be undone",
      onDelete: () {
        removeMember(memberId, groupId);
      },
    );
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
          final members = classMembersController.groupMemnersData ?? [];
          final myAuthId =
              StorageUtil.getData(StorageUtil.userAuthId)?.toString() ?? '';
          final myUserId =
              StorageUtil.getData(StorageUtil.userId)?.toString() ?? '';
          dynamic myMember;
          for (final m in members) {
            final authId = (m.auth?.id ?? '');
            if (authId == myAuthId || authId == myUserId) {
              myMember = m;
              break;
            }
          }
          final isCurrentUserAdmin =
              myMember != null && (myMember.role?.toUpperCase() == 'ADMIN');

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
                  memberInfo:
                      'Class • ${classMembersController.groupMemnersData?.length ?? 0} members',

                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // SizedBox(
                      //   height: 31.h,
                      //   width: 116.w,
                      //   child: CustomElevatedButton(
                      //     textSize: 12,
                      //     title: 'Share Profile',
                      //     onPress: () {},
                      //     borderRadius: 50,
                      //   ),
                      // ),
                      // widthBox10,
                      (classInfoController.groupInfoData?.allowInvitation ==
                                  true ||
                              isCurrentUserAdmin)
                          ? SizedBox(
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
                            )
                          : Opacity(
                              opacity: 0.5,
                              child: SizedBox(
                                height: 31.h,
                                width: 116.w,
                                child: CustomElevatedButton(
                                  textSize: 12,
                                  title: 'Add Members',
                                  onPress: () {},
                                  borderRadius: 50,
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
                heightBox4,
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CrashSafeImage(
                      Assets.images.calendar.keyName,
                      height: 16.h,
                      color: const Color(0xff7F8694),
                    ),
                    widthBox4,
                    Text(
                      'Created ${dateFormatter.getFullDateFormat()}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xff7F8694),
                      ),
                    ),
                  ],
                ),
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
              final members = classMembersController.groupMemnersData ?? [];
              final myAuthId =
                  StorageUtil.getData(StorageUtil.userAuthId)?.toString() ?? '';
              final myUserId =
                  StorageUtil.getData(StorageUtil.userId)?.toString() ?? '';
              dynamic myMember;
              for (final m in members) {
                final authId = (m.auth?.id ?? '');
                if (authId == myAuthId || authId == myUserId) {
                  myMember = m;
                  break;
                }
              }
              final isCurrentUserAdmin =
                  myMember != null && (myMember.role?.toUpperCase() == 'ADMIN');

              return ListView.builder(
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final member = members[index];
                  final bool isPerson = member.auth?.person != null;
                  final String name = isPerson
                      ? (member.auth?.person?.name ?? '')
                      : (member.auth?.business?.name ?? '');
                  final String imageUrl = isPerson
                      ? (member.auth?.person?.image ?? '')
                      : (member.auth?.business?.image ?? '');
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 6.0,
                      horizontal: 20,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            widthBox10,
                            CircleAvatar(
                              radius: 18.r,
                              backgroundImage: imageUrl.isNotEmpty
                                  ? NetworkImage(imageUrl)
                                  : null,
                              backgroundColor: Colors.grey,
                              child: imageUrl.isEmpty
                                  ? Text(
                                      name.isNotEmpty ? name[0] : '?',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    )
                                  : null,
                            ),
                            widthBox10,
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name),
                                heightBox4,
                                Text(
                                  member.role == 'ADMIN' ? 'Admin' : 'Member',
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    color: const Color.fromARGB(
                                      255,
                                      255,
                                      255,
                                      255,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        isCurrentUserAdmin &&
                                member.role != 'ADMIN' &&
                                (member.auth?.id ?? '') != myAuthId &&
                                (member.auth?.id ?? '') != myUserId
                            ? CustomElevatedButton(
                                height: 30.h,
                                width: 100.w,
                                textSize: 10,
                                color: Colors.red,
                                title: 'Remove',
                                onPress: () {
                                  _showRemoveMember(member.id, widget.classId);
                                },
                              )
                            : Container(),
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
              final members = classMembersController.groupMemnersData ?? [];
              final Set<String?> existingMemberIds = members
                  .map((member) => member.auth?.id)
                  .toSet();

              final connections =
                  allConnectionController.allConnectionData ?? [];
              final filteredConnections = connections
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
                  final bool isPerson = connection.partner?.person != null;
                  final name = isPerson
                      ? connection.partner?.person?.name
                      : connection.partner?.business?.name;
                  final title = isPerson
                      ? connection.partner?.person?.title
                      : connection.partner?.business?.industry;
                  final imageUrl = isPerson
                      ? connection.partner?.person?.image
                      : connection.partner?.business?.image;

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
                              backgroundImage:
                                  (imageUrl != null && imageUrl.isNotEmpty)
                                  ? NetworkImage(imageUrl)
                                  : null,
                              backgroundColor: Colors.grey,
                              child: (imageUrl == null || imageUrl.isEmpty)
                                  ? const Icon(Icons.person)
                                  : null,
                            ),
                            widthBox10,
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name ?? ''),
                                heightBox4,
                                Text(
                                  title ?? '',
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
