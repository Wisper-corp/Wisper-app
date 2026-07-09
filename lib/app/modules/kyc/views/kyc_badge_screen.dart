import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:wisper/app/core/others/custom_size.dart';
import 'package:wisper/app/core/others/get_storage.dart';
import 'package:wisper/app/core/services/network_caller/network_caller.dart';
import 'package:wisper/app/core/utils/snack_bar.dart';
import 'package:wisper/app/core/widgets/common/custom_button.dart';
import 'package:wisper/app/modules/kyc/controller/kyc_status_controller.dart';
import 'package:wisper/app/urls.dart';

class KycBadgeScreen extends StatefulWidget {
  const KycBadgeScreen({super.key});

  @override
  State<KycBadgeScreen> createState() => _KycBadgeScreenState();
}

class _KycBadgeScreenState extends State<KycBadgeScreen> {
  bool _loading = false;

  Future<void> _activateBadge() async {
    setState(() => _loading = true);
    final res = await Get.find<NetworkCaller>().postRequest(
      Urls.kycBadgeActivateUrl,
      body: {},
      accessToken: StorageUtil.getData(StorageUtil.userAccessToken),
    );
    setState(() => _loading = false);
    if (res.isSuccess) {
      showSnackBarMessage(context, 'Verification badge activated!');
      await Get.find<KycStatusController>().loadStatus();
      setState(() {});
    } else {
      showSnackBarMessage(context, res.errorMessage, true);
    }
  }

  Future<void> _payOutstanding() async {
    setState(() => _loading = true);
    final res = await Get.find<NetworkCaller>().postRequest(
      Urls.kycBadgePayOutstandingUrl,
      body: {},
      accessToken: StorageUtil.getData(StorageUtil.userAccessToken),
    );
    setState(() => _loading = false);
    if (res.isSuccess) {
      showSnackBarMessage(context, 'Payment successful. Badge restored!');
      await Get.find<KycStatusController>().loadStatus();
      setState(() {});
    } else {
      showSnackBarMessage(context, res.errorMessage, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<KycStatusController>();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Get Verification Badge',
            style: TextStyle(
                color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: Obx(() {
        final status = controller.status.value;
        if (status == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final badge = status.badge;
        final isActive = badge.isActive;
        final hasGracePeriod = badge.gracePeriodEnd != null;
        final isEligible = status.isEligibleForBadge;
        final recCount = status.recommendationCount;

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Badge status card ─────────────────────────────────
              _BadgeStatusCard(isActive: isActive, hasGracePeriod: hasGracePeriod),
              heightBox20,

              // ── Active badge info ─────────────────────────────────
              if (isActive && badge.nextBillingDate != null && !badge.isFeeExempt) ...[
                _InfoRow(
                  label: 'Next Billing Date',
                  value: DateFormat('dd MMM yyyy').format(badge.nextBillingDate!),
                  icon: Icons.calendar_today,
                ),
                heightBox8,
              ],
              if (isActive && badge.isFeeExempt && badge.feeExemptUntil != null) ...[
                _InfoRow(
                  label: 'Fee Exemption Until',
                  value: DateFormat('dd MMM yyyy').format(badge.feeExemptUntil!),
                  icon: Icons.card_giftcard,
                  valueColor: Colors.green,
                ),
                heightBox8,
              ],
              if (hasGracePeriod) ...[
                _InfoRow(
                  label: 'Grace Period Ends',
                  value: DateFormat('dd MMM yyyy').format(badge.gracePeriodEnd!),
                  icon: Icons.warning_amber,
                  valueColor: Colors.orange,
                ),
                heightBox16,
                Container(
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Text(
                    'Your badge payment failed. Fund your wallet and pay ₦6,500 before the grace period ends to keep your badge active.',
                    style: TextStyle(
                        color: Colors.orange, fontSize: 13.sp, height: 1.5),
                  ),
                ),
                heightBox16,
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : CustomElevatedButton(
                        title: 'Pay ₦6,500 Now',
                        onPress: _payOutstanding,
                      ),
              ],

              // ── Requirements checklist (only if not active) ───────
              if (!isActive && !hasGracePeriod) ...[
                _SectionTitle('Requirements'),
                heightBox12,
                _Requirement(
                  label: 'Email verified',
                  met: status.email.isVerified,
                ),
                _Requirement(
                  label: 'Phone number verified',
                  met: status.phone.isVerified,
                ),
                _Requirement(
                  label: 'NIN verified',
                  met: status.nin.isVerified,
                ),
                _Requirement(
                  label: 'Address verified',
                  met: status.address.isVerified,
                ),
                _Requirement(
                  label: '20 recommendations (you have $recCount)',
                  met: recCount >= 20,
                ),
                heightBox24,

                // Fee info
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: const Color(0xFF333333)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: const Color(0xFF168DE1), size: 20.sp),
                      widthBox10,
                      Expanded(
                        child: Text(
                          'The verification badge costs ₦6,500/month, deducted automatically from your wallet.',
                          style: TextStyle(
                              color: const Color(0xFFD1D1D1),
                              fontSize: 13.sp,
                              height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
                heightBox24,

                if (isEligible) ...[
                  _loading
                      ? const Center(child: CircularProgressIndicator())
                      : CustomElevatedButton(
                          title: 'Activate Badge (₦6,500)',
                          onPress: _activateBadge,
                        ),
                ] else ...[
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Center(
                      child: Text(
                        'Complete all requirements above to activate your badge',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: const Color(0xFF666666), fontSize: 13.sp),
                      ),
                    ),
                  ),
                ],
              ],

              if (isActive && !hasGracePeriod) ...[
                heightBox16,
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Back',
                      style: TextStyle(
                          color: const Color(0xFF9E9E9E), fontSize: 13.sp)),
                ),
              ],
            ],
          ),
        );
      }),
    );
  }
}

class _BadgeStatusCard extends StatelessWidget {
  final bool isActive;
  final bool hasGracePeriod;
  const _BadgeStatusCard({required this.isActive, required this.hasGracePeriod});

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? (hasGracePeriod ? Colors.orange : const Color(0xFF168DE1))
        : const Color(0xFF444444);
    final label = isActive
        ? (hasGracePeriod ? 'Grace Period Active' : 'Badge Active')
        : 'Badge Inactive';
    final icon = isActive
        ? (hasGracePeriod ? Icons.warning_amber : Icons.verified)
        : Icons.verified_outlined;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 48.sp),
          heightBox12,
          Text(
            label,
            style: TextStyle(
                color: color, fontSize: 18.sp, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _Requirement extends StatelessWidget {
  final String label;
  final bool met;
  const _Requirement({required this.label, required this.met});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        children: [
          Container(
            width: 22.w,
            height: 22.w,
            decoration: BoxDecoration(
              color: met
                  ? const Color(0xFF168DE1)
                  : const Color(0xFF2A2A2A),
              shape: BoxShape.circle,
              border: Border.all(
                color: met
                    ? const Color(0xFF168DE1)
                    : const Color(0xFF444444),
              ),
            ),
            child: met
                ? Icon(Icons.check, color: Colors.white, size: 13.sp)
                : null,
          ),
          widthBox12,
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: met ? Colors.white : const Color(0xFF777777),
                fontSize: 14.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);
  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: TextStyle(
            color: Colors.white, fontSize: 15.sp, fontWeight: FontWeight.w700));
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color valueColor;
  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF9E9E9E), size: 16.sp),
        widthBox8,
        Text('$label: ',
            style: TextStyle(color: const Color(0xFF9E9E9E), fontSize: 13.sp)),
        Text(value,
            style: TextStyle(
                color: valueColor,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}
