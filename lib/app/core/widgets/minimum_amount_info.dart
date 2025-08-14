import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:leasure_nft/app/core/app_colors.dart';
import 'package:leasure_nft/app/core/app_textstyle.dart';
import 'package:leasure_nft/app/core/assets/constant.dart';

class MinimumAmountInfo extends StatelessWidget {
  final String transactionType; // 'deposit' or 'withdraw'
  final Color? backgroundColor;
  final Color? textColor;

  const MinimumAmountInfo({
    Key? key,
    required this.transactionType,
    this.backgroundColor,
    this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDeposit = transactionType.toLowerCase() == 'deposit';
    final minAmount =
        isDeposit ? MINIMUM_DEPOSIT_AMOUNT : MINIMUM_WITHDRAW_AMOUNT;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: backgroundColor ?? AppColors.primaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: textColor ?? AppColors.primaryColor,
            size: 20.sp,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'Minimum ${transactionType.toLowerCase()} amount is ${minAmount.toInt()} PKR',
              style: AppTextStyles.adaptiveText(context, 14).copyWith(
                color: textColor ?? AppColors.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BalanceInfoCard extends StatelessWidget {
  final double currentBalance;
  final String transactionType;

  const BalanceInfoCard({
    Key? key,
    required this.currentBalance,
    required this.transactionType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isWithdraw = transactionType.toLowerCase() == 'withdraw';
    final minAmount =
        isWithdraw ? MINIMUM_WITHDRAW_AMOUNT : MINIMUM_DEPOSIT_AMOUNT;
    final canProceed = isWithdraw ? currentBalance >= minAmount : true;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: canProceed
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: canProceed
              ? Colors.green.withOpacity(0.3)
              : Colors.red.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                canProceed ? Icons.check_circle : Icons.error,
                color: canProceed ? Colors.green : Colors.red,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Current Balance',
                style: AppTextStyles.adaptiveText(context, 16).copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.blackColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            '${currentBalance.toStringAsFixed(2)} PKR',
            style: AppTextStyles.adaptiveText(context, 18).copyWith(
              fontWeight: FontWeight.bold,
              color: canProceed ? Colors.green : Colors.red,
            ),
          ),
          if (isWithdraw) ...[
            SizedBox(height: 8.h),
            Text(
              canProceed
                  ? '✓ You can withdraw up to ${currentBalance.toStringAsFixed(2)} PKR'
                  : '✗ Insufficient balance for minimum withdrawal',
              style: AppTextStyles.adaptiveText(context, 14).copyWith(
                color: canProceed ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
