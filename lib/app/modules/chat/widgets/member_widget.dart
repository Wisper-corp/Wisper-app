
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/gen/assets.gen.dart';

class MemberWidget extends StatelessWidget {
  final String imagePath;
  final String name;
  final VoidCallback onTap;
  const MemberWidget({
    super.key,
    required this.imagePath,
    required this.name,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xff1B1E25),
        borderRadius: BorderRadius.circular(30.r),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(radius: 8.5.r, backgroundImage: AssetImage(imagePath)),
            widthBox4,
            Text(
              name,
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w400),
            ),
            widthBox10,
            GestureDetector(
              onTap: onTap,
              child: Image.asset(Assets.images.cross.keyName, height: 14),
            ),
          ],
        ),
      ),
    );
  }
}
