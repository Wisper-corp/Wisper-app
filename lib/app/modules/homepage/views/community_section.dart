import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/utils/show_over_loading.dart';
import 'package:wisper/app/core/utils/snack_bar.dart';
import 'package:wisper/app/modules/chat/controller/all_group_controller.dart';
import 'package:wisper/app/modules/chat/views/group/group_message_screen.dart';
import 'package:wisper/app/modules/chat/widgets/member_list_title.dart';
import 'package:wisper/app/modules/homepage/controller/join_group_controller.dart';

class CommunitySection extends StatefulWidget {
  const CommunitySection({super.key});

  @override
  State<CommunitySection> createState() => _CommunitySectionState();
}

class _CommunitySectionState extends State<CommunitySection> {
  final AllGroupController controller = Get.put(AllGroupController());
  final JoinGroupController joinGroupController = JoinGroupController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.getAllGroup(); // Initial load
    });
  }

  @override
  void dispose() {
    super.dispose();
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
    return Obx(() {
      if (controller.inProgress) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.allGroupData == null ||
          controller.allGroupData!.isEmpty) {
        return Center(
          child: Text(
            'No communities yet',
            style: TextStyle(color: Colors.white70, fontSize: 12.sp),
          ),
        );
      }
      var groupData = controller.allGroupData;
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: groupData?.length,
        itemBuilder: (context, index) {
          final item = groupData?[index];

          return MemberListTile(
            isOnline: false, // usually no "online" for group/class
            onTap: () {
              joinGroup(item?.id, item?.name, item?.image);
            },

            isGroup: true,
            isClass: false,
            imagePath: item?.image ?? '',
            name: item?.name ?? '',
            message: '',
            time: '',
            unreadMessageCount: '',
          );
        },
      );
    });
  }
}
