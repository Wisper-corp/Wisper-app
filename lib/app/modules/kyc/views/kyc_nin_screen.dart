import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/core/services/network_caller/network_caller.dart';
import 'package:wisper/app/core/utils/snack_bar.dart';
import 'package:wisper/app/core/widgets/common/custom_button.dart';
import 'package:wisper/app/core/widgets/common/custom_text_filed.dart';
import 'package:wisper/app/modules/kyc/controller/kyc_status_controller.dart';
import 'package:wisper/app/urls.dart';

class KycNinScreen extends StatefulWidget {
  const KycNinScreen({super.key});

  @override
  State<KycNinScreen> createState() => _KycNinScreenState();
}

class _KycNinScreenState extends State<KycNinScreen> {
  final _ninCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  // Retrieved from QoreID (read-only)
  bool _verified = false;
  String _firstName = '';
  String _lastName = '';
  String _dob = '';
  int _attemptsUsed = 0;
  final int _maxAttempts = 3;

  @override
  void initState() {
    super.initState();
    // Pre-populate attempts from status if available
    final status = Get.find<KycStatusController>().status.value;
    if (status != null) {
      _attemptsUsed = status.nin.attemptsUsed;
      if (status.nin.isVerified) {
        _verified = true;
        _firstName = status.nin.firstName ?? '';
        _lastName = status.nin.lastName ?? '';
        _dob = status.nin.dateOfBirth ?? '';
      }
    }
  }

  @override
  void dispose() {
    _ninCtrl.dispose();
    super.dispose();
  }

  Future<void> _verifyNin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final res = await Get.find<NetworkCaller>().postRequest(
      Urls.kycNinVerifyUrl,
      body: {'nin': _ninCtrl.text.trim()},
      accessToken: StorageUtil.getData(StorageUtil.userAccessToken),
    );
    setState(() {
      _loading = false;
      _attemptsUsed++;
    });

    if (res.isSuccess && res.responseData != null) {
      final data = res.responseData['data'];
      setState(() {
        _verified = true;
        _firstName = data?['firstName'] ?? '';
        _lastName = data?['lastName'] ?? '';
        _dob = data?['dateOfBirth'] ?? '';
      });
      showSnackBarMessage(context, 'NIN verified successfully!');
    } else {
      showSnackBarMessage(context, res.errorMessage, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isLocked = _attemptsUsed >= _maxAttempts && !_verified;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Verify NIN',
            style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_verified) ...[
              // ── Verified result (read-only) ──────────────────────────
              _VerifiedBanner(),
              heightBox24,
              _ReadOnlyField(label: 'First Name', value: _firstName),
              heightBox12,
              _ReadOnlyField(label: 'Last Name', value: _lastName),
              heightBox12,
              _ReadOnlyField(label: 'Date of Birth', value: _dob),
              heightBox24,
              CustomElevatedButton(
                title: 'Done',
                onPress: () => Navigator.pop(context),
              ),
            ] else if (isLocked) ...[
              // ── Locked — max attempts reached ──────────────────────
              _LockedBanner(),
            ] else ...[
              // ── NIN input ──────────────────────────────────────────
              if (_attemptsUsed > 0)
                Padding(
                  padding: EdgeInsets.only(bottom: 16.h),
                  child: _AttemptsWarning(
                    attemptsUsed: _attemptsUsed,
                    maxAttempts: _maxAttempts,
                  ),
                ),
              Text(
                'National Identification Number (NIN)',
                style: TextStyle(
                    color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.w600),
              ),
              heightBox8,
              Form(
                key: _formKey,
                child: CustomTextField(
                  controller: _ninCtrl,
                  hintText: 'Enter your 11-digit NIN',
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(11),
                  ],
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'NIN is required';
                    if (v.trim().length != 11) return 'NIN must be exactly 11 digits';
                    return null;
                  },
                ),
              ),
              heightBox8,
              Text(
                'Your NIN details will be retrieved automatically via QoreID.',
                style: TextStyle(color: const Color(0xFF9E9E9E), fontSize: 12.sp),
              ),
              heightBox24,
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : CustomElevatedButton(title: 'Verify NIN', onPress: _verifyNin),
            ],
          ],
        ),
      ),
    );
  }
}

class _VerifiedBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.verified, color: Colors.green, size: 24.sp),
          widthBox12,
          Expanded(
            child: Text(
              'NIN verified successfully. Details retrieved from QoreID.',
              style: TextStyle(color: Colors.green, fontSize: 13.sp),
            ),
          ),
        ],
      ),
    );
  }
}

class _LockedBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.lock_outline, color: Colors.red, size: 40.sp),
          heightBox16,
          Text(
            'Maximum Attempts Reached',
            style: TextStyle(
                color: Colors.red, fontSize: 16.sp, fontWeight: FontWeight.w700),
          ),
          heightBox8,
          Text(
            'You have used all 3 NIN verification attempts. Please contact Customer Support for further assistance.',
            textAlign: TextAlign.center,
            style: TextStyle(color: const Color(0xFFD1D1D1), fontSize: 13.sp, height: 1.5),
          ),
          heightBox20,
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF168DE1)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r)),
            ),
            child: Text('Contact Support',
                style: TextStyle(color: const Color(0xFF168DE1), fontSize: 14.sp)),
          ),
        ],
      ),
    );
  }
}

class _AttemptsWarning extends StatelessWidget {
  final int attemptsUsed;
  final int maxAttempts;
  const _AttemptsWarning({required this.attemptsUsed, required this.maxAttempts});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18.sp),
          widthBox8,
          Expanded(
            child: Text(
              'Attempt $attemptsUsed of $maxAttempts used. '
              '${maxAttempts - attemptsUsed} remaining.',
              style: TextStyle(color: Colors.orange, fontSize: 12.sp),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;
  const _ReadOnlyField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: const Color(0xFF9E9E9E),
                fontSize: 12.sp,
                fontWeight: FontWeight.w500)),
        heightBox6,
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: const Color(0xFF333333)),
          ),
          child: Text(
            value.isEmpty ? '—' : value,
            style: TextStyle(color: Colors.white, fontSize: 15.sp),
          ),
        ),
      ],
    );
  }
}
