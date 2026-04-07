// lib/app/modules/profile/views/rcommendation_bottom_sheet.dart (নাম ঠিক করো)

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/core/utils/connectivity_services.dart';
import 'package:wisper/app/modules/profile/controller/recommendetion_controller.dart';
import 'package:wisper/app/modules/profile/model/recommendation_model.dart';
import 'package:wisper/app/modules/profile/views/create_recommendation.dart';
import 'package:wisper/app/modules/profile/widget/reviewCard.dart';

class RcommendationButtomSheet extends StatelessWidget {
  final String? recieverId;
  final bool isCreateReview; 

  const RcommendationButtomSheet({
    super.key,
    this.recieverId,
    this.isCreateReview = true,
  });

  @override
  Widget build(BuildContext context) {
    final AllRecommendationController controller =
        Get.put(AllRecommendationController());
    final ConnectivityService connectivityService =
        Get.find<ConnectivityService>();

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: Container(
        color: const Color(0xff0D0D0D),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'Recommendation',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              heightBox10,

              // Live data from controller
              Expanded(
                child: Obx(() {
                  final List<RecommendationItemModel> items =
                      controller.recommendationData;

                  if (controller.inProgress) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (items.isEmpty) {
                    if (!connectivityService.isOnline.value) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    return const Center(
                      child: Text(
                        'No recommendations yet',
                        style: TextStyle(color: Colors.white70),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final giverPerson = item.giver?.person;
                      final giverBusiness = item.giver?.business;

                      return ReviewCard(
                        image: giverPerson?.image ?? giverBusiness?.image ?? '',
                        name: giverPerson?.name ??
                            giverBusiness?.name ??
                            'Anonymous',
                        review: item.text ?? '',
                        rating: item.rating.toString(),
                      );
                    },
                  );
                }),
              ),

              heightBox10,

              // Add Recommendation button
              if (isCreateReview &&
                  StorageUtil.getData(StorageUtil.userRole) == 'PERSON')
                Center(
                  child: GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => CreateReviewSheet(
                          recieverId: recieverId ?? '',
                        ),
                      );
                    },
                    child: Container(
                      width: 210.w,
                      height: 30.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50.r),
                        color: const Color(0xff3DBCF7).withOpacity(0.20),
                      ),
                      child: Center(
                        child: Text(
                          '+ Add Recommendation',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xff2799EA),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
