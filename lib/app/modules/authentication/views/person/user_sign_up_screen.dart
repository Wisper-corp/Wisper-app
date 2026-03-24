// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/config/theme/light_theme_colors.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/core/widgets/common/circle_icon.dart';
import 'package:wisper/app/core/widgets/common/line_widget.dart';
import 'package:wisper/app/modules/authentication/controller/sign_up_controller.dart';
import 'package:wisper/app/modules/authentication/views/job_interest_screen.dart';
import 'package:wisper/app/modules/authentication/views/person/footer_section.dart';
import 'package:wisper/app/modules/authentication/views/person/information_section.dart';
import 'package:wisper/app/modules/authentication/views/person/password_section.dart';
import 'package:wisper/app/modules/authentication/views/sign_in_screen.dart';
import 'package:wisper/gen/assets.gen.dart';

class SignUpScreen extends StatefulWidget {
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool isPasswordPage = false;
  bool showConfirmButton = false;
  bool showPreviousButton = false;
  bool showFinishedButton = false;
  final _formKey = GlobalKey<FormState>(); // Form key for validation
  final _firstNameController = TextEditingController();
  final _titleController = TextEditingController();

  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final SignUpController signUpController = Get.put(SignUpController());

  @override
  void initState() {
    super.initState();
    // Add listeners to update showConfirmButton
    _firstNameController.addListener(_checkFields);
    _lastNameController.addListener(_checkFields);
    _emailController.addListener(_checkFields);
    _phoneController.addListener(_checkFields);
    _titleController.addListener(_checkFields);
  }

  void _checkFields() {
    setState(() {
      showConfirmButton =
          _firstNameController.text.isNotEmpty &&
          _lastNameController.text.isNotEmpty &&
          _emailController.text.isNotEmpty &&
          _titleController.text.isNotEmpty &&
          _phoneController.text.isNotEmpty;
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _titleController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _goToPasswordPage() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isPasswordPage = true;
        showPreviousButton = true;
        showFinishedButton = true;
        showConfirmButton = false;
      });
    }
  }

  void _goToInformationPage() {
    setState(() {
      isPasswordPage = false;
      showPreviousButton = false;
      showFinishedButton = false;
      showConfirmButton =
          _firstNameController.text.isNotEmpty &&
          _lastNameController.text.isNotEmpty &&
          _emailController.text.isNotEmpty &&
          _titleController.text.isNotEmpty &&
          _phoneController.text.isNotEmpty;
    });
  }

  void _finishSignUp() {
    if (_formKey.currentState!.validate()) {
      Get.to(
        () => JobInterestScreen(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          password: _passwordController.text,
          title: _titleController.text.trim(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.0.w, vertical: 0.0.w),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              heightBox50,
              isPasswordPage
                  ? GestureDetector(
                      onTap: _goToInformationPage,
                      child: Row(
                        children: [
                          CircleIconWidget(
                            color: LightThemeColors.blueColor,
                            iconColor: Colors.white,
                            imagePath: Assets.images.arrowBack.keyName,
                            onTap: _goToInformationPage,
                          ),
                          widthBox8,
                          Text(
                            'Previous',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w400,
                              color: LightThemeColors.blueColor,
                            ),
                          ),
                        ],
                      ),
                    )
                  : CircleIconWidget(
                      imagePath: Assets.images.arrowBack.keyName,
                      onTap: () {},
                    ),
              heightBox16,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (isPasswordPage)
                    GestureDetector(
                      onTap: _finishSignUp,
                      child: Text(
                        'finished',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w400,
                          color: LightThemeColors.blueColor,
                        ),
                      ),
                    )
                  else if (showConfirmButton)
                    GestureDetector(
                      onTap: _goToPasswordPage,
                      child: Text(
                        'continue',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w400,
                          color: LightThemeColors.blueColor,
                        ),
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: () {
                        Get.to(const SignInScreen());
                      },
                      child: Text(
                        'sign in',
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
              Row(
                children: [
                  Expanded(
                    child: StraightLiner(
                      height: 3,
                      color: isPasswordPage ? Colors.grey : Colors.white,
                    ),
                  ),
                  widthBox10,
                  Expanded(
                    child: StraightLiner(
                      height: 3,
                      color: isPasswordPage ? Colors.white : Colors.grey,
                    ),
                  ),
                ],
              ),
              heightBox30,
              Form(
                key: _formKey,
                child: isPasswordPage
                    ? PasswordSection(
                        passwordController: _passwordController,
                        confirmPasswordController: _confirmPasswordController,
                      )
                    : InformationSection(
                        titleController: _titleController,
                        firstNameController: _firstNameController,
                        lastNameController: _lastNameController,
                        emailController: _emailController,
                        phoneController: _phoneController,
                      ),
              ),
              heightBox100,
              FooterSection(),
            ],
          ),
        ),
      ),
    );
  }
}
