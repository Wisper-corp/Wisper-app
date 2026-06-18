import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wisper/app/core/config/theme/light_theme_colors.dart';
import 'package:wisper/app/core/others/custom_size.dart';

class CustomElevatedButton extends StatelessWidget {
  final String title;
  final String? iconData;
  final VoidCallback? onPress; 
  final Color? color;
  final Color? textColor;
  final Color? borderColor;
  final double? width;
  final double? height;
  final double? textSize;
  final double? borderRadius;
  const CustomElevatedButton({
    super.key,
    required this.title,
    this.iconData,
    this.onPress,
    this.color = LightThemeColors.blueColor,
    this.textColor = Colors.white,
    this.borderColor = Colors.transparent,
    this.width = double.infinity,
    this.height = 48,
    this.textSize,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPress,
      child: Container(
        width: width!.w,
        height: height?.h,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(borderRadius ?? 10.r),
          border: Border.all(color: borderColor!, width: 0.8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            iconData != null
                ? Image.asset(iconData!, height: 20.h, width: 20.w)
                : Container(),
            iconData != null ? widthBox10 : Container(),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: textSize ?? 16.sp,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
