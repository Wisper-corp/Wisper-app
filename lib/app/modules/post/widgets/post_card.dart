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
  final List<String>? postImage;        // লিস্ট
  final String? postDescription;
  final String? postTime;
  final String? views;
  final bool? isComment;
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
                  border: Border.all(color: Colors.grey.shade400, width: 0.4),
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