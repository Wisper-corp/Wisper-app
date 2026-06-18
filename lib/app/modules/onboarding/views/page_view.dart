import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wisper/app/core/others/custom_size.dart';

class OnboardingPageView extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imagePath;
  final bool onBoardingRow;
  final bool showBackButton;
  final double imageHeight;
  final double imageWidth;
  final PageController pageController;

  const OnboardingPageView({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onBoardingRow,
    required this.imageHeight,
    required this.showBackButton,
    required this.pageController,
    required this.imagePath,
    required this.imageWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.r),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              imagePath,
              height: imageHeight.h,
              width: imageWidth.w,
            ),
            heightBox24,
            Text(
              title,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            heightBox8,
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w400,
                color: const Color(0xffAEAEAE),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}