import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/config/theme/light_theme_colors.dart';
import 'package:wisper/app/core/utils/date_formatter.dart';
import 'package:wisper/app/core/utils/connectivity_services.dart';
import 'package:wisper/app/core/widgets/shimmer/gallery_post_shimmer.dart';
import 'package:wisper/app/modules/post/controller/feed_post_controller.dart';
import 'package:wisper/app/modules/post/views/comment_screen.dart';
import 'package:wisper/app/modules/post/widgets/post_card.dart';
 
class PostSection extends StatefulWidget {
  const PostSection({super.key});

  @override
  State<PostSection> createState() => _PostSectionState();
}

class _PostSectionState extends State<PostSection> {
  final AllFeedPostController controller = Get.find<AllFeedPostController>();
  final ConnectivityService connectivityService =
      Get.find<ConnectivityService>();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.getAllPost();
    });
  }

  Future<void> _refreshPosts() async {
    controller.resetPagination();
    while (controller.inProgress) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshPosts,
      child: Obx(() {
        // Loading state
        if (controller.inProgress) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              SizedBox(height: 120),
              Center(child: PostShimmerEffectWidget()),
            ],
          );
        }

        // Empty list
        if (controller.allPostData.isEmpty) {
          if (!connectivityService.isOnline.value) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 120),
                Center(child: PostShimmerEffectWidget()),
              ],
            );
          }
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              SizedBox(height: 120),
              Center(
                child: Text(
                  'No posts yet',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ),
            ],
          );
        }

        // Main post list
        return ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
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
                onTapComment: () {
                  Get.to(CommentScreen(postId: post.id ?? ''));
                },
                isComment: false,
                ownerId: post.author?.id ?? '',
                trailing: const Text(
                  'Sponsor',
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    color: LightThemeColors.themeGreyColor,
                  ),
                ),
                ownerName: post.author?.person != null
                    ? post.author?.person?.name ?? 'Unknown User'
                    : post.author?.business?.name ?? 'Unknown Business',
                ownerImage: post.author?.person != null
                    ? post.author?.person?.image ?? ''
                    : post.author?.business?.image ?? '',
                ownerProfession: post.author?.person != null
                    ? post.author?.person?.title ?? 'Professional'
                    : post.author?.business?.name ?? 'Business',
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
