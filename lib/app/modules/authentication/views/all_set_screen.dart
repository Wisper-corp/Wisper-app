import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/config/theme/light_theme_colors.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/modules/homepage/views/main_button_navbar_screen.dart';
import 'package:wisper/gen/assets.gen.dart';

class AllSetScreen extends StatefulWidget {
  const AllSetScreen({super.key});

  @override
  State<AllSetScreen> createState() => _AllSetScreenState();
}

class _AllSetScreenState extends State<AllSetScreen> {
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
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => Get.offAll(() => MainButtonNavbarScreen()),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                        color: LightThemeColors.blueColor,
                      ),
                    ),
                    widthBox4,
                    Image.asset(
                      Assets.images.arrowForwoard.keyName,
                      height: 16.h,
                      width: 16.w,
                      color: LightThemeColors.blueColor,
                    ),
                  ],
                ),
              ), 
              heightBox80,
              Image.asset(
                Assets.images.vector01.keyName,
                height: 283,
                width: 211,
              ),

              Text(
                'You’re All Set',
                style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.w800),
              ),

              heightBox8,
              SizedBox(
                width: 300.w,
                child: Text(
                  'You’ve successfully set-up your account to explore your job search ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFFD1D1D1),
                  ),
                ),
              ),
              heightBox200,
              heightBox20,
            ],
          ),
        ),
      ),
    );
  }
}
