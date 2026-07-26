// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/core/utils/initials.dart';
import 'package:wisper/app/core/utils/show_over_loading.dart';
import 'package:wisper/app/core/utils/snack_bar.dart';
import 'package:wisper/app/core/widgets/common/custom_button.dart';
import 'package:wisper/app/core/widgets/common/custom_text_filed.dart';
import 'package:wisper/app/modules/profile/controller/buisness/buisness_controller.dart';
import 'package:wisper/app/modules/profile/controller/create_recommandation.dart';
import 'package:wisper/app/modules/profile/controller/person/profile_controller.dart';
import 'package:wisper/app/modules/profile/controller/recommendetion_controller.dart';

class CreateReviewSheet extends StatefulWidget {
  final String recieverId;
  const CreateReviewSheet({super.key, required this.recieverId});

  @override
  State<CreateReviewSheet> createState() => _CreateReviewSheetState();
}

class _CreateReviewSheetState extends State<CreateReviewSheet> {
  final TextEditingController _reviewController = TextEditingController();
  final CreateRecommendationController createRecommendationController =
      CreateRecommendationController();

  final ProfileController profileController = Get.find<ProfileController>();
  final BusinessController businessController = Get.find<BusinessController>();

  // Rating
  int _rating = 0;

  // User info observables (giver)
  final RxBool isLoading = true.obs;
  final RxString userName = ''.obs;
  final RxString userImageUrl = ''.obs;

  late final bool isPerson;

  @override
  void initState() {
    super.initState();
    isPerson = StorageUtil.getData(StorageUtil.userRole) == 'PERSON';

    // Fetch giver's profile based on role
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

  void _updateUserInfo() {
    if (isPerson) {
      final person = profileController.profileData?.auth?.person;
      userName.value = person?.name ?? 'Anonymous';
      userImageUrl.value = person?.image ?? '';
      isLoading.value = profileController.inProgress;
    } else {
      final business = businessController.buisnessData?.auth?.business;
      userName.value = business?.name ?? 'Anonymous';
      userImageUrl.value = business?.image ?? '';
      isLoading.value = businessController.inProgress;
    }
  }

  void addRecommendation() {
    if (_rating == 0) {
      showSnackBarMessage(context, "Please give a rating", true);
      return;
    }

    if (_reviewController.text.trim().isEmpty) {
      showSnackBarMessage(context, "Please write a review", true);
      return;
    }

    showLoadingOverLay(
      asyncFunction: () async => await performRecommendation(),
      msg: 'Posting review...',
    );
  }

  Future<void> performRecommendation() async {
    final bool isSuccess = await createRecommendationController
        .addRecommendation(
          text: _reviewController.text.trim(),
          rating: _rating,
          recieverId: widget.recieverId,
        );

    if (isSuccess && mounted) {
      final controller = Get.find<AllRecommendationController>();
      await controller.getAllRecommendations(widget.recieverId);
      controller.update(); // GetBuilder rebuild করবে
      controller.refreshRecommendations();

      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) Navigator.pop(context);
      // showSnackBarMessage(context, "Review posted successfully!", false);
    } else if (mounted) {
      showSnackBarMessage(
        context,
        createRecommendationController.errorMessage,
        true,
      );
    }
  }

  Widget _buildStarRating() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        return GestureDetector(
          onTap: () {
            setState(() {
              _rating = starIndex;
            });
          },
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Icon(
              starIndex <= _rating ? Icons.star : Icons.star_border,
              color: Colors.amber,
              size: 24.sp,
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20.w,
        right: 20.w,
        top: 20.h,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xff0D0D0D),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                heightBox10,

                // Header: Cancel + Post
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 36.h,
                      width: 80.w,
                      child: CustomElevatedButton(
                        title: 'Post',
                        textSize: 14,
                        borderRadius: 50,
                        onPress: addRecommendation,
                      ),
                    ),
                  ],
                ),

                heightBox20,

                // Giver Info + Rating
                Obx(() {
                  if (isLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20.r,
                            backgroundColor: Colors.grey,
                            backgroundImage: userImageUrl.value.isNotEmpty
                                ? NetworkImage(userImageUrl.value)
                                : null,
                            child: userImageUrl.value.isEmpty
                                ? Text(
                                    initialsFromName(userName.value),
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                                : null,
                          ),
                          widthBox12,
                          SizedBox(
                            width: 100.w,
                            child: Text(
                              userName.value,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      _buildStarRating(),
                    ],
                  );
                }),

                heightBox20,

                // Review Text Field
                SizedBox(
                  height: 120.h,
                  child: CustomTextField(
                    controller: _reviewController,
                    maxLines: 6,
                    hintText: 'Write your review here...',
                    hintStyle: TextStyle(
                      fontSize: 14.sp,
                      color: const Color(0xff8C8C8C),
                    ),
                    contentPadding: EdgeInsets.all(12.w),
                  ),
                ),

                heightBox100, // Keyboard safety
              ],
            ),
          ),
        ),
      ),
    );
  }
}
