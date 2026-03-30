import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wisper/app/core/config/theme/light_theme_colors.dart';
import 'package:wisper/app/core/others/custom_size.dart';

class ContactWidget extends StatelessWidget {
  final String imagePath;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;
  const ContactWidget({
    super.key,
    required this.imagePath,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: imagePath.isNotEmpty
                    ? NetworkImage(imagePath)
                    : null,
                backgroundColor: Colors.grey,
                child: imagePath.isEmpty
                    ? Text(
                        title.isNotEmpty
                            ? title[0]
                            : '?',
                        style: TextStyle(
                          fontSize: 16.sp,
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
                    title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w400,
                      color: LightThemeColors.themeGreyColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing == null ? const SizedBox() : trailing!,
        ],
      ),
    );
  }
}
