import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:leasure_nft/app/core/app_colors.dart';
import 'package:leasure_nft/app/core/app_textstyle.dart';
import 'package:leasure_nft/app/core/widgets/header.dart';
import 'package:leasure_nft/app/users/contollers/user_main_controller.dart';
import 'package:leasure_nft/app/users/screens/network/controller/network_controller.dart';
import 'package:leasure_nft/app/users/screens/records/user_deposit_records.dart';

class NetworkScreen extends GetView<NetworkController> {
  const NetworkScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return GetBuilder<NetworkController>(
        init: NetworkController(),
        builder: (controller) {
          return Scaffold(
            body: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 16.h),
                child: Column(
                  children: [
                    Header(
                        title: "Network",
                        ontap: () {
                          final controller1 =
                              Get.find<UserDashboardController>();
                          controller1.changePage(DashboardTab.home.index);
                        }),
                    SizedBox(
                      height: 15.h,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Total Refferal Profit",
                          style: AppTextStyles.adaptiveText(context, 17)
                              .copyWith(
                                  fontWeight: FontWeight.normal,
                                  color: AppColors.blackColor),
                        ),
                        Obx(
                          () => Text(
                            "${controller.totalProfit.value.toStringAsFixed(2)} PKR",
                            style: AppTextStyles.adaptiveText(context, 17)
                                .copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.blackColor),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 15.h,
                    ),
                    Obx(
                      () => Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 10.w, vertical: 10.h),
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
                              text: "Level 1",
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
                              text: "Level 2",
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
                              text: "Level 3",
                              textColor: controller.currentTab.value == 2
                                  ? AppColors.whiteColor
                                  : AppColors.blackColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 20.h,
                    ),
                    Expanded(
                      child: Obx(() {
                        if (controller.isloading.value) {
                          return Center(child: CircularProgressIndicator());
                        }

                        List<Map<String, dynamic>> currentList = [];
                        if (controller.currentTab.value == 0) {
                          currentList = controller.level1;
                        } else if (controller.currentTab.value == 1) {
                          currentList = controller.level2;
                        } else if (controller.currentTab.value == 2) {
                          currentList = controller.level3;
                        }

                        if (currentList.isEmpty) {
                          return Center(
                              child: Text("No users found in this level"));
                        }

                        return Column(
                          children: [
                            controller.currentTab.value == 0
                                ? Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Total Level 1 Profit",
                                        style: AppTextStyles.adaptiveText(
                                                context, 17)
                                            .copyWith(
                                                fontWeight: FontWeight.normal,
                                                color: AppColors.blackColor),
                                      ),
                                      Obx(
                                        () => Text(
                                          "${controller.level1Profit.value.toStringAsFixed(2)} PKR",
                                          style: AppTextStyles.adaptiveText(
                                                  context, 17)
                                              .copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.blackColor),
                                        ),
                                      ),
                                    ],
                                  )
                                : controller.currentTab.value == 1
                                    ? Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "Total Level 2 Profit",
                                            style: AppTextStyles.adaptiveText(
                                                    context, 17)
                                                .copyWith(
                                                    fontWeight:
                                                        FontWeight.normal,
                                                    color:
                                                        AppColors.blackColor),
                                          ),
                                          Obx(
                                            () => Text(
                                              "${controller.level2Profit.value.toStringAsFixed(2)} PKR",
                                              style: AppTextStyles.adaptiveText(
                                                      context, 17)
                                                  .copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          AppColors.blackColor),
                                            ),
                                          ),
                                        ],
                                      )
                                    : controller.currentTab.value == 2
                                        ? Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                "Total Level 3 Profit",
                                                style:
                                                    AppTextStyles.adaptiveText(
                                                            context, 17)
                                                        .copyWith(
                                                            fontWeight:
                                                                FontWeight
                                                                    .normal,
                                                            color: AppColors
                                                                .blackColor),
                                              ),
                                              Obx(
                                                () => Text(
                                                  "${controller.level3Profit.value.toStringAsFixed(2)} PKR",
                                                  style: AppTextStyles
                                                          .adaptiveText(
                                                              context, 17)
                                                      .copyWith(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: AppColors
                                                              .blackColor),
                                                ),
                                              ),
                                            ],
                                          )
                                        : SizedBox(),
                            SizedBox(
                              height: 10.h,
                            ),
                            Expanded(
                              child: ListView.builder(
                                itemCount: currentList.length,
                                itemBuilder: (context, index) {
                                  final user = currentList[index];
                                  return Card(
                                    margin: EdgeInsets.symmetric(
                                        vertical: 6, horizontal: 4),
                                    child: ListTile(
                                      leading: Icon(Icons.person,
                                          size: 30,
                                          color: AppColors.accentColor),
                                      title: Text(
                                        user["name"],
                                        style: AppTextStyles.adaptiveText(
                                                context, 16)
                                            .copyWith(
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.primaryColor),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Email:  ${user["email"]}",
                                            style: AppTextStyles.adaptiveText(
                                                    context, 14)
                                                .copyWith(
                                                    fontWeight: FontWeight.w400,
                                                    color:
                                                        AppColors.blackColor),
                                          ),
                                          Text(
                                            "Total Profit:  ${user["totalProfit"]} PKR",
                                            style: AppTextStyles.adaptiveText(
                                                    context, 14)
                                                .copyWith(
                                                    fontWeight: FontWeight.w400,
                                                    color:
                                                        AppColors.blackColor),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      }),
                    )
                  ],
                ),
              ),
            ),
          );
        });
  }

  /// Recursively build tree nodes
}
