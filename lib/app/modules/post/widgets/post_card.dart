// তোমার PostCard ফাইল

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/config/theme/light_theme_colors.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/core/widgets/common/initials_avatar.dart';
import 'package:wisper/app/modules/profile/views/business/others_business_screen.dart';
import 'package:wisper/app/modules/profile/views/person/others_person_screen.dart';

class PostCard extends StatelessWidget {
  final Widget trailing;
  final String? ownerId;
  final bool? isPerson;  
  final String? ownerName;
  final String? ownerImage; 
  final String? ownerProfession;
  final List<String>? postImage;
  final String? postDescription;
  final String? postTime;
  final String? views;
  final bool? isComment;
  final double? price;
  final String? deliveryTime;
  final VoidCallback onTapComment;

  const PostCard({
    super.key,
    required this.trailing,
    this.ownerName,
    this.ownerImage,
    this.ownerProfession,
    this.postImage,
    this.postDescription,
    this.postTime,
    this.views,
    this.ownerId,
    this.isComment = false,
    this.price,
    this.deliveryTime,
    required this.onTapComment,
    this.isPerson = true,
  });

  String _formatViews(String? views) {
    final count = int.tryParse(views ?? '0') ?? 0;
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M Views';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K Views';
    }
    return '$count Views';
  }

  @override
  Widget build(BuildContext context) {
    print('Post Images: $postImage');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            if (isPerson == true) {
              Get.to(() => OthersPersonScreen(userId: ownerId ?? ''));
            } else {
              Get.to(() => OthersBusinessScreen(userId: ownerId ?? ''));
            }
          },
          child: InitialsAvatar(
            name: ownerName ?? '',
            imageUrl: ownerImage,
            radius: 20.r,
            fontSize: 14,
          ),
        ),
        widthBox8,
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.73,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ownerName ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      if (ownerProfession != null && ownerProfession!.isNotEmpty)
                        Text(
                          ownerProfession!,
                          style: TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: 10,
                            color: LightThemeColors.themeGreyColor,
                          ),
                        ),
                    ],
                  ),
                  trailing,
                ],
              ),
              heightBox10,
              Container(
                width: MediaQuery.of(context).size.width * 0.73,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Caption FIRST (top) — like Twitter/X layout
                    if (postDescription != null && postDescription!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                        child: Text(
                          postDescription!,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),

                    // Price + Delivery time row (below caption, above images)
                    if (price != null || (deliveryTime != null && deliveryTime!.isNotEmpty))
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                        child: Row(
                          children: [
                            if (price != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xff1877F2).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xff1877F2).withOpacity(0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('₦', style: TextStyle(fontSize: 11, color: Color(0xff1877F2), fontWeight: FontWeight.w600)),
                                    const SizedBox(width: 2),
                                    Text(
                                      price! % 1 == 0 ? price!.toInt().toString() : price!.toStringAsFixed(2),
                                      style: const TextStyle(fontSize: 11, color: Color(0xff1877F2), fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            if (deliveryTime != null && deliveryTime!.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.access_time, size: 11, color: LightThemeColors.themeGreyColor),
                                    const SizedBox(width: 3),
                                    Text(
                                      deliveryTime!,
                                      style: TextStyle(fontSize: 11, color: LightThemeColors.themeGreyColor),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),

                    // Images below caption
                    if (postImage != null && postImage!.isNotEmpty)
                      ImageContainer(
                        images: postImage,
                        height: 200,
                        width: double.infinity,
                        borderRadius: 8,
                      )
                    else
                      const SizedBox.shrink(),
                  ],
                ),
              ),
              heightBox8,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Views count with eye icon (like "105K Views")
                  Row(
                    children: [
                      Icon(
                        Icons.remove_red_eye_outlined,
                        size: 12,
                        color: LightThemeColors.themeGreyColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatViews(views),
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: 10,
                          color: LightThemeColors.themeGreyColor,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    postTime ?? '',
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 10,
                      color: LightThemeColors.themeGreyColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}