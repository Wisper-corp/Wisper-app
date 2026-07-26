import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/config/theme/light_theme_colors.dart';
import 'package:wisper/app/core/utils/date_formatter.dart';
import 'package:wisper/app/core/widgets/shimmer/gallery_post_shimmer.dart';
import 'package:wisper/app/modules/post/controller/feed_post_controller.dart';
import 'package:wisper/app/modules/post/views/comment_screen.dart';
import 'package:wisper/app/modules/post/widgets/post_card.dart';
import 'package:wisper/app/core/widgets/common/star_rating.dart';

class PostSection extends StatefulWidget {
  final String? groupId;
  final String? searchQuery;
  const PostSection({super.key, this.groupId, this.searchQuery});

  @override
  State<PostSection> createState() => _PostSectionState();
}

class _PostSectionState extends State<PostSection> {
  late final AllFeedPostController controller;

  String get _tag => widget.groupId != null && widget.groupId!.isNotEmpty
      ? 'posts_group_${widget.groupId}'
      : 'posts_global';

  @override
  void initState() {
    super.initState();
    // Use tagged controller so group posts don't overwrite global feed
    controller = Get.isRegistered<AllFeedPostController>(tag: _tag)
        ? Get.find<AllFeedPostController>(tag: _tag)
        : Get.put(AllFeedPostController(), tag: _tag);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Single call — resetPagination passes groupId into the fetch
      controller.resetPagination(groupId: widget.groupId, searchQuery: widget.searchQuery);
    });
  }

  @override
  void didUpdateWidget(covariant PostSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != oldWidget.searchQuery) {
      controller.resetPagination(groupId: widget.groupId, searchQuery: widget.searchQuery);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
        if (controller.inProgress) {
          return const Center(child: PostShimmerEffectWidget());
        }

        if (controller.allPostData.isEmpty) {
          return const SizedBox.expand(
            child: Center(
              child: Text(
                'No posts yet',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
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

            return _PostItem(
              post: post,
              formattedTime: formattedTime,
              controller: controller,
            );
          },
        );
      });
  }
}

/// Stateful wrapper so we can increment the view once when the item first appears
class _PostItem extends StatefulWidget {
  final dynamic post;
  final String formattedTime;
  final AllFeedPostController controller;

  const _PostItem({
    required this.post,
    required this.formattedTime,
    required this.controller,
  });

  @override
  State<_PostItem> createState() => _PostItemState();
}

class _PostItemState extends State<_PostItem> {
  @override
  void initState() {
    super.initState();
    // Increment view once when the post widget is first built (visible in list)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.incrementView(widget.post.id ?? '');
    });
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: PostCard(
        isPerson: post.author?.person != null,
        onTapComment: () {
          Get.to(CommentScreen(postId: post.id ?? ''));
        },
        isComment: false,
        ownerId: post.author?.id ?? '',
        trailing: const SizedBox.shrink(),
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
        postTime: widget.formattedTime,
        views: post.views.toString(),
        price: post.price,
        deliveryTime: post.deliveryTime,
        currency: post.currency,
        ratingWidget: post.ratingCount > 0
            ? StarRating(rating: post.avgRating, count: post.ratingCount)
            : null,
      ),
    );
  }
}
