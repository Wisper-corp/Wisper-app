// তোমার PostCard ফাইল

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/config/theme/light_theme_colors.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/core/widgets/common/image_container_widget.dart'; // নতুনটা
import 'package:wisper/app/modules/profile/views/business/others_business_screen.dart';
import 'package:wisper/app/modules/profile/views/person/others_person_screen.dart';

class PostCard extends StatelessWidget {
  final Widget trailing;
  final String? ownerId;
  final bool? isPerson;
  final String? ownerName;
  final String? ownerImage;
  final String? ownerProfession;
  final List<String>? postImage; // লিস্ট
  final String? postDescription;
  final String? postTime;
  final String? views;
  final bool? isComment;
  final int? commentCount;
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
    required this.onTapComment,
    this.isPerson = true,
    this.commentCount,
  });

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
          child: CircleAvatar(
            backgroundColor: Colors.grey.shade800,
            radius: 20.r,
            backgroundImage: ownerImage != null && ownerImage!.isNotEmpty
                ? NetworkImage(ownerImage!)
                : null,
            child: ownerImage == null || ownerImage!.isEmpty
                ? Icon(Icons.person, color: Colors.white, size: 20.r)
                : null,
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
                      if (ownerProfession != null &&
                          ownerProfession!.isNotEmpty)
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
                  border: Border.all(color: Colors.grey.shade400, width: 0.4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // নতুন ImageContainer — লিস্ট পাস করছি
                    if (postImage != null && postImage!.isNotEmpty)
                      ImageContainer(
                        images: postImage,
                        height: 200, // তোমার পছন্দমতো, 168 থেকে 200 ভালো দেখায়
                        width: double.infinity,
                        borderRadius: 8,
                      )
                    else
                      const SizedBox.shrink(),

                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        postDescription ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              heightBox8,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: onTapComment,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Icon(
                          Icons.comment,
                          size: 14,
                          color: LightThemeColors.themeGreyColor,
                        ),
                        widthBox4,
                        Text(
                          ' ${commentCount ?? 0} Comments',
                          style: TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: 10,
                            color: LightThemeColors.themeGreyColor,
                          ),
                        ),
                      ],
                    ),
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
