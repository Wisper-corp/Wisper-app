import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/core/utils/show_over_loading.dart';
import 'package:wisper/app/core/utils/snack_bar.dart';
import 'package:wisper/app/core/utils/validator_service.dart';
import 'package:wisper/app/core/widgets/common/custom_button.dart';
import 'package:wisper/app/core/widgets/common/custom_text_filed.dart';
import 'package:wisper/app/core/widgets/common/label.dart';
import 'package:wisper/app/modules/authentication/controller/forgot_password_controller.dart';
import 'package:wisper/app/modules/authentication/views/otp_verification_screen.dart';
import 'package:wisper/app/modules/authentication/widget/auth_header.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
 
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final emailController = TextEditingController();
  final ForgotPasswordController forgotPasswordController = Get.put(
    ForgotPasswordController(),
  );
  final formKey = GlobalKey<FormState>();

  void forgotPassword() { 
    showLoadingOverLay(
      asyncFunction: () async => await performForgotPassword(context),
      msg: 'Please wait...',
    );
  }

  Future<void> performForgotPassword(BuildContext context) async {
    final bool isSuccess = await forgotPasswordController.forgotPassword(
      email: emailController.text,
    ); 

    if (isSuccess) {
      Get.to(
        () => OtpVerificationScreen(
          email: emailController.text,
          isResetpassword: true,
        ),
      );
    } else {
      showSnackBarMessage(context, forgotPasswordController.errorMessage, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.0.w, vertical: 0.0.w),
        child: SizedBox(
          height: double.infinity,
          width: double.infinity,
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                heightBox60,
                AuthHeader(
                  title: 'Forget Password',
                  subtitle:
                      'Please enter your email address to reset your password',
                ),
                heightBox30,
                Label(label: 'Email'),
                heightBox10, 
                CustomTextField(
                  controller: emailController,
                  hintText: 'example@gmail.com',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => ValidatorService.validateEmailAddress(
                    emailController.text,
                  ),
                ),
                heightBox50,

                Expanded(child: heightBox10),
                Center(
                  child: CustomElevatedButton(
                    height: 56,
                    title: 'Submit',
                    onPress: () {
                      if (formKey.currentState!.validate()) {
                        forgotPassword();
                      }
                    },
                    color: Colors.blue,
                  ),
                ),
                heightBox20,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
