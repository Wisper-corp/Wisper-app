import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/config/theme/light_theme_colors.dart';
import 'package:wisper/app/core/utils/date_formatter.dart';
import 'package:wisper/app/core/utils/connectivity_services.dart';
import 'package:wisper/app/core/widgets/shimmer/gallery_post_shimmer.dart';
import 'package:wisper/app/modules/post/controller/others_post_controller.dart';
import 'package:wisper/app/modules/post/views/comment_screen.dart';
import 'package:wisper/app/modules/post/widgets/post_card.dart';

class OthersPostSection extends StatefulWidget {
  final String? userId;
  const OthersPostSection({super.key, this.userId});

  @override
  State<OthersPostSection> createState() => _OthersPostSectionState();
} 

class _OthersPostSectionState extends State<OthersPostSection> {
  final OthersFeedPostController controller = Get.put(
    OthersFeedPostController(),
  );
  final ConnectivityService connectivityService =
      Get.find<ConnectivityService>();

  @override
  void initState() {
    super.initState();
    print('User ID: ${widget.userId}');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.resetPagination();
      print('User ID avobe callback: ${widget.userId}');
      controller.getAllPost(userId: widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      // Expanded Obx এর বাইরে → সমস্যা সমাধান!
      child: Obx(() {
        if (controller.inProgress) {
          return PostShimmerEffectWidget();
        }

        if (controller.allPostData.isEmpty) {
          if (!connectivityService.isOnline.value) {
            return const Center(child: PostShimmerEffectWidget());
          }
          return const Center(
            child: Text(
              'No posts yet',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: controller.allPostData.length,
          itemBuilder: (context, index) {
            final post = controller.allPostData[index];
            final formattedTime = DateFormatter(
              post.createdAt!,
            ).getRelativeTimeFormat();

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              
              child: PostCard(
                isPerson: post.author?.person != null,
                isComment: false,
                onTapComment: () {
                   Get.to(CommentScreen(postId: post.id ?? ''));
                },
                commentCount: post.count?.comment ?? 0,
                ownerId: post.author?.id ?? '',
                trailing: const Text(
                  '',
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    color: LightThemeColors.themeGreyColor,
                  ),
                ),
                ownerName: post.author?.person != null
                    ? post.author?.person?.name ?? ''
                    : post.author?.business?.name ?? '',
                ownerImage: post.author?.person != null
                    ? post.author?.person?.image
                    : post.author?.business?.image ?? '',
                ownerProfession: post.author?.person != null
                    ? post.author?.person?.title
                    : post.author?.business?.industry ?? '',
                postImage: post.images.isNotEmpty ? post.images : [],
                postDescription: post.caption ?? '',
                postTime: formattedTime,
                views: post.views.toString(),
              ),
            );
          },
        );
      }),
    );
  }
}
