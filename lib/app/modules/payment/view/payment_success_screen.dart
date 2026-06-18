import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/core/widgets/common/custom_button.dart';
import 'package:wisper/app/modules/dashboard/views/dashboard_screen.dart';
import 'package:wisper/gen/assets.gen.dart';

class PaymentSuccessScreen extends StatefulWidget {
  const PaymentSuccessScreen({super.key});

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen> {
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
                'Payment Successful',
                style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.w800),
              ),

              heightBox8,
              Text(
                'Your payment has been successfully processed. Now, let’s set a profile picture for your account.',
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
                title: 'Go to Homepage',
                onPress: () {
                  Get.to(const MainButtonNavbarScreen());
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
