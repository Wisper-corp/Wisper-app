import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wisper/app/core/config/theme/light_theme_colors.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/gen/assets.gen.dart';

class ReviewCard extends StatelessWidget {
  final String image;
  final String name;
  final String review;
  final String rating;

  const ReviewCard({
    super.key,
    required this.image,
    required this.name,
    required this.review,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    final updateRating = double.parse(rating);
    return SizedBox(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Container(
          decoration: BoxDecoration(
            color: Color(0xff121212),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 21.r,
                  backgroundImage: NetworkImage(image),
                ),
                widthBox10,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    Row(
                      children: [
                        for (int i = 0; i < updateRating; i++) ...{
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Image.asset(
                              Assets.images.star.keyName,
                              height: 12,
                            ),
                          ),
                        },
                      ],
                    ),
                    SizedBox(
                      width: 250.w,
                      child: Text(
                        review,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    // heightBox8,
                    // Text(
                    //   date,
                    //   style: TextStyle(
                    //     fontSize: 10.sp,
                    //     fontWeight: FontWeight.w600,
                    //     color: LightThemeColors.themeGreyColor,
                    //   ),
                    // ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
