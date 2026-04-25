import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:crash_safe_image/crash_safe_image.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/core/utils/show_over_loading.dart';
import 'package:wisper/app/core/utils/snack_bar.dart';
import 'package:wisper/app/core/widgets/common/circle_icon.dart';
import 'package:wisper/app/core/widgets/common/custom_button.dart';
import 'package:wisper/app/core/widgets/common/line_widget.dart';
import 'package:wisper/app/modules/chat/controller/all_community_controller.dart';
import 'package:wisper/app/modules/chat/controller/all_group_controller.dart';
import 'package:wisper/app/modules/chat/views/group/group_info_screen.dart';
import 'package:wisper/app/modules/chat/views/group/group_message_screen.dart';
import 'package:wisper/app/modules/homepage/controller/join_group_controller.dart';
import 'package:wisper/app/modules/homepage/views/create_post_screen.dart';
import 'package:wisper/app/modules/homepage/views/role_section.dart';
import 'package:wisper/app/modules/job/views/job_section.dart';
import 'package:wisper/app/modules/post/views/post_section.dart';
import 'package:wisper/gen/assets.gen.dart';

class CommunityScreen extends StatefulWidget {
  final String? chatId;
  final String? groupId;
  final String? groupName;
  final List<String>? memberImage;
  final int? memberCount;

  final bool? hasJoined;
  const CommunityScreen({
    super.key,
    this.chatId,
    this.groupId,
    this.hasJoined,
    this.groupName,
    this.memberImage,
    this.memberCount,
  });

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final JoinGroupController joinGroupController = JoinGroupController();

  int selectedIndex = 0;
  int _postSectionVersion = 0;
  int _jobSectionVersion = 0;
  int _roleSectionVersion = 0;
  int _uploadSectionVersion = 0;
  late bool _hasJoined;
  String _chatId = '';

  bool _isValidImagePath(String path) {
    final trimmed = path.trim();
    if (trimmed.isEmpty) return false;
    final lowered = trimmed.toLowerCase();
    return lowered != 'null' && lowered != 'undefined';
  }

  bool _isAssetPath(String path) {
    final trimmed = path.trim();
    return trimmed.startsWith('assets/') || trimmed.startsWith('packages/');
  }

  String _initialsFromName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      final word = parts.first;
      return word.length == 1
          ? word.toUpperCase()
          : '${word[0]}${word[word.length - 1]}'.toUpperCase();
    }
    final first = parts.first.isNotEmpty ? parts.first[0] : '';
    final last = parts.last.isNotEmpty ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  Widget _buildMemberImageAvatar(String imagePath, String fallbackText) {
    if (!_isValidImagePath(imagePath)) {
      return CircleAvatar(
        radius: 11.r,
        backgroundColor: const Color(0xff1A2732),
        child: Text(
          _initialsFromName(fallbackText),
          style: TextStyle(
            color: Colors.white,
            fontSize: 8.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    final bool isAsset = _isAssetPath(imagePath);

    return CircleAvatar(
      radius: 11.r,
      backgroundColor: const Color(0xff1A2732),
      child: CircleAvatar(
        radius: 10.r,
        backgroundImage: isAsset ? null : NetworkImage(imagePath),
        backgroundColor: const Color(0xff1A2732),
        child: isAsset
            ? ClipOval(
                child: CrashSafeImage(
                  imagePath,
                  height: 20.h,
                  width: 20.w,
                  fit: BoxFit.cover,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildMembersPreview(List<String> images) {
    final String fallbackText = widget.groupName ?? '';
    return SizedBox(
      width: (images.length * 14.w) + 10.w,
      height: 24.h,
      child: Stack(
        children: [
          for (int i = 0; i < images.length; i++)
            Positioned(
              left: i * 14.w,
              child: _buildMemberImageAvatar(images[i], fallbackText),
            ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _hasJoined = widget.hasJoined ?? false;
    _chatId = widget.chatId ?? '';
  }

  void joinGroup(String? groupId, String? groupName, String? groupImage) {
    showLoadingOverLay(
      asyncFunction: () async =>
          await performJoinGroup(context, groupId, groupName, groupImage),
      msg: 'Please wait...',
    );
  }

  Future<void> performJoinGroup(
    BuildContext context,
    String? groupId,
    String? name,
    String? image,
  ) async {
    final bool isSuccess = await joinGroupController.joinGroup(
      groupId: groupId,
    );

    if (isSuccess) {
      if (Get.isRegistered<AllGroupController>()) {
        final groupInfoController = Get.find<AllGroupController>();
        await groupInfoController.getAllGroup();
      }
      if (Get.isRegistered<CommunityController>()) {
        await Get.find<CommunityController>().getCommunities();
      }
      if (!mounted) return;
      setState(() {
        _hasJoined = true;
        _chatId = joinGroupController.chatId;
      });
      showSnackBarMessage(context, 'Joined successfully', false);
    } else {
      showSnackBarMessage(context, joinGroupController.errorMessage, true);
    }
  }
  

  @override
  Widget build(BuildContext context) {
    final List<String> previewMembers = (widget.memberImage ?? const [])
        .map((e) => e.trim())
        .take(3)
        .toList();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            heightBox40,
            Row(
              children: [
                CircleIconWidget(
                  iconRadius: 18,
                  color: Colors.black,
                  imagePath: Assets.images.arrowBack.keyName,
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                widthBox8,
                GestureDetector(
                  onTap: () {
                    Get.to(
                      GroupInfoScreen(
                        groupId: widget.groupId,
                        chatId: widget.chatId ?? '',
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.groupName ?? '',
                        style: TextStyle(
                          fontFamily: "Segoe UI",
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      // heightBox4,
                      Row(
                        children: [
                          if (previewMembers.isNotEmpty)
                            _buildMembersPreview(previewMembers),
                          if (previewMembers.isNotEmpty) SizedBox(width: 8.w),
                          Text(
                            '${widget.memberCount ?? 0} members',
                            style: TextStyle(
                              fontFamily: "Segoe UI",
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            heightBox12,
            SizedBox(
              height: 30.h,
              width: double.infinity,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildTab('General Chat', 0, 90.w),
                  widthBox20,

                  _buildTab('Posts', 1, 40.w),
                  widthBox20,

                  _buildTab('Jobs', 2, 40.w),
                  widthBox20,

                  _buildTab('Role', 3, 40.w),

                  widthBox20,

                  _buildTab('Upload', 4, 50.w),
                ],
              ),
            ),
            StraightLiner(height: 0.4, color: const Color(0xff454545)),

            // heightBox14,
            Expanded(
              child: IndexedStack(
                index: selectedIndex,
                children: [
                  // Tab 0: General Chat
                  SizedBox.expand(
                    child: !_hasJoined
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'You are not join this group.',
                                  style: TextStyle(color: Colors.white70),
                                ),
                                SizedBox(height: 12.h),
                                CustomElevatedButton(
                                  height: 40.h,
                                  width: 130.w,
                                  title: 'Join Now',
                                  textSize: 12.sp,
                                  onPress: () => joinGroup(
                                    widget.groupId,
                                    widget.groupName,
                                    '',
                                  ),
                                ),
                              ],
                            ),
                          )
                        : (_chatId.isEmpty)
                        ? const Center(
                            child: Text(
                              'General Chat is not configured',
                              style: TextStyle(color: Colors.white70),
                            ),
                          )
                        : GroupChatScreen(
                            isGeneralChat: true,
                            chatId: _chatId,
                            groupId: widget.groupId,
                            groupName: 'General Chat',
                            groupImage: '',
                          ),
                  ),

                  // Tab 1: Posts
                  SizedBox.expand(
                    child: PostSection(
                      key: ValueKey('post_section_$_postSectionVersion'),
                      groupId: widget.groupId,
                    ),
                  ),

                  // Tab 2: Jobs
                  SizedBox.expand(
                    child: JobSection(
                      key: ValueKey('job_section_$_jobSectionVersion'),
                      groupId: widget.groupId,
                    ),
                  ),

                  // Tab 3: Role
                  SizedBox.expand(
                    child: RoleSection(
                      key: ValueKey('role_section_$_roleSectionVersion'),
                      groupId: widget.groupId,
                    ),
                  ),

                  // Tab 4: Upload
                  SizedBox.expand(
                    child: CreatePostScreen(
                      key: ValueKey('upload_section_$_uploadSectionVersion'),
                      groupId: widget.groupId,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, int index, double underlineWidth) {
    final isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          if (index == 1) {
            _postSectionVersion++;
          }
          if (index == 2) {
            _jobSectionVersion++;
          }
          if (index == 3) {
            _roleSectionVersion++;
          } else if (index == 4) {
            _uploadSectionVersion++;
          }
          selectedIndex = index;
        });
      },
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: "Segoe UI",
              fontSize: index == 0 ? 15.sp : 14.sp,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xff93A4B0),
            ),
          ),
          heightBox4,
          Container(
            height: 2.h,
            width: underlineWidth,
            color: isSelected ? Colors.blue : Colors.transparent,
          ),
        ],
      ),
    );
  }
}
