import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/core/widgets/common/details_card.dart';

class SeetingsButton extends StatelessWidget {
  final VoidCallback? onTap;
  final String title;
  final Color bgColor;
  final Color borderColor;
  final String iconPath;
  const SeetingsButton({
    super.key,
    required this.title,
    required this.bgColor,
    required this.borderColor,
    required this.iconPath,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 31,
      child: GestureDetector(
        onTap: onTap,
        child: DetailsCard(
          borderRadius: 8,
          borderColor: borderColor,
          bgColor: bgColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                iconPath,
                height: 18.h,
                width: 18.w,
                color: Color(0xffE62047),
              ),
              widthBox8,
              Text(
                title,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: Color(0xffE62047),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
