import 'package:crash_safe_image/crash_safe_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wisper/app/core/config/theme/light_theme_colors.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/core/utils/initials.dart';
import 'package:wisper/gen/assets.gen.dart';

class CallListTile extends StatelessWidget {
  final String imagePath;
  final String name;
  final String time;
  final String callType;
  final Color callTypeColor;
  const CallListTile({
    super.key,
    required this.imagePath,
    required this.name,
    required this.time,
    required this.callType,
    required this.callTypeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10.r)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 21.r,
                backgroundColor: Colors.grey,
                backgroundImage:
                    imagePath.isNotEmpty ? NetworkImage(imagePath) : null,
                child: imagePath.isEmpty || imagePath == ""
                    ? Text(
                        initialsFromName(name),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : null,
              ),
              widthBox10,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    children: [
                      CrashSafeImage(Assets.images.call.keyName, height: 12.h),
                      widthBox4,
                      Text(
                        callType,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w400,
                          color: callTypeColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              Text(
                time,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w400,
                  color: LightThemeColors.themeGreyColor,
                ),
              ),
              widthBox12,
              Icon(
                Icons.info_outline,
                size: 16,
                color: LightThemeColors.themeGreyColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
