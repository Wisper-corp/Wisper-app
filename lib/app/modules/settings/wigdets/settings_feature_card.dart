
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/core/widgets/common/details_card.dart';

class SeetingsFeatureCard extends StatelessWidget {
  final String iconPath;
  final String title;
  final Widget widget;
  const SeetingsFeatureCard({ 
    super.key,
    required this.iconPath,
    required this.title,
    required this.widget,
  });

  @override
  Widget build(BuildContext context) {
    return DetailsCard(
      borderWidth: 0.5,
      width: double.infinity,
      borderColor: Colors.white.withValues(alpha: 0.20),
      bgColor: Color(0xff121212),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            Row(
              children: [
                Image.asset(
                  iconPath,
                  height: 18.h,
                  width: 18.w,
                  color: Colors.white,
                ),
                widthBox4,
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
           
            widget,
          ],
        ),
      ),
    );
  }
}
