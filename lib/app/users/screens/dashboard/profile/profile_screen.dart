import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:leasure_nft/app/core/app_colors.dart';
import 'package:leasure_nft/app/core/app_textstyle.dart';
import 'package:leasure_nft/app/core/widgets/header.dart';
import 'package:leasure_nft/app/users/contollers/user_main_controller.dart';
import 'package:leasure_nft/app/users/screens/contact_us/contact_us_screen.dart';
import 'package:leasure_nft/app/users/screens/records/record_screen.dart';
import 'package:leasure_nft/app/auth_screens/user_login_screen.dart';
import 'package:leasure_nft/app/users/screens/dashboard/about_us/about_us_screen.dart';
import 'package:leasure_nft/app/users/screens/dashboard/profile/controller/profile_controller.dart';
import 'package:leasure_nft/app/users/screens/dashboard/profile/update_profile_screen.dart';
import 'package:leasure_nft/app/core/utils/common_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

class UserProfileScreen extends GetView<ProfileController> {
  const UserProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileController>(
        init: ProfileController(),
        builder: (controller) {
          return Scaffold(
            body: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 15.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Header(
                        title: "Profile",
                        ontap: () {
                          final controller1 =
                              Get.find<UserDashboardController>();
                          controller1.changePage(DashboardTab.home.index);
                        }),
                    SizedBox(
                      height: 20.h,
                    ),
                    // Profile Picture
                    Obx(
                      () => Center(
                        child: CircleAvatar(
                          radius: 50.r,
                          backgroundColor:
                              AppColors.accentColor.withOpacity(0.5),
                          child: controller.userModel.value?.image != null &&
                                  controller.userModel.value!.image!.isNotEmpty
                              ? ClipOval(
                                  child: Image.memory(
                                  base64Decode(
                                    controller.userModel.value!.image!,
                                  ),
                                  width: 160
                                      .r, // Should match the diameter (2 * radius)
                                  height: 160.r,
                                  fit: BoxFit.cover,
                                ))
                              : Icon(
                                  Icons.person,
                                  size: 80,
                                  color: AppColors.primaryColor,
                                ),
                        ),
                      ),
                    ),
                    SizedBox(height: 15.h),

                    // User Name
                    Obx(
                      () => Text(
                        controller.userModel.value?.username ?? "No Name",
                        style: AppTextStyles.adaptiveText(context, 18).copyWith(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.bold),
                      ),
                    ),

                    // Email

                    SizedBox(height: 10.h),

                    // Profile Options
                    Expanded(
                      child: ListView(
                        children: [
                          _buildProfileOption(
                            context: context,
                            icon: Icons.person,
                            title: 'Edit Profile',
                            onTap: () {
                              Get.to(() => UpdateProfileScreen());
                            },
                          ),
                          _buildProfileOption(
                            context: context,
                            icon: Icons.history,
                            title: 'Records',
                            onTap: () {
                              Get.to(() => RecordScreen());
                              // Navigate to settings screen
                            },
                          ),
                          _buildProfileOption(
                            context: context,
                            icon: Icons.contact_support_sharp,
                            title: 'Contact Us',
                            onTap: () {
                              Get.to(() => ContactUsScreen());
                              // Navigate to help and support screen
                            },
                          ),
                          _buildProfileOption(
                            context: context,
                            icon: Icons.info,
                            title: 'About Us',
                            onTap: () {
                              Get.to(() => AboutUsScreen());
                            },
                          ),
                          if (GetPlatform.isWeb)
                            _buildProfileOption(
                              context: context,
                              icon: Icons.download,
                              title: 'Download App',
                              onTap: () async {
                                // "https://github.com/LeasureNFT/leasureNFT/releases/download/1.0.0/app-release.apk"
                                // Get.to(() => AboutUsScreen());
                                final Uri url = Uri.parse(
                                    "https://github.com/LeasureNFT/leasure_nft/releases/download/1.0/app-release.apk");

                                if (await canLaunchUrl(url)) {
                                  await launchUrl(url,
                                      mode: LaunchMode.externalApplication);
                                } else {
                                  throw 'Could not launch $url';
                                }
                              },
                            ),
                          _buildProfileOption(
                            context: context,
                            icon: Icons.logout,
                            title: 'Log Out',
                            onTap: () async {
                              showDialog(
                                context: context,
                                builder: (context) => CommonDialog(
                                  title: 'Logout',
                                  message:
                                      'Do you want to logout your account?',
                                  icon: Icons.logout,
                                  iconColor: AppColors.primaryColor,
                                  negativeButtonText: 'NO',
                                  positiveButtonText: 'YES',
                                  onPositiveButtonPressed: () async {
                                    final box = GetStorage();

                                    // Close the dialog
                                    final user =
                                        FirebaseAuth.instance.currentUser;
                                    if (user == null) return;

                                    String uid = user.uid;
                                    String? lastResetDate =
                                        box.read<String>('lastResetDate');
                                    String currentDate =
                                        DateFormat('yyyy-MM-dd')
                                            .format(DateTime.now());

                                    if (lastResetDate == null ||
                                        lastResetDate != currentDate) {
                                      // Clear the saved 'completedTasks' from local storage (empty list for the new day)
                                      box.remove('completedTasks_$uid');
                                      box.remove("cashValue");
                                      // Save the updated 'completedTasks' list (as an empty list or initialized state)

                                      // Store the new date to track the last reset
                                    }
                                    await FirebaseAuth.instance.signOut();
                                    Get.offAll(() => UserLoginScreen());
                                    Get.back();
                                  },
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    context,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8.h),
        padding: EdgeInsets.symmetric(vertical: 15.h, horizontal: 12.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppColors.accentColor,
              size: 25.r,
            ),
            VerticalDivider(),
            Text(title,
                style: AppTextStyles.adaptiveText(context, 16).copyWith(
                    color: AppColors.blackColor, fontWeight: FontWeight.bold)),
            Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}
