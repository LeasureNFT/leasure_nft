import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_simple_treeview/flutter_simple_treeview.dart';
import 'package:get/get.dart';
import 'package:leasure_nft/app/core/app_colors.dart';
import 'package:leasure_nft/app/core/app_textstyle.dart';
import 'package:leasure_nft/app/core/widgets/header.dart';
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
                          Get.back();
                        }),
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
      return Center(child: Text("No users found in this level"));
    }

    return ListView.builder(
      itemCount: currentList.length,
      itemBuilder: (context, index) {
        final user = currentList[index];
        return Card(
          margin: EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: ListTile(
            leading: Icon(Icons.person),
            title: Text(user["name"]),
            subtitle: Text("UID: ${user["id"]}"),
          ),
        );
      },
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
  List<TreeNode> _buildTreeNodes(
      List<Map<String, dynamic>> referrals, context) {
    return referrals.map((referral) {
      return TreeNode(
        content: Container(
          padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.accentColor),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 5,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.person, color: AppColors.primaryColor),
              SizedBox(width: 10),
              Text(referral["name"],
                  style: AppTextStyles.adaptiveText(context, 15)),
            ],
          ),
        ),
        children: _buildTreeNodes(referral["children"], context),
      );
    }).toList();
  }
}
