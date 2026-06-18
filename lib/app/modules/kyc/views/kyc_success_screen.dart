import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/core/widgets/common/custom_button.dart';
import 'package:wisper/app/modules/settings/views/wallet_screen.dart';

class KycSuccessScreen extends StatelessWidget {
  const KycSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Success animation / icon
            Container(
              width: 120.w,
              height: 120.w,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_outline,
                size: 60.sp,
                color: Colors.green,
              ),
            ),

            heightBox24,

            Text(
              'Identity Verified!',
              style: TextStyle(
                fontSize: 26.sp,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),

            heightBox12,

            Text(
              'Your identity has been successfully verified.\nYou can now access all wallet features.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: const Color(0xFFD1D1D1),
                height: 1.6,
              ),
            ),

            heightBox50,

            CustomElevatedButton(
              title: 'Go to Wallet',
              onPress: () => Get.offAll(() => const WalletScreen()),
            ),

            heightBox16,

            TextButton(
              onPressed: () => Get.back(),
              child: Text(
                'Back to Home',
                style: TextStyle(
                  color: const Color(0xFF9E9E9E),
                  fontSize: 14.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
