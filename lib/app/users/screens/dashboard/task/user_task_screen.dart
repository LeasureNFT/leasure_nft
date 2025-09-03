import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:leasure_nft/app/core/app_colors.dart';
import 'package:leasure_nft/app/core/app_textstyle.dart';
import 'package:leasure_nft/app/core/widgets/custom_button.dart';
import 'package:leasure_nft/app/core/widgets/header.dart';
import 'package:leasure_nft/app/routes/app_routes.dart';
import 'package:leasure_nft/app/users/contollers/user_main_controller.dart';
import 'package:leasure_nft/app/users/screens/dashboard/task/controller/user_task_controller.dart';

class UserTaskScreen extends GetView<UserTaskController> {
  final formkey = GlobalKey<FormState>();
  UserTaskScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return GetBuilder<UserTaskController>(
        init: UserTaskController(),
        builder: (controller) {
          return Scaffold(
              body: SafeArea(
                  child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            child: Column(
              children: [
                Header(
                  title: "Daily Task",
                  ontap: () {
                    final controller1 = Get.put(UserDashboardController());
                    controller1.changePage(DashboardTab.home.index);
                    // controller1.pageController
                    //     .jumpToPage(DashboardTab.home.index);
                  },
                ),
                SizedBox(
                  height: 20.h,
                ),
                Obx(
                  () => Expanded(
                    child: controller.isLoading.value
                        ? Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primaryColor,
                            ),
                          )
                        : controller.errorMsg.value.isNotEmpty
                            ? _buildBalanceWarning(context, controller.errorMsg.value)
                            : controller.taskList.isEmpty
                                ? Center(
                                    child: Text(
                                      "No Task Found!",
                                      style: AppTextStyles.adaptiveText(
                                              context, 18)
                                          .copyWith(
                                              color: AppColors.blackColor300),
                                    ),
                                  )
                                : ListView.builder(
                                itemCount: controller.taskList.length,
                                itemBuilder: (context, index) {
                                  return GestureDetector(
                                    onTap: () {
                                      // Get.to(() => ViewTaskScreen(
                                      //       task: controller.taskList[index],
                                      //     ));
                                    },
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 10.w, vertical: 10.h),
                                      margin: EdgeInsets.only(
                                          bottom: 15.h, right: 5.w, left: 5.w),
                                      decoration: BoxDecoration(
                                          color: controller
                                                      .completedTasks[index] ==
                                                  true
                                              ? AppColors.accentColor
                                              : AppColors.whiteColor,
                                          borderRadius:
                                              BorderRadius.circular(12.r),
                                          boxShadow: [
                                            BoxShadow(
                                                color: AppColors.blackColor300,
                                                spreadRadius: 1,
                                                blurRadius: 5,
                                                offset: Offset(0, 3))
                                          ]),
                                      width: double.infinity,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              controller.taskList[index]
                                                  ["task"],
                                              style: AppTextStyles.adaptiveText(
                                                      context, 18)
                                                  .copyWith(
                                                      color: AppColors
                                                          .primaryColor,
                                                      fontWeight:
                                                          FontWeight.bold)),
                                          SizedBox(
                                            height: 5.h,
                                          ),
                                          Text(
                                              controller.taskList[index]
                                                  ["description"],
                                              style: AppTextStyles.adaptiveText(
                                                      context, 16)
                                                  .copyWith(
                                                      color:
                                                          AppColors.blackColor,
                                                      fontWeight:
                                                          FontWeight.normal)),
                                          SizedBox(
                                            height: 5.h,
                                          ),
                                          CustomButton(
                                            onPressed: () {
                                              controller.completedTasks[
                                                          index] ==
                                                      true
                                                  ? null
                                                  : Get.toNamed(
                                                      AppRoutes.viewTaskDetail,
                                                      arguments: {
                                                        "task": controller
                                                            .taskList[index],
                                                        "index": index
                                                      },
                                                    );
                                            },
                                            text: controller.completedTasks[
                                                        index] ==
                                                    true
                                                ? "Task Completed"
                                                : "View Task",
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                  ),
                ),
              ],
            ),
          )));
        });
  }

  Widget _buildBalanceWarning(BuildContext context, String errorMessage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.all(20.w),
          margin: EdgeInsets.symmetric(horizontal: 20.w),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: Colors.red.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.account_balance_wallet,
                size: 80,
                color: Colors.red,
              ),
              SizedBox(height: 20.h),
              Text(
                "Insufficient Balance",
                style: AppTextStyles.adaptiveText(context, 24)
                    .copyWith(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 15.h),
              Text(
                errorMessage,
                style: AppTextStyles.adaptiveText(context, 16)
                    .copyWith(
                  color: AppColors.blackColor,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 25.h),
              Container(
                padding: EdgeInsets.all(15.w),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: AppColors.primaryColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      "To access daily tasks, you need:",
                      style: AppTextStyles.adaptiveText(context, 14)
                          .copyWith(
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      "Minimum Balance: 500 PKR",
                      style: AppTextStyles.adaptiveText(context, 16)
                          .copyWith(
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
              CustomButton(
                onPressed: () {
                  // Navigate to deposit screen
                  final controller1 = Get.put(UserDashboardController());
                  controller1.changePage(DashboardTab.deposit.index);
                },
                text: "Deposit Now",
              ),
            ],
          ),
        ),
      ],
    );
  }
}
