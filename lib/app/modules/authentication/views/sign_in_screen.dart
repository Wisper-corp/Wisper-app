import 'package:crash_safe_image/crash_safe_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/config/theme/light_theme_colors.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/core/utils/show_over_loading.dart';
import 'package:wisper/app/core/utils/snack_bar.dart';
import 'package:wisper/app/core/utils/validator_service.dart';
import 'package:wisper/app/core/widgets/common/custom_button.dart';
import 'package:wisper/app/core/widgets/common/custom_text_filed.dart';
import 'package:wisper/app/core/widgets/common/label.dart';
import 'package:wisper/app/modules/authentication/controller/google_sign_up_controller.dart';
import 'package:wisper/app/modules/authentication/controller/sign_in_controller.dart';
import 'package:wisper/app/modules/authentication/views/auth_screen.dart';
import 'package:wisper/app/modules/authentication/views/forgot_password.dart';
import 'package:wisper/app/modules/dashboard/views/dashboard_screen.dart';
import 'package:wisper/app/modules/profile/controller/buisness/buisness_controller.dart';
import 'package:wisper/app/modules/profile/controller/person/profile_controller.dart';
import 'package:wisper/gen/assets.gen.dart';

class SignInScreen extends StatefulWidget { 
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}
 
class _SignInScreenState extends State<SignInScreen> {
  final SignInController signInController = Get.put(SignInController());
  final ProfileController profileController = Get.put(ProfileController());
  final BusinessController businessController = Get.put(BusinessController());
  final GoogleSignUpAuthController googleAuthController = Get.put(
    GoogleSignUpAuthController(),
  );

  final formKey = GlobalKey<FormState>(); 
  final emailController = TextEditingController(
    text: 'aminulislamzxx5152@gmail.com',
  );
  final passwordController = TextEditingController(text: 'Aminul@123');
  // final passwordController = TextEditingController(text: '12345678');
  void signIn() {
    showLoadingOverLay(
      asyncFunction: () async => await performSignIn(context),
      msg: 'Please wait...',
    );
  }

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
      showSnackBarMessage(context, signInController.errorMessage, true);
    }
  }

  Future<void> performSignIn(BuildContext context) async {
    final bool isSuccess = await signInController.signIn(
      email: emailController.text,
      password: passwordController.text,
    );

    if (isSuccess) {
      await profileController.getMyProfile();
      await businessController.getMyProfile();
      if (StorageUtil.getData(StorageUtil.userId) == null) {
        await profileController.getMyProfile();
        await businessController.getMyProfile();
      } else {
        Get.offAll(() => MainButtonNavbarScreen());
      }
    } else {
      showSnackBarMessage(context, signInController.errorMessage, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.0.w, vertical: 0.0.w),
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                heightBox60,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      child: Text(
                        'Sign In',
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Get.to(AuthScreen()),
                      child: Text(
                        'Sign up',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w400,
                          color: LightThemeColors.blueColor,
                        ),
                      ),
                    ),
                  ],
                ),
                heightBox30,
                Label(label: 'Email'),
                heightBox10,
                CustomTextField(
                  controller: emailController,
                  hintText: 'email@gmail.com',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => ValidatorService.validateEmailAddress(
                    emailController.text,
                  ),
                ),
                heightBox16,
                Label(label: 'Password'),
                heightBox10,
                CustomTextField(
                  controller: passwordController,
                  suffixIcon: Icons.visibility_off,
                  hintText: '********',
                  obscureText: true, // Enable password hiding
                  keyboardType: TextInputType.text, // Fixed for password
                  validator: (value) => ValidatorService.validatePassword(
                    passwordController.text,
                  ),
                ),
                heightBox10,
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                      Get.to(const ForgotPasswordScreen());
                    },
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w400,
                        color: LightThemeColors.blueColor,
                      ),
                    ),
                  ),
                ),
                heightBox100,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
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
                          onTap: () {
                            signInGoogle();
                          },
                          child: CrashSafeImage(
                            Assets.images.gmail.keyName,
                            height: 30.h,
                          ),
                        ),
                        // widthBox14,
                        // CrashSafeImage(
                        //   Assets.images.facebook.keyName,
                        //   height: 30.h,
                        // ),
                      ],
                    ),
                  ],
                ),

                heightBox100,
                heightBox80,

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
                heightBox10,
                CustomElevatedButton(
                  height: 56,
                  title: 'Login',
                  onPress: () {
                    if (formKey.currentState!.validate()) {
                      print('Validated');
                      signIn();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
