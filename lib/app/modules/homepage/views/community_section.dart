import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:wisper/app/modules/chat/controller/all_community_controller.dart';
import 'package:wisper/app/modules/chat/widgets/communities_list_title.dart';
import 'package:wisper/app/modules/homepage/views/community_screen.dart';

class CommunitySection extends StatefulWidget {
  const CommunitySection({super.key});

  @override
  State<CommunitySection> createState() => _CommunitySectionState();
}

class _CommunitySectionState extends State<CommunitySection> {
  final CommunityController controller = Get.put(CommunityController());
  

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.getCommunities(); // Initial load
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

 

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.inProgress) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.communitiesData == null ||
          controller.communitiesData!.isEmpty) {
        return Center(
          child: Text(
            'No communities yet',
            style: TextStyle(color: Colors.white70, fontSize: 12.sp),
          ),
        );
      }
      var groupData = controller.communitiesData;
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: groupData?.length,
        itemBuilder: (context, index) {
          final item = groupData?[index];
          final List<String> membersImages = (item?.members ?? const [])
              .map((e) => (e.image ?? '').toString().trim())
              .toList();
          return CommunitiesListTile(
            memberCount: item?.memberCount ?? 0,
            membersImage: membersImages,
            isOnline: false,
            onTap: () async {
              await Get.to(
                CommunityScreen(
                  hasJoined: item?.isJoined ?? false,
                  groupId: item?.id ?? '',
                  chatId: item?.chatId ?? '',
                  groupName: item?.name ?? '',
                  memberImage: membersImages,
                  memberCount: item?.memberCount ?? 0,
                ),
              );
              await controller.getCommunities();
            },
            isGroup: true,
            imagePath: item?.image ?? '',
            name: item?.name ?? '',
            message: '',
            time: '',
          );
        },
      );
    });
  }
}
