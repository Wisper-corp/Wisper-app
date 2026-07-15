import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wisper/app/core/utils/currency_helper.dart';
import 'package:wisper/app/core/utils/date_formatter.dart';
import 'package:wisper/app/modules/settings/model/wallet_model.dart';

class TransactionSection extends StatelessWidget {
  final List<TransectionItemModel>? allTransectionModel;
  final bool isLoading;

  const TransactionSection({
    super.key,
    this.allTransectionModel,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 16.h),
          Text(
            'Transaction History',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18.sp,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 12.h),

          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (allTransectionModel == null || allTransectionModel!.isEmpty)
            _buildEmpty()
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: allTransectionModel!.length,
              separatorBuilder: (_, __) => Divider(
                color: Colors.white.withOpacity(0.06),
                height: 1,
              ),
              itemBuilder: (context, index) {
                final item = allTransectionModel![index];
                return _buildTransactionTile(item);
              },
            ),

          SizedBox(height: 24.h),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(TransectionItemModel item) {
    final sym = CurrencyHelper.deviceSymbol;
    final isCredit = item.isCredit;
    final color = isCredit ? Colors.greenAccent : Colors.redAccent;
    final amountStr = item.amount != null
        ? '${isCredit ? '+' : '-'}$sym${item.amount!.toStringAsFixed(2)}'
        : '—';

    final DateFormatter df = DateFormatter(item.date ?? DateTime.now());

    // Icon based on type
    IconData icon;
    switch (item.type) {
      case 'DEPOSIT':
        icon = Icons.arrow_downward_rounded;
        break;
      case 'WITHDRAW':
        icon = Icons.arrow_upward_rounded;
        break;
      case 'SPEND':
        icon = Icons.payments_outlined;
        break;
      default:
        icon = Icons.swap_horiz_rounded;
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        children: [
          // Icon circle
          Container(
            width: 42.w,
            height: 42.w,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(icon, color: color, size: 18.sp),
            ),
          ),
          SizedBox(width: 12.w),

          // Label + date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.typeLabel,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  df.getShortDateFormat(),
                  style: TextStyle(
                    color: const Color(0xFF8C8C8C),
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),

          // Amount
          Text(
            amountStr,
            style: TextStyle(
              color: color,
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 40.h),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              color: const Color(0xFF444444),
              size: 48.sp,
            ),
            SizedBox(height: 12.h),
            Text(
              'No transactions yet',
              style: TextStyle(
                color: const Color(0xFF666666),
                fontSize: 14.sp,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Your transaction history will appear here.',
              style: TextStyle(
                color: const Color(0xFF555555),
                fontSize: 12.sp,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
