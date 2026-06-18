import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/core/widgets/common/custom_button.dart';
import 'package:wisper/app/modules/authentication/views/profile_image_screen.dart';
import 'package:wisper/gen/assets.gen.dart';

class VerifySuccessScreen extends StatefulWidget {
  const VerifySuccessScreen({super.key});

  @override
  State<VerifySuccessScreen> createState() => _VerifySuccessScreenState();
}

class _VerifySuccessScreenState extends State<VerifySuccessScreen> {
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
              SizedBox(height: 200.h),

              Image.asset(
                Assets.images.shield.keyName,
                height: 167.h,
                width: 142.h,
              ),
              heightBox10,
              Text(
                'Verification Successful',
                style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.w800),
              ),

              heightBox8,
              Text(
                'Your email has been successfully verified. Now, let’s set a new password for your account.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFFD1D1D1),
                ),
              ),

              Expanded(child: heightBox10),
              CustomElevatedButton(
                width: 250,
                height: 56,
                title: 'Set Your Account',
                onPress: () {
                  Get.to(const ProfileImageScreen());
                },
              ),
              heightBox20,
            ],
          ),
        ),
      ),
    );
  }
}
