// ignore_for_file: use_build_context_synchronously
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/config/theme/light_theme_colors.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/core/utils/show_over_loading.dart';
import 'package:wisper/app/core/utils/snack_bar.dart';
import 'package:wisper/app/core/utils/currency_helper.dart';
import 'package:wisper/app/core/utils/validator_service.dart';
import 'package:wisper/app/core/widgets/common/custom_button.dart';
import 'package:wisper/app/core/widgets/common/custom_text_filed.dart';
import 'package:wisper/app/core/widgets/common/image_picker.dart';
import 'package:wisper/app/core/widgets/common/line_widget.dart';
import 'package:wisper/app/modules/post/controller/create_post_controller.dart';
import 'package:wisper/app/modules/post/controller/feed_post_controller.dart';
import 'package:wisper/app/modules/post/controller/my_post_controller.dart';
import 'package:wisper/app/modules/profile/controller/buisness/buisness_controller.dart';
import 'package:wisper/app/modules/profile/controller/person/profile_controller.dart';
import 'package:wisper/gen/assets.gen.dart';

class GalleryPostScreen extends StatefulWidget {
  final String? groupId;
  const GalleryPostScreen({super.key, this.groupId});

  @override
  State<GalleryPostScreen> createState() => _GalleryPostScreenState();
}

class _GalleryPostScreenState extends State<GalleryPostScreen> {
  final TextEditingController _captionCtrl = TextEditingController();
  final TextEditingController _priceCtrl = TextEditingController();
  final TextEditingController _deliveryTimeCtrl = TextEditingController();
  String _deliveryUnit = 'Days'; // Fixed to Days only
  final CreatePostController createPostController = CreatePostController();
  final ProfileController profileController = Get.find<ProfileController>();
  final BusinessController businessController = Get.find<BusinessController>();
  final formKey = GlobalKey<FormState>();
  final List<File> _selectedImages = [];
  final ImagePickerHelper _imagePickerHelper = ImagePickerHelper();

  String _selectedPrivacy = 'EVERYONE';

  // Role-based user info observables
  final RxBool isLoading = true.obs;
  final RxString userName = ''.obs;
  final RxString userSubtitle = ''.obs;
  final RxString userImageUrl = ''.obs;

  // Realtime character count
  final RxInt currentCaptionLength = 0.obs;
  final RxBool isCaptionLimitExceeded =
      false.obs; // নতুন: লিমিট ক্রস হয়েছে কিনা

  late final bool isPerson;

  static const int maxImages = 4;
  static const int maxCaptionLength = 60;

  void _addImage(File image) {
    if (_selectedImages.length >= maxImages) {
      showSnackBarMessage(context, "Maximum $maxImages images allowed!", true);
      return;
    }

    setState(() {
      _selectedImages.add(image);
    });
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void createPost() {
    if (_selectedImages.isEmpty) {
      showSnackBarMessage(
        context,
        "Please select at least one image to post!",
        true,
      );
      return;
    }
    if (isCaptionLimitExceeded.value) {
      showSnackBarMessage(
        context,
        "Caption exceeds maximum length of $maxCaptionLength characters!",
        true,
      );
      return;
    }
    if (!formKey.currentState!.validate()) {
      return;
    }

    showLoadingOverLay(
      asyncFunction: () async => await performCreatePost(),
      msg: 'Please wait...',
    );
  }

  Future<void> performCreatePost() async {
    double? price;
    if (_priceCtrl.text.trim().isNotEmpty) {
      price = double.tryParse(_priceCtrl.text.trim());
    }

    String? deliveryTime;
    if (_deliveryTimeCtrl.text.trim().isNotEmpty) {
      deliveryTime = '${_deliveryTimeCtrl.text.trim()} $_deliveryUnit';
    }

    final bool isSuccess = await createPostController.createPost(
      description: _captionCtrl.text.trim(),
      images: _selectedImages,
      privacy: _selectedPrivacy,
      price: price,
      deliveryTime: deliveryTime,
      groupId: widget.groupId,
    );

    if (isSuccess) {
      final AllFeedPostController feedController = Get.put(
        AllFeedPostController(),
      );
      final MyFeedPostController myFeedPostController = Get.put(
        MyFeedPostController(),
      );
      myFeedPostController.resetPagination();
      feedController.resetPagination();
      await myFeedPostController.getAllPost();
      await feedController.getAllPost();
      if (mounted) Navigator.pop(context);
      showSnackBarMessage(context, "Post created successfully!", false);
    } else {
      showSnackBarMessage(context, createPostController.errorMessage, true);
    }
  }

  void _updateUserInfo() {
    if (isPerson) {
      final data = profileController.profileData?.auth?.person;
      userName.value = data?.name ?? '';
      userSubtitle.value = data?.title ?? '';
      userImageUrl.value = data?.image ?? '';
      isLoading.value = profileController.inProgress;
    } else {
      final data = businessController.buisnessData?.auth?.business;
      userName.value = data?.name ?? '';
      userSubtitle.value = data?.industry ?? '';
      userImageUrl.value = data?.image ?? '';
      isLoading.value = businessController.inProgress;
    }
  }
 
  @override
  void initState() {
    super.initState();
    isPerson = StorageUtil.getData(StorageUtil.userRole) == 'PERSON';

    // Realtime caption length listener
    _captionCtrl.addListener(() {
      final length = _captionCtrl.text.length;
      currentCaptionLength.value = length;
      isCaptionLimitExceeded.value = length > maxCaptionLength;
    });

    if (isPerson) {
      profileController.getMyProfile().then((_) {
        if (mounted) _updateUserInfo();
      });
    } else {
      businessController.getMyProfile().then((_) {
        if (mounted) _updateUserInfo();
      });
    }
  }

  @override
  void dispose() {
    _captionCtrl.dispose();
    _priceCtrl.dispose();
    _deliveryTimeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox(
        height: double.infinity,
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  heightBox40,

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Text(
                        'Post on Marketplace',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      _selectedImages.isEmpty
                          ? SizedBox(
                              height: 32.h,
                              width: 66.w,
                              child: CustomElevatedButton(
                                color: Colors.grey,
                                title: 'Post',
                                textSize: 12,
                                borderRadius: 50,
                              ),
                            )
                          : SizedBox(
                              height: 32.h,
                              width: 66.w,
                              child: CustomElevatedButton(
                                title: 'Post',
                                textSize: 12,
                                borderRadius: 50,
                                onPress: createPost,
                              ),
                            ),
                    ],
                  ),

                  heightBox16,

                  Obx(() {
                    if (isLoading.value) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    return Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.grey,
                          radius: 18.r,
                          backgroundImage: userImageUrl.value.isNotEmpty
                              ? NetworkImage(userImageUrl.value)
                              : null,
                          child: userImageUrl.value.isEmpty
                              ? const Icon(Icons.person, color: Colors.white)
                              : null,
                        ),
                        widthBox8,
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName.value,
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w400,
                                color: Colors.white,
                              ),
                            ),
                            if (userSubtitle.value.isNotEmpty)
                              Text(
                                userSubtitle.value,
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  color: LightThemeColors.themeGreyColor,
                                ),
                              ),
                          ],
                        ),
                      ],
                    );
                  }),

                  heightBox20,

                  CustomTextField(
                    controller: _captionCtrl,
                    maxLength:
                        maxCaptionLength, // হার্ড লিমিট (ইনপুট বন্ধ করে দেয় ৬০ এর পর)
                    maxLines: 5,
                    hintText: 'Share your skill',
                    validator: ValidatorService.validateSimpleField,
                    hintStyle: TextStyle(
                      fontSize: 14.sp,
                      color: const Color(0xff8C8C8C),
                    ),
                  ),
                  heightBox4,

                  Obx(() {
                    final exceeded = isCaptionLimitExceeded.value;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exceeded
                              ? 'Max limit crossed'
                              : 'Maximum limit ${currentCaptionLength.value}/60',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: exceeded
                                ? Colors.red
                                : const Color(0xff8C8C8C),
                          ),
                        ),
                      ],
                    );
                  }),

                  heightBox10,
                  StraightLiner(height: 0.5),
                  heightBox10,

                  // Price field (required)
                  Row(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                        child: Text(
                          CurrencyHelper.inputPrefix,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Expanded(
                        child: CustomTextField(
                          controller: _priceCtrl,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          hintText: 'Service Price',
                          hintStyle: TextStyle(
                            fontSize: 14.sp,
                            color: const Color(0xff8C8C8C),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Service price is required';
                            }
                            if (double.tryParse(value.trim()) == null) {
                              return 'Enter a valid price';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  heightBox10,
                  StraightLiner(height: 0.5),
                  heightBox10,

                  // Delivery time field — number + Days/Hours toggle
                  Row(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                        child: Icon(
                          Icons.access_time,
                          color: Colors.white,
                          size: 18.sp,
                        ),
                      ),
                      Expanded(
                        child: CustomTextField(
                          controller: _deliveryTimeCtrl,
                          keyboardType: TextInputType.number,
                          hintText: 'Delivery Time',
                          hintStyle: TextStyle(
                            fontSize: 14.sp,
                            color: const Color(0xff8C8C8C),
                          ),
                        ),
                      ),
                      // Days only toggle
                      StatefulBuilder(
                        builder: (context, setInner) {
                          return Container(
                            margin: EdgeInsets.symmetric(horizontal: 6.w, vertical: 6.h),
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
                            decoration: BoxDecoration(
                              color: const Color(0xff2799EA),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              'Days',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        },
                      ),
                      SizedBox(width: 4.w),
                    ],
                  ),
                  heightBox10,
                  StraightLiner(height: 0.5),
                  heightBox10,

                  GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.black,
                        isScrollControlled: true,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20.r),
                          ),
                        ),
                        builder: (_) => _privacyBottomSheet(),
                      );
                    },
                    child: Row(
                      children: [
                        Icon(
                          _selectedPrivacy == 'EVERYONE'
                              ? Icons.public
                              : Icons.lock_outline,
                          color: LightThemeColors.blueColor,
                          size: 24.sp,
                        ),
                        widthBox10,
                        Text(
                          _selectedPrivacy == 'EVERYONE'
                              ? 'Everyone'
                              : 'Only me',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w400,
                            color: LightThemeColors.blueColor,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.keyboard_arrow_down,
                          color: LightThemeColors.blueColor,
                        ),
                      ],
                    ),
                  ),

                  heightBox20,

                  if (_selectedImages.length < maxImages)
                    GestureDetector(
                      onTap: () => _imagePickerHelper.showAlertDialog(
                        context,
                        _addImage,
                      ),
                      child: Row(
                        children: [
                          Image.asset(
                            Assets.images.gallery02.keyName,
                            height: 24.h,
                          ),
                          widthBox10,
                          Text(
                            'Add Gallery',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w400,
                              color: LightThemeColors.blueColor,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                      child: Text(
                        'Maximum $maxImages images selected',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: LightThemeColors.themeGreyColor,
                        ),
                      ),
                    ),

                  heightBox20,

                  if (_selectedImages.isNotEmpty)
                    Wrap(
                      spacing: 10.w,
                      runSpacing: 10.h,
                      children: List.generate(_selectedImages.length, (index) {
                        return Stack(
                          children: [
                            Container(
                              height: 100.h,
                              width: 100.w,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10.r),
                                image: DecorationImage(
                                  image: FileImage(_selectedImages[index]),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 5,
                              right: 5,
                              child: GestureDetector(
                                onTap: () => _removeImage(index),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 20.sp,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),

                  heightBox100,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _privacyBottomSheet() {
    final options = [
      {'title': 'Everyone', 'value': 'EVERYONE', 'icon': Icons.public},
      {'title': 'Followers', 'value': 'FOLLOWERS', 'icon': Icons.lock_outline},
    ];

    return SafeArea(
      child: Container(
        color: Colors.black,
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 5.h,
              decoration: BoxDecoration(
                color: const Color(0xff8C8C8C),
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            heightBox20,
            Text(
              'Who can Comment on this post?',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: LightThemeColors.blueColor,
              ),
            ),
            heightBox20,
            ...options.map((option) {
              return ListTile(
                leading: Icon(
                  option['icon'] as IconData,
                  color: LightThemeColors.blueColor,
                ),
                title: Text(
                  option['title'] as String,
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: LightThemeColors.blueColor,
                  ),
                ),
                trailing: _selectedPrivacy == option['value']
                    ? Icon(Icons.check, color: LightThemeColors.blueColor)
                    : null,
                onTap: () {
                  setState(() {
                    _selectedPrivacy = option['value'] as String;
                  });
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}
