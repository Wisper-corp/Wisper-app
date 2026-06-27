import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/config/theme/light_theme_colors.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/core/utils/show_over_loading.dart';
import 'package:wisper/app/core/utils/snack_bar.dart';
import 'package:wisper/app/core/utils/validator_service.dart';
import 'package:wisper/app/core/widgets/common/custom_button.dart';
import 'package:wisper/app/core/widgets/common/custom_text_filed.dart';
import 'package:wisper/app/core/widgets/common/label.dart';
import 'package:wisper/app/modules/authentication/controller/google_sign_up_controller.dart';
import 'package:wisper/app/modules/authentication/controller/sign_up_controller.dart';
import 'package:wisper/app/modules/authentication/views/otp_verification_screen.dart';
import 'package:wisper/app/modules/authentication/views/sign_in_screen.dart';
import 'package:wisper/gen/assets.gen.dart';

class RecruiterSignUpScreen extends StatefulWidget {
  const RecruiterSignUpScreen({super.key});

  @override
  State<RecruiterSignUpScreen> createState() => _RecruiterSignUpScreenState();
}

class _RecruiterSignUpScreenState extends State<RecruiterSignUpScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GoogleSignUpAuthController googleAuthController = Get.put(
    GoogleSignUpAuthController(),
  );
  final formKey = GlobalKey<FormState>();

  void signInGoogle() {
    showLoadingOverLay(
      asyncFunction: () async => await performGoogleSignIn(context),
      msg: 'Please wait...',
    );
  }

  Future<void> performGoogleSignIn(BuildContext context) async {
    final bool isSuccess = await googleAuthController.signUpWithGoogle(
      'BUSINESS',
    );

    if (isSuccess) {
    } else {
      showSnackBarMessage(context, 'Failed to sign in', true);
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
                        'Sign Up',
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Get.to(const SignInScreen()),
                      child: Text(
                        'Sign In',
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
                Label(label: 'Bussiness Name'),
                heightBox10,
                CustomTextField(
                  controller: nameController,
                  hintText: 'Bussiness Name',
                  keyboardType: TextInputType.text,
                  validator: ValidatorService.validateSimpleField,
                ),
                heightBox16,
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

                heightBox80,
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
                          onTap: signInGoogle,
                          child: Image.asset(
                            Assets.images.gmail.keyName,
                            height: 30.h,
                          ),
                        ),
                        // widthBox14,
                        // Image.asset(
                        //   Assets.images.facebook.keyName,
                        //   height: 30.h,
                        // ),
                      ],
                    ),
                  ],
                ),

                heightBox100,
                heightBox50,

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
                  title: 'Sign Up',
                  onPress: () {
                    if (formKey.currentState!.validate()) {
                      final signUpController = Get.put(SignUpController());
                      showLoadingOverLay(
                        asyncFunction: () async {
                          final bool isSuccess = await signUpController.signUp(
                            bussinessName: nameController.text.trim(),
                            email: emailController.text.trim(),
                            password: passwordController.text,
                            confirmPassword: passwordController.text,
                            industry: '',
                            address: '',
                          );
                          if (isSuccess) {
                            showSnackBarMessage(context, 'Successfully done');
                            Get.to(() => OtpVerificationScreen(email: emailController.text.trim()));
                          } else {
                            showSnackBarMessage(context, signUpController.errorMessage, true);
                          }
                        },
                        msg: 'Please wait...',
                      );
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
