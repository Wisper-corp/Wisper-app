import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wisper/app/core/others/custom_size.dart' show widthBox4, heightBox10, heightBox8;

class FeatureList extends StatelessWidget {
  final String? title;
  final String? iconPath;
  const FeatureList({super.key, this.title, this.iconPath});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(iconPath!, height: 16.h, width: 16),
            widthBox4,
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.75,
              child: Text(
                
                title!,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w400,
                  color: Color(0xff8C8C8C),
                ),
              ),
            ),
            heightBox10,
          ],
        ),
        heightBox8,
      ],
      
    );
  }
}