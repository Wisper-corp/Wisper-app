// lib/app/modules/post/views/my_post_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:wisper/app/core/config/theme/light_theme_colors.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/core/utils/date_formatter.dart';
import 'package:wisper/app/core/utils/show_over_loading.dart';
import 'package:wisper/app/core/utils/snack_bar.dart';
import 'package:wisper/app/core/widgets/common/circle_icon.dart';
import 'package:wisper/app/core/widgets/common/custom_button.dart';
import 'package:wisper/app/core/widgets/common/custom_popup.dart';
import 'package:wisper/app/core/widgets/shimmer/gallery_post_shimmer.dart';
import 'package:wisper/app/modules/post/controller/delete_gallery_post_controlller.dart';
import 'package:wisper/app/modules/post/controller/feed_post_controller.dart';
import 'package:wisper/app/modules/post/controller/my_post_controller.dart';
import 'package:wisper/app/modules/post/views/comment_screen.dart';
import 'package:wisper/app/modules/post/views/edit_gallery_post.dart';
import 'package:wisper/app/modules/post/widgets/post_card.dart';
import 'package:wisper/app/modules/settings/views/boost_screen.dart';
import 'package:wisper/gen/assets.gen.dart';

class MyPostSection extends StatefulWidget {
  const MyPostSection({super.key});

  @override
  State<MyPostSection> createState() => _MyPostSectionState();
}

class _MyPostSectionState extends State<MyPostSection> {
  final MyFeedPostController controller = Get.find<MyFeedPostController>();
  final DeletePostController deletePostController = Get.put(
    DeletePostController(),
  );

  @override
  void initState() {
    super.initState();
    controller.getAllPost();
  }

  Future<void> _handleDeletePost(String postId) async {
    showLoadingOverLay(
      asyncFunction: () async {
        final bool success = await deletePostController.deletePost(
          postId: postId,
        );

        if (success) {
          final myFeedCtrl = Get.find<MyFeedPostController>();
          final allFeedCtrl = Get.find<AllFeedPostController>();

          allFeedCtrl.resetPagination();
          myFeedCtrl.resetPagination();
          await myFeedCtrl.getAllPost();

          showSnackBarMessage(context, "Post deleted successfully!", false);
        } else {
          showSnackBarMessage(context, deletePostController.errorMessage, true);
        }
      },
      msg: 'Deleting post...',
    );
  }

  void _showDeleteConfirmation(String postId) {
    ConfirmationBottomSheet.show(
      context: context,
      title: "Delete Post?",
      message:
          "This post will be permanently removed.\nThis action cannot be undone.",
      onDelete: () {
        _handleDeletePost(postId);
      },
      // deleteText: "Delete Now", // optional customization
      // cancelText: "Keep it",   // optional
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.inProgress) {
        return const PostShimmerEffectWidget();
      }

      if (controller.allPostData.isEmpty) {
        return Center(
          child: Text(
            'No posts yet',
            style: TextStyle(color: Colors.white70, fontSize: 14.sp),
          ),
        );
      }

      return ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: controller.allPostData.length,
        itemBuilder: (context, index) {
          final post = controller.allPostData[index];
          final formattedTime = DateFormatter(post.createdAt ?? DateTime.now());

          final GlobalKey suffixKey = GlobalKey();

          final popup = CustomPopupMenu(
            targetKey: suffixKey,
            options: [
              Text(
                'Boost Post',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: LightThemeColors.blueColor,
                ),
              ),
              Text(
                'Edit Post',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              Text(
                'Delete Post',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.redAccent,
                ),
              ),
            ],
            optionActions: {
              '0': () => Get.to(() => BoostScreen(feedPostItemModel: post)),
              '1': () =>
                  Get.to(() => EditGalleryPostScreen(feedPostItemModel: post)),
              '2': () => _showDeleteConfirmation(post.id ?? ''),
            },
            menuWidth: 180.w,
            menuHeight: 48.h * 3, // approximate for 3 items
          );

          return Padding(
            padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 4.w),
            child: PostCard(
              isPerson: post.author?.person != null,
              onTapComment: () {
                if (post.id != null) {
                  Get.to(() => CommentScreen(postId: post.id!));
                }
              },
              isComment: true,
              ownerId: post.author?.id ?? '',
              trailing: GestureDetector(
                key: suffixKey,
                onTap: () => popup.showMenuAtPosition(context),
                child: const Icon(
                  Icons.more_vert_rounded,
                  color: Color(0xff8C8C8C),
                  size: 26,
                ),
              ),
              ownerName: StorageUtil.getData(StorageUtil.userRole) == 'PERSON'
                  ? post.author?.person?.name ?? 'Unknown'
                  : post.author?.business?.name ?? 'Unknown',
              ownerImage: StorageUtil.getData(StorageUtil.userRole) == 'PERSON'
                  ? post.author?.person?.image ?? ''
                  : post.author?.business?.image ?? '',
              ownerProfession:
                  StorageUtil.getData(StorageUtil.userRole) == 'PERSON'
                  ? post.author?.person?.title ?? ''
                  : post.author?.business?.industry ?? '',
              postImage: post.images.isNotEmpty ? post.images : [],
              postDescription: post.caption ?? '',
              postTime: formattedTime.getRelativeTimeFormat(),
              views: post.views?.toString() ?? '0',
              price: post.price,
              currency: post.currency,
              deliveryTime: post.deliveryTime,
            ),
          );
        }, 
      );
    });
  }
}

// lib/app/core/widgets/common/delete_confirmation_bottomsheet.dart

class ConfirmationBottomSheet extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onTap;
  final String? deleteButtonText;
  final String? cancelButtonText;

  const ConfirmationBottomSheet({
    super.key,
    this.title = 'Delete?',
    this.message = 'Are you sure you want to delete?',
    required this.onTap,
    this.deleteButtonText = 'Delete',
    this.cancelButtonText = 'Discard',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.3,
      padding: EdgeInsets.all(20.w),
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleIconWidget(
            imagePath: Assets.images.delete.keyName,
            onTap: () {},
            iconRadius: 22.r,
            radius: 24.r,
            color: const Color(0xff312609),
            iconColor: const Color(0xffDC8B44),
          ),
          heightBox20,
          Text(
            title,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          heightBox8,
          Text(
            message,
            style: TextStyle(fontSize: 14.sp, color: const Color(0xff9FA3AA)),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: CustomElevatedButton(
                  color: const Color.fromARGB(255, 15, 15, 15),
                  borderColor: const Color(0xff262629),
                  title: cancelButtonText!,
                  onPress: () => Get.back(),
                ),
              ),
              widthBox12,
              Expanded(
                child: CustomElevatedButton(
                  color: const Color(0xffE62047),
                  title: deleteButtonText!,
                  onPress: () {
                    onTap(); // delete action
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Static method for easy usage
  static void show({
    required BuildContext context,
    String title = 'Delete?',
    String message = 'Are you sure you want to delete?',
    required VoidCallback onDelete,
    String deleteButtonText = 'Delete',
    String cancelButtonText = 'Discard',
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ConfirmationBottomSheet(
        title: title,
        message: message,
        onTap: onDelete,
        deleteButtonText: deleteButtonText,
        cancelButtonText: cancelButtonText,
      ),
    );
  } 
}
