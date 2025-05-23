import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:leasure_nft/app/auth_controllers/verification_controler.dart';
import 'package:leasure_nft/app/core/app_colors.dart';
import 'package:leasure_nft/app/core/app_textstyle.dart';
import 'package:leasure_nft/app/core/widgets/custom_button.dart';
import 'package:leasure_nft/app/core/widgets/header.dart';
import 'package:leasure_nft/app/core/widgets/toas_message.dart';

class VarificationScreen extends GetView<VerificationController> {
  final formKey = GlobalKey<FormState>();
  VarificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<VerificationController>(
      init: VerificationController(),
      builder: (controller) => Scaffold(
        backgroundColor: AppColors.scaffoldColor,
        body: SafeArea(
            child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 15.h),
          child: Form(
            key: formKey,
            child: Column(
              children: [
                Header(
                    title: "Email Verification",
                    ontap: () async {
                      final user = FirebaseAuth.instance.currentUser;

                      if (user != null) {
                        await user.reload(); // Refresh user's latest state

                        if (!user.emailVerified) {
                          // Email is not verified — delete user
                          await user.delete();
                          showToast("Email not verified.",
                              isError: true);
                        } else {
                          showToast("Email verified successfully!");
                        }
                      }

                      Get.back(); // Go back either way
                    }),
                SizedBox(
                  height: 30.h,
                ),

                SizedBox(
                  height: 20.h,
                ),
                Obx(
                  () => Text.rich(
                    TextSpan(
                      text: "A verification link has been sent to ",
                      style: AppTextStyles.adaptiveText(context, 16).copyWith(
                        color: AppColors.blackColor,
                        fontWeight: FontWeight.normal,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text: controller.email.value,
                          style:
                              AppTextStyles.adaptiveText(context, 18).copyWith(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text:
                              ". Please go to the email address and verify your account.",
                          style:
                              AppTextStyles.adaptiveText(context, 16).copyWith(
                            color: AppColors.blackColor,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: 20.h,
                ),
                Obx(
                  () => CustomButton(
                    loading: controller.isLoading.value,
                    onPressed: () {
                      controller.verifyEmailAndCreateAccount();
                    },
                    text: "Verify",
                  ),
                ),
                SizedBox(
                  height: 15.h,
                ),
                // InkWell(
                //   onTap: () async {
                //     await controller.resend();
                //   },
                //   child: Row(
                //     crossAxisAlignment: CrossAxisAlignment.center,
                //     mainAxisAlignment: MainAxisAlignment.center,
                //     children: [
                //       Text('Didn\'t receive code? ',
                //           style: AppTextStyles.adaptiveText(context, 14)
                //               .copyWith(fontWeight: FontWeight.w500)),
                //       Text('Resend',
                //           style: AppTextStyles.adaptiveText(context, 15)
                //               .copyWith(
                //                   fontWeight: FontWeight.w500,
                //                   color: AppColors.primaryColor)),
                //     ],
                //   ),
                // ),
              ],
            ),
          ),
        )),
      ),
    );
  }
}
