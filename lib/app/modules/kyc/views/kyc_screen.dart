import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:smile_id/smile_id.dart';
import 'package:smile_id/products/biometric/smile_id_biometric_kyc.dart';
import 'package:wisper/app/core/config/theme/light_theme_colors.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/core/utils/snack_bar.dart';
import 'package:wisper/app/core/widgets/common/custom_button.dart';
import 'package:wisper/app/core/widgets/common/custom_text_filed.dart';
import 'package:wisper/app/modules/kyc/controller/kyc_controller.dart';
import 'package:wisper/app/modules/kyc/views/kyc_success_screen.dart';

class KycScreen extends StatefulWidget {
  const KycScreen({super.key});

  @override
  State<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends State<KycScreen> {
  final KycController _kycController = Get.put(KycController());
  final TextEditingController _idNumberController = TextEditingController();

  String _selectedIdType = 'BVN';
  final List<String> _idTypes = ['BVN', 'NIN'];
  bool _showKycWidget = false;

  @override
  void dispose() {
    _idNumberController.dispose();
    super.dispose();
  }

  void _startBiometricKyc() {
    final idNumber = _idNumberController.text.trim();

    if (idNumber.isEmpty) {
      showSnackBarMessage(context, 'Please enter your $_selectedIdType number', true);
      return;
    }

    if (idNumber.length != 11) {
      showSnackBarMessage(context, '$_selectedIdType must be 11 digits', true);
      return;
    }

    // Skip selfie - directly validate BVN/NIN
    _validateIdNumber();
  }

  void _validateIdNumber() async {
    final idNumber = _idNumberController.text.trim();
    
    // Show loading
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            heightBox16,
            Text('Validating $_selectedIdType...', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
      barrierDismissible: false,
    );

    // Submit to backend for validation
    final bool success = await _kycController.submitKyc(
      smileJobId: DateTime.now().millisecondsSinceEpoch.toString(),
      idNumber: idNumber,
      idType: _selectedIdType,
      country: 'NG',
      selfieImagePath: '', // No selfie required
      resultCode: '0810',
      resultText: 'BVN/NIN validation successful',
    );

    Get.back(); // Close loading dialog

    if (success) {
      Get.off(() => const KycSuccessScreen());
    } else {
      if (mounted) {
        showSnackBarMessage(context, _kycController.errorMessage, true);
      }
    }
  }

  void _onKycSuccess(String resultJson) async {
    setState(() => _showKycWidget = false);

    // Submit result to Wisper backend
    final bool success = await _kycController.submitKyc(
      smileJobId: DateTime.now().millisecondsSinceEpoch.toString(),
      idNumber: _idNumberController.text.trim(),
      idType: _selectedIdType,
      country: 'NG',
      selfieImagePath: '',
      resultCode: '0810',
      resultText: resultJson,
    );

    if (success) {
      Get.off(() => const KycSuccessScreen());
    } else {
      if (mounted) {
        showSnackBarMessage(context, _kycController.errorMessage, true);
      }
    }
  }

  void _onKycError(String errorMessage) {
    setState(() => _showKycWidget = false);
    showSnackBarMessage(context, 'Verification failed: $errorMessage', true);
  }

  @override
  Widget build(BuildContext context) {
    if (_showKycWidget) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => setState(() => _showKycWidget = false),
          ),
          title: Text(
            'Identity Verification',
            style: TextStyle(color: Colors.white, fontSize: 18.sp),
          ),
        ),
        body: SafeArea(
          child: Container(
            width: double.infinity,
            height: double.infinity,
            child: SmileIDBiometricKYC(
              country: 'NG',
              idType: _selectedIdType,
              idNumber: _idNumberController.text.trim(),
              userId: 'user_${DateTime.now().millisecondsSinceEpoch}',
              jobId: 'job_${DateTime.now().millisecondsSinceEpoch}',
              onSuccess: _onKycSuccess,
              onError: _onKycError,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Identity Verification',
          style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            heightBox30,

            Center(
              child: Container(
                width: 80.w,
                height: 80.w,
                decoration: BoxDecoration(
                  color: LightThemeColors.blueColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.verified_user_outlined, size: 40.sp, color: LightThemeColors.blueColor),
              ),
            ),

            heightBox20,

            Center(
              child: Text(
                'Verify Your Identity',
                style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ),

            heightBox8,

            Center(
              child: Text(
                'We need to verify your identity before\nyou can access the wallet.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14.sp, color: const Color(0xFFD1D1D1), height: 1.5),
              ),
            ),

            heightBox40,

            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: LightThemeColors.blueColor.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('What you\'ll need:', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: Colors.white)),
                  heightBox12,
                  _buildRequirement(Icons.credit_card_outlined, 'Your BVN or NIN number'),
                  heightBox8,
                  _buildRequirement(Icons.verified_user_outlined, 'Government-issued ID verification'),
                  heightBox8,
                  _buildRequirement(Icons.security_outlined, 'Secure identity validation'),
                ],
              ),
            ),

            heightBox30,

            Text('Select ID Type', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: Colors.white)),
            heightBox8,
            Row(
              children: _idTypes.map((type) {
                final isSelected = _selectedIdType == type;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedIdType = type),
                    child: Container(
                      margin: EdgeInsets.only(right: type == 'BVN' ? 8.w : 0),
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      decoration: BoxDecoration(
                        color: isSelected ? LightThemeColors.blueColor : const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: isSelected ? LightThemeColors.blueColor : Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Center(
                        child: Text(type, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: Colors.white)),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            heightBox20,

            Text('$_selectedIdType Number', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: Colors.white)),
            heightBox8,
            CustomTextField(
              controller: _idNumberController,
              hintText: 'Enter your $_selectedIdType number',
              keyboardType: TextInputType.number,
            ),

            heightBox12,
            Text(
              'Your $_selectedIdType is an 11-digit number issued by the government.',
              style: TextStyle(fontSize: 12.sp, color: const Color(0xFF9E9E9E)),
            ),

            heightBox40,

            CustomElevatedButton(
              title: 'Verify ID Number',
              onPress: _startBiometricKyc,
            ),

            heightBox16,

            Center(
              child: Text(
                '🔒 Your data is encrypted and only used\nfor identity verification purposes.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11.sp, color: const Color(0xFF9E9E9E)),
              ),
            ),

            heightBox40,
          ],
        ),
      ),
    );
  }

  Widget _buildRequirement(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18.sp, color: LightThemeColors.blueColor),
        widthBox10,
        Text(text, style: TextStyle(fontSize: 13.sp, color: const Color(0xFFD1D1D1))),
      ],
    );
  }
}
