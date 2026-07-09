import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Displays: ★ 4.8  (35)  — matches Victor's screenshot style
class StarRating extends StatelessWidget {
  final double rating;
  final int count;
  final double fontSize;

  const StarRating({
    super.key,
    required this.rating,
    required this.count,
    this.fontSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star, color: Colors.white, size: (fontSize + 2).sp),
        SizedBox(width: 4.w),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(width: 4.w),
        Text(
          '($count)',
          style: TextStyle(
            color: const Color(0xFF9E9E9E),
            fontSize: fontSize.sp,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
