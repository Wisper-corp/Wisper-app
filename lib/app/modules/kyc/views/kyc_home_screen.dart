import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/modules/kyc/controller/kyc_status_controller.dart';
import 'package:wisper/app/modules/kyc/views/kyc_email_screen.dart';
import 'package:wisper/app/modules/kyc/views/kyc_phone_screen.dart';
import 'package:wisper/app/modules/kyc/views/kyc_nin_screen.dart';
import 'package:wisper/app/modules/kyc/views/kyc_address_screen.dart';
import 'package:wisper/app/modules/kyc/views/kyc_badge_screen.dart';

class KycHomeScreen extends StatelessWidget {
  const KycHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final KycStatusController controller = Get.put(KycStatusController());

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'KYC Verification',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.inProgress.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return RefreshIndicator(
          onRefresh: controller.loadStatus,
          color: const Color(0xFF168DE1),
          backgroundColor: const Color(0xFF1E1E1E),
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
            children: [
              _KycRow(
                title: 'Verify your Email',
                isVerified: controller.emailVerified,
                onTap: () async {
                  await Get.to(() => const KycEmailScreen());
                  controller.loadStatus();
                },
              ),
              heightBox12,
              _KycRow(
                title: 'Verify Phone Number',
                isVerified: controller.phoneVerified,
                onTap: () async {
                  await Get.to(() => const KycPhoneScreen());
                  controller.loadStatus();
                },
              ),
              heightBox12,
              _KycRow(
                title: 'Verify NIN',
                isVerified: controller.ninVerified,
                onTap: () async {
                  await Get.to(() => const KycNinScreen());
                  controller.loadStatus();
                },
              ),
              heightBox12,
              _KycRow(
                title: 'Verify your Address',
                isVerified: controller.addressVerified,
                isPendingReview:
                    controller.status.value?.address.isPendingReview ?? false,
                onTap: () async {
                  await Get.to(() => const KycAddressScreen());
                  controller.loadStatus();
                },
              ),
              heightBox12,
              _KycRow(
                title: 'Get Verification Badge',
                isVerified: controller.badgeActive,
                onTap: () async {
                  await Get.to(() => const KycBadgeScreen());
                  controller.loadStatus();
                },
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _KycRow extends StatelessWidget {
  final String title;
  final bool isVerified;
  final bool isPendingReview;
  final VoidCallback onTap;

  const _KycRow({
    required this.title,
    required this.isVerified,
    required this.onTap,
    this.isPendingReview = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 18.h),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isVerified
                ? const Color(0xFF168DE1).withOpacity(0.4)
                : const Color(0xFF333333),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (isPendingReview)
              _StatusChip(label: 'Pending', color: Colors.orange)
            else if (isVerified)
              Container(
                width: 24.w,
                height: 24.w,
                decoration: const BoxDecoration(
                  color: Color(0xFF168DE1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check, color: Colors.white, size: 14.sp),
              )
            else
              Container(
                width: 28.w,
                height: 28.w,
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF444444)),
                ),
                child: Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 12.sp,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
