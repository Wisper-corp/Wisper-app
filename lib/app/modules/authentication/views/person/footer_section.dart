import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/core/utils/show_over_loading.dart';
import 'package:wisper/app/core/utils/snack_bar.dart';
import 'package:wisper/app/modules/authentication/controller/google_sign_up_controller.dart';
import 'package:wisper/gen/assets.gen.dart';

class FooterSection extends StatefulWidget {
  const FooterSection({super.key});

  @override
  State<FooterSection> createState() => _FooterSectionState();
}

class _FooterSectionState extends State<FooterSection> {
  final GoogleSignUpAuthController googleAuthController = Get.put(
    GoogleSignUpAuthController(),
  );

  void signInGoogle() {
    showLoadingOverLay(
      asyncFunction: () async => await performGoogleSignIn(context),
      msg: 'Please wait...',
    );
  }

  Future<void> performGoogleSignIn(BuildContext context) async {
    final bool isSuccess = await googleAuthController.signUpWithGoogle(
      'PERSON',
    );

    if (isSuccess) {
    } else {
      showSnackBarMessage(context, 'Failed to sign in', true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Sign Up With",
              style: TextStyle(color: const Color(0xff8C8C8C), fontSize: 16.sp),
            ),
            heightBox10,
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: signInGoogle,
                  child: Image.asset(
                    Assets.images.gmail.keyName,
                    height: 30.h,
                  ),
                ),
                // widthBox14,
                // Image.asset(Assets.images.facebook.keyName, height: 30.h),
              ],
            ),
          ],
        ),
        heightBox16,
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: [
              TextSpan(
                text: 'By signing up, I agree to the Wispa  ',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Color(0xffAEAEAE),
                  fontWeight: FontWeight.w400,
                ),
              ),
              TextSpan(
                text: 'Terms and Conditions',
                style: TextStyle(
                  decoration: TextDecoration.underline,
                  fontSize: 14.sp,
                  color: Color(0xffAEAEAE),
                  fontWeight: FontWeight.w400,
                ),
              ),
              TextSpan(
                text: ' and ',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Color(0xffAEAEAE),
                  fontWeight: FontWeight.w400,
                ),
              ),
              TextSpan(
                text: 'Privacy Policy',
                style: TextStyle(
                  decoration: TextDecoration.underline,
                  fontSize: 14.sp,
                  color: Color(0xffAEAEAE),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
