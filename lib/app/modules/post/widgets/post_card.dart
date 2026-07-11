import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/config/theme/light_theme_colors.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/core/widgets/common/image_container_widget.dart';
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
  final Widget? ratingWidget;

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
    this.ratingWidget,
    this.isPerson = true,
  });

  String _formatViews(String? views) {
    final count = int.tryParse(views ?? '0') ?? 0;
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '$count';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Left: Avatar ─────────────────────────────────
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

          SizedBox(width: 10.w),

          // ── Right: Content ───────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row: name + trailing (more icon)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name + rating inline
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  ownerName ?? '',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14.sp,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              if (ratingWidget != null) ...[
                                SizedBox(width: 6.w),
                                ratingWidget!,
                              ],
                            ],
                          ),
                          // Profession under name
                          if (ownerProfession != null && ownerProfession!.isNotEmpty)
                            Text(
                              ownerProfession!,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.grey,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Trailing (more icon only, no sponsor)
                    if (trailing is! Text)
                      trailing,
                  ],
                ),

                // Caption text
                if (postDescription != null && postDescription!.isNotEmpty) ...[
                  SizedBox(height: 6.h),
                  Text(
                    postDescription!,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.white,
                      height: 1.4,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],

                // Price + Delivery badges with icons (no box borders)
                if (price != null || (deliveryTime != null && deliveryTime!.isNotEmpty)) ...[
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      if (price != null) ...[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                              decoration: BoxDecoration(
                                color: const Color(0xff1E1E1E),
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.payments_outlined, size: 14.sp, color: Colors.white70),
                                  SizedBox(width: 4.w),
                                  Text(
                                    'from ₦${price! % 1 == 0 ? price!.toInt().toString() : price!.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 8.w),
                          ],
                        ),
                      ],
                      if (deliveryTime != null && deliveryTime!.isNotEmpty)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                          decoration: BoxDecoration(
                            color: const Color(0xff1E1E1E),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.schedule_outlined, size: 14.sp, color: Colors.white70),
                              SizedBox(width: 4.w),
                              Text(
                                deliveryTime!,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],

                // Images — full width, Twitter style
                if (postImage != null && postImage!.isNotEmpty) ...[
                  SizedBox(height: 10.h),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14.r),
                    child: ImageContainer(
                      images: postImage,
                      height: 200,
                      width: double.infinity,
                      borderRadius: 14,
                    ),
                  ),
                ],

                // Action row: comment · views · bookmark + timestamp
                SizedBox(height: 10.h),
                Row(
                  children: [
                    // Comment
                    _ActionButton(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: '',
                      onTap: onTapComment,
                    ),
                    SizedBox(width: 20.w),
                    // Views
                    _ActionButton(
                      icon: Icons.bar_chart_rounded,
                      label: _formatViews(views),
                      onTap: () {},
                    ),
                    const Spacer(),
                    // Timestamp on the right
                    if (postTime != null && postTime!.isNotEmpty)
                      Text(
                        postTime!,
                        style: TextStyle(fontSize: 11.sp, color: Colors.grey),
                      ),
                    SizedBox(width: 10.w),
                    // Bookmark
                    Icon(Icons.bookmark_border_rounded, size: 16.sp, color: Colors.grey),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 16.sp, color: Colors.grey),
          if (label.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12.sp, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }
}
