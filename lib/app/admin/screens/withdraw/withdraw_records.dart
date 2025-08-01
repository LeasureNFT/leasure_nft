import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:leasure_nft/app/core/app_colors.dart';
import 'package:leasure_nft/app/core/app_textstyle.dart';
import 'package:leasure_nft/app/core/widgets/header.dart';
import 'package:leasure_nft/app/users/screens/records/user_deposit_records.dart';
import 'package:leasure_nft/app/admin//screens/transaction_detail_screen.dart';
import 'package:leasure_nft/app/admin//screens/withdraw/controller/withdraw_record_controller.dart';

class WithdrawRecords extends StatelessWidget {
  const WithdrawRecords({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize controller
    final controller = Get.put(WithdrawRecordController());

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 15.h),
          child: Column(
            children: [
              Header(
                  title: "Withdraw",
                  ontap: () {
                    Get.back();
                  }),
              SizedBox(height: 15.h),
              Obx(() => Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
                    decoration: BoxDecoration(
                      color: AppColors.blackColor200,
                      borderRadius: BorderRadius.circular(15.r),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        swapButton(
                          buttonColor: controller.currentTab.value == 0
                              ? AppColors.accentColor
                              : AppColors.transparentColor,
                          context: context,
                          ontap: () {
                            controller.changeTab(0);
                          },
                          text: "Pending",
                          textColor: controller.currentTab.value == 0
                              ? AppColors.whiteColor
                              : AppColors.blackColor,
                        ),
                        swapButton(
                          buttonColor: controller.currentTab.value == 1
                              ? AppColors.accentColor
                              : AppColors.transparentColor,
                          context: context,
                          ontap: () {
                            controller.changeTab(1);
                          },
                          text: "Completed",
                          textColor: controller.currentTab.value == 1
                              ? AppColors.whiteColor
                              : AppColors.blackColor,
                        ),
                        swapButton(
                          buttonColor: controller.currentTab.value == 2
                              ? AppColors.accentColor
                              : AppColors.transparentColor,
                          context: context,
                          ontap: () {
                            controller.changeTab(2);
                          },
                          text: "Cancelled",
                          textColor: controller.currentTab.value == 2
                              ? AppColors.whiteColor
                              : AppColors.blackColor,
                        ),
                      ],
                    ),
                  )),
              SizedBox(height: 20.h),
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return Center(
                        child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 10.h),
                        Text("Loading withdrawals...",
                            style: AppTextStyles.adaptiveText(context, 14)),
                      ],
                    ));
                  }

                  if (controller.errorMessage.isNotEmpty) {
                    return Center(
                        child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, color: Colors.red, size: 50),
                        SizedBox(height: 10.h),
                        Text(
                          controller.errorMessage.value,
                          style: TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 10.h),
                        ElevatedButton(
                          onPressed: () => controller.fetchPayments(),
                          child: Text("Retry"),
                        ),
                      ],
                    ));
                  }

                  return controller.currentTab.value == 0
                      ? _buildPaymentList(controller.pendingPayments,
                          "No Pending Withdrawals", context)
                      : controller.currentTab.value == 1
                          ? _buildPaymentList(controller.completedPayments,
                              "No Completed Withdrawals", context)
                          : _buildPaymentList(controller.cancelledPayments,
                              "No Cancelled Withdrawals", context);
                }),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentList(List payments, String emptyMessage, context) {
    return payments.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 50, color: AppColors.blackColor300),
                SizedBox(height: 10.h),
                Text(emptyMessage,
                    style: AppTextStyles.adaptiveText(context, 15)
                        .copyWith(color: AppColors.blackColor300)),
              ],
            ),
          )
        : ListView.builder(
            itemCount: payments.length,
            itemBuilder: (context, index) {
              var payment = payments[index];
              return InkWell(
                onTap: () {
                  Get.to(() => TransactionDetailScreen(
                        transaction: payment,
                        isFormAmin: true,
                      ));
                },
                child: Card(
                  elevation: 7,
                  child: ListTile(
                    title: Text(
                        "Transaction ID: ${payment['transactionId'] ?? 'Loading..'}",
                        style: AppTextStyles.adaptiveText(context, 18).copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
                        )),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(payment['accountName'] ?? 'No Name',
                            style: AppTextStyles.adaptiveText(context, 15)
                                .copyWith(
                              fontWeight: FontWeight.normal,
                              color: AppColors.primaryColor,
                            )),
                        Text(
                          "Amount: ${payment['amount'] ?? '0'}",
                          style:
                              AppTextStyles.adaptiveText(context, 15).copyWith(
                            fontWeight: FontWeight.normal,
                            color: AppColors.blackColor,
                          ),
                        ),
                      ],
                    ),
                    trailing: Text(payment['status'],
                        style: AppTextStyles.adaptiveText(context, 16).copyWith(
                            fontWeight: FontWeight.normal,
                            color: payment['status'] == "pending"
                                ? AppColors.primaryColor
                                : payment['status'] == "completed"
                                    ? AppColors.accentColor
                                    : Colors.red)),
                  ),
                ),
              );
            },
          );
  }
}
