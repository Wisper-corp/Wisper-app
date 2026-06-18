// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:wisper/app/core/config/theme/light_theme_colors.dart';

import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/core/utils/show_over_loading.dart';
import 'package:wisper/app/core/utils/snack_bar.dart';
import 'package:wisper/app/core/widgets/common/custom_button.dart';
import 'package:wisper/app/modules/authentication/controller/google_sign_up_controller.dart';

import 'package:wisper/app/modules/authentication/views/auth_screen.dart';
import 'package:wisper/app/modules/authentication/views/sign_in_screen.dart';
import 'package:wisper/app/modules/onboarding/views/page_view.dart';
import 'package:wisper/gen/assets.gen.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final PageController _pageController = PageController();
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

  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LightThemeColors.blackColor,
      body: Padding(
        padding: EdgeInsets.all(20.0.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            heightBox40,
            Text(
              "Wisper",
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.w700,
                color: LightThemeColors.blueColor,
              ),
            ),
            Text(
              "Welcome",
              style: TextStyle(
                fontSize: 32.sp,
                fontWeight: FontWeight.bold,
                color: LightThemeColors.whiteColor,
              ),
            ),
            heightBox50,
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  OnboardingPageView(
                    showBackButton: false,
                    imageWidth: 163,
                    imageHeight: 236,
                    onBoardingRow: false,
                    title: "Manage Your Hiring Process, Effortlessly",
                    subtitle:
                        "Post jobs, review candidates, and schedule interviews all in one place.",
                    pageController: _pageController,
                    imagePath: Assets.images.svg02.keyName,
                  ),
                  OnboardingPageView(
                    showBackButton: false,
                    imageWidth: 180,
                    imageHeight: 240,
                    onBoardingRow: false,
                    title: "Unlock Top Talent with Ease",
                    subtitle:
                        "Hire smarter, faster, and with confidence using Find Top Talent.",
                    pageController: _pageController,
                    imagePath: Assets.images.svg01.keyName,
                  ),
                  OnboardingPageView(
                    showBackButton: false,
                    imageWidth: 312,
                    imageHeight: 179,
                    onBoardingRow: false,
                    title: "Find Top Jobs, Fuel Your Success!",
                    subtitle:
                        "Connecting you with the best jobs in every field, ready to bring your dream to life.",
                    pageController: _pageController,
                    imagePath: Assets.images.world.keyName,
                  ),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SmoothPageIndicator(
                  controller: _pageController,
                  count: 3,
                  effect: WormEffect(
                    dotHeight: 6.0.h,
                    dotWidth: 34.0.w,
                    spacing: 10.0,
                    dotColor: LightThemeColors.darkGreyColor,
                    activeDotColor: LightThemeColors.blueColor,
                  ),
                ),
                heightBox40, // Reduced from heightBox50 to minimize gap
                Text(
                  "Sign Up With",
                  style: TextStyle(
                    color: const Color(0xff8C8C8C),
                    fontSize: 16.sp,
                  ),
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
            heightBox30,
            Padding(
              padding: EdgeInsets.all(15.0.h),
              child: Row(
                children: [
                  Expanded(
                    child: CustomElevatedButton(
                      title: 'Login',
                      onPress: () {
                        Get.to(() => SignInScreen());
                      },
                      color: Colors.transparent,
                      textColor: Colors.white,
                      borderColor: Colors.white,
                    ),
                  ),
                  widthBox15,
                  Expanded(
                    child: CustomElevatedButton(
                      title: 'Sign Up',
                      onPress: () {
                        Get.to(() => AuthScreen());
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
