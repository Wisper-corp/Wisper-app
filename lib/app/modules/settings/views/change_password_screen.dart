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
import 'package:wisper/app/modules/authentication/controller/change_password_controller.dart';
import 'package:wisper/app/modules/authentication/views/update_password_success_screen.dart';
import 'package:wisper/app/modules/authentication/widget/auth_header.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  ChangePasswordController changePasswordController = Get.put(
    ChangePasswordController(),
  );

  final TextEditingController oldPasswordController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final formKey = GlobalKey<FormState>();

  void changePassword() {
    showLoadingOverLay(
      asyncFunction: performChangePassword,
      msg: 'Please wait...',
    );
  }

  Future<void> performChangePassword() async {
    final bool isSuccess = await changePasswordController.changePassword(
      oldPassword: oldPasswordController.text,
      newPassword: passwordController.text,
    );

    if (!mounted) return;

    if (isSuccess) {
      Get.to(() => PasswordUpdateSuccessScreen());
      return;
    }

    // Never fail silently: an empty error would leave the button looking dead.
    final reason = changePasswordController.errorMessage.trim();
    showSnackBarMessage(
      context,
      reason.isEmpty ? 'Could not change your password. Please try again.' : reason,
      true,
    );
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
              mainAxisSize: MainAxisSize.min,
              children: [
                heightBox60,
                AuthHeader(title: 'Change Password'),
                heightBox20,
                Label(label: 'Old Password'),
                heightBox10,
                CustomTextField(
                  controller: oldPasswordController,
                  suffixIcon: Icons.visibility_off,
                  hintText: '********',
                  obscureText: true,
                  keyboardType: TextInputType.text,
                  // Only that something was typed: the account's existing
                  // password need not satisfy today's strength rules, and the
                  // server is what decides whether it is correct.
                  validator: (value) => ValidatorService.validateCurrentPassword(
                    oldPasswordController.text,
                  ),
                ),
                heightBox12,
                Label(label: 'Password'),
                heightBox10,
                CustomTextField(
                  controller: passwordController,
                  suffixIcon: Icons.visibility_off,
                  hintText: '********',
                  obscureText: true,
                  keyboardType: TextInputType.text,
                  validator: (value) => ValidatorService.validatePassword(
                    passwordController.text,
                  ),
                ),
                heightBox12,
                Label(label: 'Confirm Password'),
                heightBox10,
                CustomTextField(
                  controller: confirmPasswordController,
                  suffixIcon: Icons.visibility_off,
                  hintText: '********',
                  obscureText: true,
                  keyboardType: TextInputType.text,
                  validator: (value) =>
                      ValidatorService.validateConfirmPassword(
                        value,
                        passwordController.text,
                      ),
                ),

                heightBox200,
                heightBox100,
                Center(
                  child: CustomElevatedButton(
                    height: 56,
                    title: 'Submit',
                    onPress: () {
                      if (formKey.currentState!.validate()) {
                        changePassword();
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
