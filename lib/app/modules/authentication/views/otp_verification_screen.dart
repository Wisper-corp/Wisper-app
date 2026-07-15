import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:wisper/app/core/others/custom_size.dart'; 
import 'package:wisper/app/core/utils/show_over_loading.dart';
import 'package:wisper/app/core/utils/snack_bar.dart';
import 'package:wisper/app/core/widgets/common/custom_button.dart';
import 'package:wisper/app/core/widgets/common/details_card.dart';
import 'package:wisper/app/modules/authentication/controller/otp_verify_controller.dart';
import 'package:wisper/app/modules/authentication/controller/resend_otp_controller.dart';
import 'package:wisper/app/modules/authentication/controller/sign_in_controller.dart';
import 'package:wisper/app/modules/authentication/views/reset_password_screen.dart';
import 'package:wisper/app/modules/authentication/views/sign_in_screen.dart';
import 'package:wisper/app/modules/authentication/widget/auth_header.dart';
import 'package:wisper/app/modules/dashboard/views/dashboard_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final bool isResetpassword;
  final String? password; // for auto sign-in after registration OTP

  const OtpVerificationScreen({
    super.key,
    this.isResetpassword = false,
    required this.email,
    this.password,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final otpController = TextEditingController();
  final OtpVerifyController otpVerifyController = Get.put(
    OtpVerifyController(),
  );

  final ResendOtpController resendOtpController = Get.put(
    ResendOtpController(),
  );
  int _secondsRemaining = 60;
  bool _isTimerActive = true;
  Timer? _timer;
  String _otpCode = '';

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 0) {
        setState(() {
          _isTimerActive = false;
          timer.cancel();
        });
      } else {
        setState(() {
          _secondsRemaining--;
        });
      }
    });
  }

  void _resendOtp() {
    if (!_isTimerActive) {
      setState(() {
        resendOtp(context);
        _secondsRemaining = 60;
        _isTimerActive = true;
      });
      _startTimer();
      // Add logic to resend OTP here
    }
  }

  void _otpVerify() {
    showLoadingOverLay(
      asyncFunction: () async => await performOtpVerify(context),
      msg: 'Please wait...',
    );
  }

  Future<void> performOtpVerify(BuildContext context) async {
    final bool isSuccess = await otpVerifyController.otpVerify(
      isShowVerify: widget.isResetpassword ? false : true,
      email: widget.email,
      otp: _otpCode,
    );

    if (isSuccess) {
      showSnackBarMessage(context, 'Successfully done');
      if (widget.isResetpassword) {
        Get.to(() => ResetPasswordScreen(email: widget.email));
      } else if (widget.password != null && widget.password!.isNotEmpty) {
        // Auto sign-in after registration — go directly to home
        final signInController = Get.put(SignInController());
        final loggedIn = await signInController.signIn(
          email: widget.email,
          password: widget.password,
        );
        if (loggedIn) {
          Get.offAll(() => MainButtonNavbarScreen());
        } else {
          // Sign-in failed — fallback to sign-in screen
          Get.offAll(() => const SignInScreen());
        }
      } else {
        Get.offAll(() => const SignInScreen());
      }
    } else {
      showSnackBarMessage(context, otpVerifyController.errorMessage, true);
    }
  }

  Future<void> resendOtp(BuildContext context) async {
    final bool isSuccess = await resendOtpController.resend(
      email: widget.email,
    );

    if (isSuccess) {
      showSnackBarMessage(context, 'Resend OTP Done');
    } else {
      showSnackBarMessage(context, otpVerifyController.errorMessage, true);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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
              heightBox60,
              AuthHeader(
                title: widget.isResetpassword
                    ? 'Reset Password'
                    : 'Verify Your Email Address',
                subtitle:
                    'Please enter the OTP sent to ${widget.email} to verify your account:',
              ),
              heightBox30,
              PinCodeTextField(
                controller: otpController,
                length: 6,
                obscureText: false,

                keyboardType: TextInputType.number,
                animationType: AnimationType.fade,
                animationDuration: const Duration(milliseconds: 300),
                onChanged: (value) {
                  setState(() {
                    _otpCode = value;
                  });
                },
                pinTheme: PinTheme(
                  selectedColor: Colors.black,
                  activeColor: Color(0xff2B2B2B),
                  borderWidth: 0.5,
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(12.r),
                  inactiveColor: Color(0xff2B2B2B),
                  fieldHeight: 47.h,
                  fieldWidth: 47.h,
                  activeFillColor: const Color.fromARGB(255, 141, 140, 140),
                  inactiveFillColor: Color(0xff2B2B2B),
                  selectedFillColor: Color.fromARGB(255, 141, 140, 140),
                ),
                backgroundColor: Colors.transparent,
                enableActiveFill: true,
                appContext: context,
              ),
              heightBox50,
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Didn’t get code?',
                    style: TextStyle(color: Colors.white, fontSize: 14.sp),
                  ),
                  widthBox4,
                  DetailsCard(
                    bgColor: const Color(0xff2B2B2B),
                    borderRadius: 4,
                    borderColor: Colors.transparent,
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Text(
                        '${_secondsRemaining}s',
                        style: TextStyle(color: Colors.white, fontSize: 14.sp),
                      ),
                    ),
                  ),
                  widthBox4,
                  GestureDetector(
                    onTap: _resendOtp,
                    child: Text(
                      'Resend',
                      style: TextStyle(
                        color: _isTimerActive ? Colors.grey : Colors.blue,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                ],
              ),
              heightBox40,
              Center(
                child: CustomElevatedButton(
                  width: 200,
                  height: 56,
                  title: 'Verify Email',
                  onPress: _otpCode.length == 6 ? _otpVerify : null,
                  color: _otpCode.length == 6
                      ? Colors.blue
                      : const Color(0xff6A6A6A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
