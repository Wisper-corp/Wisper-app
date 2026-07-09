import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/core/services/network_caller/network_caller.dart';
import 'package:wisper/app/core/utils/snack_bar.dart';
import 'package:wisper/app/core/widgets/common/custom_button.dart';
import 'package:wisper/app/core/widgets/common/custom_text_filed.dart';
import 'package:wisper/app/urls.dart';
import 'dart:async';

class KycPhoneScreen extends StatefulWidget {
  const KycPhoneScreen({super.key});

  @override
  State<KycPhoneScreen> createState() => _KycPhoneScreenState();
}

class _KycPhoneScreenState extends State<KycPhoneScreen> {
  final _phoneCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _otpSent = false;
  bool _loading = false;
  String _otp = '';
  int _secondsRemaining = 60;
  bool _canResend = false;
  Timer? _timer;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _secondsRemaining = 60;
    _canResend = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsRemaining <= 0) {
        setState(() => _canResend = true);
        t.cancel();
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final res = await Get.find<NetworkCaller>().postRequest(
      Urls.kycPhoneSendOtpUrl,
      body: {'phone': _phoneCtrl.text.trim()},
      accessToken: StorageUtil.getData(StorageUtil.userAccessToken),
    );
    setState(() => _loading = false);
    if (res.isSuccess) {
      setState(() => _otpSent = true);
      _startTimer();
      showSnackBarMessage(context, 'OTP sent to ${_phoneCtrl.text.trim()}');
    } else {
      showSnackBarMessage(context, res.errorMessage, true);
    }
  }

  Future<void> _verifyOtp() async {
    if (_otp.length != 6) {
      showSnackBarMessage(context, 'Enter the 6-digit OTP', true);
      return;
    }
    setState(() => _loading = true);
    final res = await Get.find<NetworkCaller>().postRequest(
      Urls.kycPhoneVerifyUrl,
      body: {'phone': _phoneCtrl.text.trim(), 'otp': _otp},
      accessToken: StorageUtil.getData(StorageUtil.userAccessToken),
    );
    setState(() => _loading = false);
    if (res.isSuccess) {
      showSnackBarMessage(context, 'Phone number verified successfully!');
      Navigator.pop(context);
    } else {
      showSnackBarMessage(context, res.errorMessage, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Verify Phone Number',
            style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Phone Number',
                  style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.w600)),
              heightBox8,
              CustomTextField(
                controller: _phoneCtrl,
                hintText: 'e.g. +2348012345678',
                keyboardType: TextInputType.phone,
                enabled: !_otpSent,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Phone number is required';
                  if (v.trim().length < 10) return 'Enter a valid phone number';
                  return null;
                },
              ),
              heightBox8,
              Text(
                'An OTP will be sent via SMS to this number.',
                style: TextStyle(color: const Color(0xFF9E9E9E), fontSize: 12.sp),
              ),
              heightBox24,
              if (!_otpSent) ...[
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : CustomElevatedButton(title: 'Send OTP via SMS', onPress: _sendOtp),
              ] else ...[
                Text(
                  'Enter the 6-digit code sent to ${_phoneCtrl.text.trim()}',
                  style: TextStyle(color: const Color(0xFF9E9E9E), fontSize: 13.sp),
                ),
                heightBox20,
                PinCodeTextField(
                  appContext: context,
                  length: 6,
                  keyboardType: TextInputType.number,
                  animationType: AnimationType.fade,
                  animationDuration: const Duration(milliseconds: 200),
                  onChanged: (v) => setState(() => _otp = v),
                  pinTheme: PinTheme(
                    shape: PinCodeFieldShape.box,
                    borderRadius: BorderRadius.circular(10.r),
                    fieldHeight: 50.h,
                    fieldWidth: 46.w,
                    activeColor: const Color(0xFF168DE1),
                    selectedColor: const Color(0xFF168DE1),
                    inactiveColor: const Color(0xFF2B2B2B),
                    activeFillColor: const Color(0xFF1E1E1E),
                    selectedFillColor: const Color(0xFF1E1E1E),
                    inactiveFillColor: const Color(0xFF1E1E1E),
                  ),
                  enableActiveFill: true,
                  backgroundColor: Colors.transparent,
                ),
                heightBox16,
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Didn't receive?",
                        style: TextStyle(color: const Color(0xFF9E9E9E), fontSize: 13.sp)),
                    widthBox8,
                    GestureDetector(
                      onTap: _canResend ? _sendOtp : null,
                      child: Text(
                        _canResend ? 'Resend' : 'Resend in ${_secondsRemaining}s',
                        style: TextStyle(
                          color: _canResend ? const Color(0xFF168DE1) : const Color(0xFF555555),
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                heightBox24,
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : CustomElevatedButton(title: 'Verify Phone Number', onPress: _verifyOtp),
                heightBox12,
                TextButton(
                  onPressed: () => setState(() { _otpSent = false; _timer?.cancel(); }),
                  child: Text('Change number',
                      style: TextStyle(color: const Color(0xFF168DE1), fontSize: 13.sp)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
