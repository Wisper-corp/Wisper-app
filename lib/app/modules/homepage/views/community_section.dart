import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/services/socket/socket_service.dart';
import 'package:wisper/app/core/utils/show_over_loading.dart';
import 'package:wisper/app/core/utils/snack_bar.dart';
import 'package:wisper/app/core/widgets/common/initials_avatar.dart';
import 'package:wisper/app/modules/chat/controller/all_group_controller.dart';
import 'package:wisper/app/modules/chat/model/all_group_model.dart';
import 'package:wisper/app/modules/chat/views/group/group_message_screen.dart';
import 'package:wisper/app/modules/homepage/controller/join_group_controller.dart';

class CommunitySection extends StatefulWidget {
  const CommunitySection({super.key});

  @override
  State<CommunitySection> createState() => _CommunitySectionState();
}

class _CommunitySectionState extends State<CommunitySection> {
  final AllGroupController controller = Get.put(AllGroupController());
  final JoinGroupController joinGroupController = JoinGroupController();
  final SocketService socketService = Get.find<SocketService>();

  /// Returns the chatId if the user has already joined this group
  String? _joinedChatId(String? groupId) {
    if (groupId == null) return null;
    final joined = socketService.socketFriendList.firstWhereOrNull(
      (item) => item['groupId'] == groupId,
    );
    return joined?['id'] as String?;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.getAllGroup();
    });
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
    final bool isSuccess = await joinGroupController.joinGroup(groupId: groupId);
    if (isSuccess) {
      final groupInfoController = Get.find<AllGroupController>();
      await groupInfoController.getAllGroup();
      Get.to(
        () => GroupChatScreen(
          chatId: joinGroupController.chatId,
          groupId: groupId,
          groupName: name,
          groupImage: image,
        ),
      );
    } else {
      showSnackBarMessage(context, joinGroupController.errorMessage, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Obx(() {
        if (controller.inProgress) {
          return const Center(child: CircularProgressIndicator());
        }

        final groupData = controller.allGroupData;

        if (groupData == null || groupData.isEmpty) {
          return Center(
            child: Text(
              'No communities yet',
              style: TextStyle(color: Colors.white70, fontSize: 12.sp),
            ),
          );
        }

        return ListView.separated(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
          itemCount: groupData.length,
          separatorBuilder: (_, __) => Divider(
            color: const Color(0xff2A2A2A),
            height: 1,
            thickness: 0.5,
          ),
          itemBuilder: (context, index) {
            final item = groupData[index];
            return _CommunityCard(
              item: item,
              onTap: () {
                final existingChatId = _joinedChatId(item.id);
                if (existingChatId != null) {
                  Get.to(
                    () => GroupChatScreen(
                      chatId: existingChatId,
                      groupId: item.id,
                      groupName: item.name,
                      groupImage: item.image?.toString(),
                    ),
                  );
                } else {
                  joinGroup(item.id, item.name, item.image?.toString());
                }
              },
            );
          },
        );
      }),
    );
  }
}

class _CommunityCard extends StatelessWidget {
  final AllGroupItemModel item;
  final VoidCallback onTap;

  const _CommunityCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final memberCount = item.chat?.count?.participants ?? 0;
    final participants = item.chat?.participants ?? [];

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Group avatar
            InitialsAvatar(
              name: item.name ?? 'G',
              imageUrl: item.image?.toString(),
              radius: 28.r,
              fontSize: 18,
            ),
            SizedBox(width: 14.w),

            // Name + member count + member avatars
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name ?? '',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    '$memberCount ${memberCount == 1 ? 'Member' : 'Members'}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.white54,
                    ),
                  ),
                  if (participants.isNotEmpty) ...[
                    SizedBox(height: 6.h),
                    _MemberAvatarRow(participants: participants),
                  ],
                ],
              ),
            ),

            // Chevron
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white38,
              size: 20.sp,
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberAvatarRow extends StatelessWidget {
  final List<GroupParticipant> participants;

  const _MemberAvatarRow({required this.participants});

  @override
  Widget build(BuildContext context) {
    const double size = 22;
    const double overlap = 10;
    final count = participants.length.clamp(0, 3);

    return SizedBox(
      height: size,
      width: size + (count - 1) * (size - overlap),
      child: Stack(
        children: List.generate(count, (i) {
          final p = participants[i];
          return Positioned(
            left: i * (size - overlap).toDouble(),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xff121212), width: 1.5),
              ),
              child: InitialsAvatar(
                name: p.name ?? '?',
                imageUrl: p.image,
                radius: size / 2,
                fontSize: 8,
              ),
            ),
          );
        }),
      ),
    );
  }
}
