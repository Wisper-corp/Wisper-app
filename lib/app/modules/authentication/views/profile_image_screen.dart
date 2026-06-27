import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/core/widgets/common/circle_icon.dart';
import 'package:wisper/app/modules/dashboard/views/dashboard_screen.dart';
import 'package:wisper/gen/assets.gen.dart';

class ProfileImageScreen extends StatefulWidget {
  const ProfileImageScreen({super.key}); 

  @override
  State<ProfileImageScreen> createState() => _ProfileImageScreenState();
}

class _ProfileImageScreenState extends State<ProfileImageScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        height: double.infinity,
        width: double.infinity,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0.w, vertical: 0.0.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              heightBox60,
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () {
                    Get.offAll(() => const MainButtonNavbarScreen());
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Skip',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFD1D1D1),
                        ),
                      ),
                      widthBox8,
                      Image.asset(
                        color: Colors.white,
                        Assets.images.arrowForwoard.keyName,
                        height: 16.h,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 100.h),

              CircleIconWidget(
                radius: 48,
                iconRadius: 32,
                imagePath: Assets.images.galleryPlus.keyName,
                onTap: () {},
              ),
              heightBox10,
              Text(
                'Add Profile Picture',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800),
              ),

              heightBox8,
              SizedBox(
                width: 250.w,
                child: Text(
                  'A professional headshot doubles your chances of getting hired!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFFD1D1D1),
                  ),
                ),
              ),
         
            ],
          ),
        ),
      ),
    );
  }
}
