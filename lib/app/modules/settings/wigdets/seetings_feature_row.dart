
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/gen/assets.gen.dart';

class SettingsFeatureRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  const SettingsFeatureRow({
    super.key,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                  ),
                ),
                if (subtitle != null) ...[
                  heightBox4,
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xff999999),
                    ),
                  ),
                ],
              ],
            ),
          ),
          widthBox10,
          Image.asset(
            Assets.images.arrowForwoard.keyName,
            height: 12.h,
            width: 12.w,
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}
