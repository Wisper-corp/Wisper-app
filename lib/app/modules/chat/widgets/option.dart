
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wisper/app/core/config/theme/light_theme_colors.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/core/widgets/common/circle_icon.dart';

class Option extends StatelessWidget {
  final VoidCallback onTap;
  final String imagePath;
  final String title;
  final Color? iconColor;
  final bool useReceiptIcon;

  const Option({
    super.key,
    required this.onTap,
    required this.imagePath,
    required this.title,
    this.iconColor,
    this.useReceiptIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (useReceiptIcon)
          GestureDetector(
            onTap: onTap,
            child: CircleAvatar(
              backgroundColor: LightThemeColors.circleIconColor,
              radius: 20,
              child: Icon(
                Icons.receipt_long_rounded,
                color: iconColor ?? const Color(0xffFFD700),
                size: 22,
              ),
            ),
          )
        else
          CircleIconWidget(
            imagePath: imagePath,
            onTap: onTap,
            iconColor: iconColor,
            iconRadius: 22,
            radius: 20,
          ),
        heightBox4,
        Text(title, style: TextStyle(fontSize: 12.sp)),
      ],
    );
  }
}
