import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/config/theme/light_theme_colors.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/core/utils/show_over_loading.dart';
import 'package:wisper/app/core/widgets/common/custom_button.dart';
import 'package:wisper/app/modules/post/controller/feed_post_controller.dart';
import 'package:wisper/app/modules/post/controller/my_post_controller.dart';
import 'package:wisper/app/modules/post/controller/others_post_controller.dart';
import 'package:wisper/app/modules/post/model/feed_post_model.dart';
import 'package:wisper/app/modules/post/widgets/post_card.dart';
import 'package:wisper/app/modules/payment/controller/payment_services.dart';
import 'package:wisper/app/modules/profile/controller/get_package_controller.dart';

class BoostScreen extends StatefulWidget {
  final FeedPostItemModel feedPostItemModel;
  const BoostScreen({super.key, required this.feedPostItemModel});

  @override
  State<BoostScreen> createState() => _BoostScreenState();
}

class _BoostScreenState extends State<BoostScreen> {
  final AllPackageController allPackageController = Get.put(
    AllPackageController(),
  );

  final PaymentService paymentService = PaymentService();
  final AllFeedPostController? allFeedPostController =
      Get.isRegistered<AllFeedPostController>()
          ? Get.find<AllFeedPostController>()
          : null;
  final MyFeedPostController? myFeedPostController =
      Get.isRegistered<MyFeedPostController>()
          ? Get.find<MyFeedPostController>()
          : null;
  final OthersFeedPostController? othersFeedPostController =
      Get.isRegistered<OthersFeedPostController>()
          ? Get.find<OthersFeedPostController>()
          : null;

  var packageId;
  bool isSelected = false;

  @override
  void initState() {
    allPackageController.getAllPackage();
    super.initState();
  }

  void addPayment(String packageId, String postId, String targetIndustry) {
    showLoadingOverLay(
      asyncFunction: () async =>
          await _payNow(packageId, postId, targetIndustry),
      msg: 'Please wait...',
    );
  }

  Future<void> _payNow(
    String packageId,
    String postId,
    String targetIndustry,
  ) async {
    await paymentService.payment(context, packageId, postId, targetIndustry);
  }

  int _resolveCommentCount() {
    final postId = widget.feedPostItemModel.id ?? '';
    if (postId.isNotEmpty) {
      if (allFeedPostController != null) {
        for (final p in allFeedPostController!.allPostData) {
          if (p.id == postId) return p.count?.comment ?? 0;
        }
      }
      if (myFeedPostController != null) {
        for (final p in myFeedPostController!.allPostData) {
          if (p.id == postId) return p.count?.comment ?? 0;
        }
      }
      if (othersFeedPostController != null) {
        for (final p in othersFeedPostController!.allPostData) {
          if (p.id == postId) return p.count?.comment ?? 0;
        }
      }
    }
    return widget.feedPostItemModel.count?.comment ?? 0;
  }

  Widget _buildPostCard() {
    return PostCard(
      isPerson: widget.feedPostItemModel.author?.person != null,
      isComment: true,
      onTapComment: () {},
      trailing: Container(),
      commentCount: _resolveCommentCount(),
      ownerName: widget.feedPostItemModel.author?.person?.name,
      ownerImage: widget.feedPostItemModel.author?.person?.image,
      ownerProfession: widget.feedPostItemModel.author?.person?.title,
      postDescription: widget.feedPostItemModel.caption,
      postTime: widget.feedPostItemModel.createdAt.toString(),
      views: widget.feedPostItemModel.views.toString(),
      postImage: widget.feedPostItemModel.images.isNotEmpty
          ? widget.feedPostItemModel.images
          : [],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
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
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
                  ),
                ),
                Text(
                  'Advertisement',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                SizedBox(
                  height: 32,
                  width: 70,
                  child: CustomElevatedButton(
                    title: 'Pay Now',
                    textSize: 12,
                    borderRadius: 50,
                    onPress: () {
                      addPayment(
                        packageId.toString(),
                        widget.feedPostItemModel.id.toString(),
                        'edtech',
                      );
                    },
                  ),
                ),
              ],
            ),
            heightBox12,
            if (allFeedPostController != null)
              GetBuilder<AllFeedPostController>(
                builder: (_) => _buildPostCard(),
              )
            else if (myFeedPostController != null)
              GetBuilder<MyFeedPostController>(
                builder: (_) => _buildPostCard(),
              )
            else if (othersFeedPostController != null)
              GetBuilder<OthersFeedPostController>(
                builder: (_) => _buildPostCard(),
              )
            else
              _buildPostCard(),
            heightBox20,
            Text(
              'Select a package',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            heightBox8,
            Expanded(
              child: Obx(() {
                if (allPackageController.inProgress) {
                  return Center(child: CircularProgressIndicator());
                } else if (allPackageController.allPackageData!.isEmpty) {
                  return Center(child: Text('No package found'));
                } else {
                  return ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.all(0),
                    itemCount: allPackageController.allPackageData!.length,

                    itemBuilder: (context, index) {
                      var data = allPackageController.allPackageData![index];
                      var price = data.price;
                      var duration = data.duration;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            isSelected = !isSelected;
                            packageId = data.id;
                            print('Package id: $packageId');
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? LightThemeColors.blueColor
                                : Color(0xff212121),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    // Text(
                                    //   '$name',
                                    //   style: TextStyle(
                                    //     fontWeight: FontWeight.w600,
                                    //     fontSize: 14.sp,
                                    //     color: LightThemeColors.blueColor,
                                    //   ),
                                    // ),
                                    Text(
                                      ' $duration Days \$$price USD',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14.sp,
                                        color: LightThemeColors.whiteColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }
              }),
            ),
          ],
        ),
      ),
    );
  }
}
