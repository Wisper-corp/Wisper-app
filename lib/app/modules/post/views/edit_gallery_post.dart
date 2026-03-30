// EditGalleryPostScreen.dart - Final, Error-Free & Super Simple

import 'dart:io';
import 'package:crash_safe_image/crash_safe_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/config/theme/light_theme_colors.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/core/utils/show_over_loading.dart';
import 'package:wisper/app/core/utils/snack_bar.dart';
import 'package:wisper/app/core/widgets/common/custom_button.dart';
import 'package:wisper/app/core/widgets/common/custom_text_filed.dart';
import 'package:wisper/app/core/widgets/common/image_picker.dart';
import 'package:wisper/app/core/widgets/common/line_widget.dart';
import 'package:wisper/app/modules/post/controller/create_post_controller.dart';
import 'package:wisper/app/modules/post/controller/feed_post_controller.dart';
import 'package:wisper/app/modules/post/controller/my_post_controller.dart';
import 'package:wisper/app/modules/post/model/feed_post_model.dart';
import 'package:wisper/gen/assets.gen.dart';

class EditGalleryPostScreen extends StatefulWidget {
  final FeedPostItemModel feedPostItemModel;
  const EditGalleryPostScreen({super.key, required this.feedPostItemModel});

  @override
  State<EditGalleryPostScreen> createState() => _EditGalleryPostScreenState();
}

class _EditGalleryPostScreenState extends State<EditGalleryPostScreen> {
  final TextEditingController _captionCtrl = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final ImagePickerHelper _imagePickerHelper = ImagePickerHelper();

  String _selectedPrivacy = 'EVERYONE';

  // পুরাতন ইমেজ URL গুলো
  List<String> _existingImages = [];

  // নতুন যোগ করা ইমেজ ফাইল
  List<File> _newImages = [];

  @override
  void initState() {
    super.initState();
    _captionCtrl.text = widget.feedPostItemModel.caption ?? '';
    _selectedPrivacy = widget.feedPostItemModel.commentAccess ?? 'EVERYONE';
    _existingImages = List.from(widget.feedPostItemModel.images);
  }

  void _addImage(File file) => setState(() => _newImages.add(file));

  void _removeOldImage(String url) =>
      setState(() => _existingImages.remove(url));

  void _removeNewImage(File file) => setState(() => _newImages.remove(file));

  void _updatePost() async {
    if (!formKey.currentState!.validate()) return;

    showLoadingOverLay(
      asyncFunction: () async {
        final controller = Get.find<CreatePostController>();

        final imagesToDelete = widget.feedPostItemModel.images
            .where((img) => !_existingImages.contains(img))
            .toList();

        bool success = await controller.updatePost(
          postId: widget.feedPostItemModel.id,
          privacy: _selectedPrivacy,
          description: _captionCtrl.text.trim(),
          images: _newImages,
        );

        if (success) {
          final MyFeedPostController myFeedPostController =
              Get.find<MyFeedPostController>();
          final AllFeedPostController allFeedPostController =
              Get.find<AllFeedPostController>();

          allFeedPostController.resetPagination();
          await allFeedPostController.getAllPost();
          myFeedPostController.resetPagination();
          await myFeedPostController.getAllPost();
          Navigator.pop(context);
          showSnackBarMessage(context, "Post updated successfully!", false);
        } else {
          showSnackBarMessage(context, "Update failed", true);
        }
      },
      msg: 'Updating post...',
    );
  }

  @override
  Widget build(BuildContext context) {
    final allImages = [
      ..._existingImages.map((url) => {'type': 'url', 'data': url}),
      ..._newImages.map((file) => {'type': 'file', 'data': file}),
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Form(
            key: formKey,
            child: Column(
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: Colors.white, fontSize: 15.sp),
                      ),
                    ),
                    Text(
                      'Edit Post',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(
                      height: 38.h,
                      width: 90.w,
                      child: CustomElevatedButton(
                        title: 'Update',
                        onPress: _updatePost,
                        borderRadius: 50,
                      ),
                    ),
                  ],
                ),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        heightBox20,

                        // User Info
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 22.r,
                              backgroundImage: AssetImage(
                                Assets.images.image.keyName,
                              ),
                            ),
                            widthBox12,
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Aminul Islam',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16.sp,
                                  ),
                                ),
                                Text(
                                  'Flutter Developer',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        heightBox20,

                        // Caption
                        CustomTextField(
                          controller: _captionCtrl,
                          maxLines: 6,
                          hintText: 'Write a caption...',
                        ),

                        heightBox20,
                        StraightLiner(height: 0.5),

                        heightBox20,

                        // Privacy Selector
                        GestureDetector(
                          onTap: () => _showPrivacyDialog(),
                          child: Row(
                            children: [
                              Icon(
                                Icons.public,
                                color: LightThemeColors.blueColor,
                                size: 24.sp,
                              ),
                              widthBox10,
                              Text(
                                _selectedPrivacy == 'EVERYONE'
                                    ? 'Everyone can comment'
                                    : 'Followers',
                                style: TextStyle(
                                  color: LightThemeColors.blueColor,
                                  fontSize: 15.sp,
                                ),
                              ),
                              Spacer(),
                              Icon(
                                Icons.keyboard_arrow_right,
                                color: LightThemeColors.blueColor,
                              ),
                            ],
                          ),
                        ),

                        heightBox20,

                        // Add Photos
                        GestureDetector(
                          onTap: () => _imagePickerHelper.showAlertDialog(
                            context,
                            _addImage,
                          ),
                          child: Row(
                            children: [
                              CrashSafeImage(
                                Assets.images.gallery02.keyName,
                                height: 28.h,
                              ),
                              widthBox10,
                              Text(
                                'Add Photos',
                                style: TextStyle(
                                  color: LightThemeColors.blueColor,
                                  fontSize: 15.sp,
                                ),
                              ),
                            ],
                          ),
                        ),

                        heightBox20,

                        // All Images Grid
                        Wrap(
                          spacing: 12.w,
                          runSpacing: 12.h,
                          children: allImages.map((item) {
                            final String type = item['type'] as String;
                            final dynamic data = item['data'];

                            if (type == 'url') {
                              return _imageBox(
                                url: data as String,
                                onRemove: () => _removeOldImage(data),
                              );
                            } else {
                              return _imageBox(
                                file: data as File,
                                onRemove: () => _removeNewImage(data),
                              );
                            }
                          }).toList(),
                        ),

                        if (allImages.isEmpty)
                          Padding(
                            padding: EdgeInsets.only(top: 80.h),
                            child: Center(
                              child: Text(
                                'No photos added yet',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ),

                        heightBox10,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // একটা ছোট উইজেট — পুরাতন + নতুন দুই ধরনের ইমেজ দেখাবে
  Widget _imageBox({String? url, File? file, required VoidCallback onRemove}) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12.r),
          child: url != null
              ? CrashSafeImage(
                  url,
                  width: 120.w,
                  height: 120.h,
                  fit: BoxFit.cover,
                )
              : Image.file(
                  file!,
                  width: 120.w,
                  height: 120.h,
                  fit: BoxFit.cover,
                ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close, color: Colors.white, size: 16.sp),
            ),
          ),
        ),
      ],
    );
  }

  // Privacy Bottom Sheet — সবচেয়ে সিম্পল
  void _showPrivacyDialog() {
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 5.h,
              decoration: BoxDecoration(
                color: Color(0xff8C8C8C),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            heightBox20,
            Text(
              'Who can comment on this post?',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: LightThemeColors.blueColor,
              ),
            ),
            heightBox20,

            _privacyOption('Everyone can comment', 'EVERYONE', Icons.public),
            _privacyOption('Followers ', 'FOLLOWERS', Icons.lock_outline),

            heightBox20,
          ],
        ),
      ),
    );
  }

  Widget _privacyOption(String title, String value, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: LightThemeColors.blueColor),
      title: Text(
        title,
        style: TextStyle(fontSize: 16.sp, color: LightThemeColors.blueColor),
      ),
      trailing: _selectedPrivacy == value
          ? Icon(Icons.check, color: LightThemeColors.blueColor)
          : null,
      onTap: () {
        setState(() => _selectedPrivacy = value);
        Get.back(); // bottom sheet বন্ধ
      },
    );
  }
}
