import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:leasure_nft/app/auth_controllers/verification_controler.dart';
import 'package:leasure_nft/app/core/app_colors.dart';
import 'package:leasure_nft/app/core/app_textstyle.dart';
import 'package:leasure_nft/app/core/widgets/custom_button.dart';
import 'package:leasure_nft/app/core/widgets/custom_text_field.dart';
import 'package:leasure_nft/app/core/widgets/header.dart';

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
                    ontap: () {
                      Get.back();
                    }),
                SizedBox(
                  height: 30.h,
                ),
                Obx(
                  () => Text(
                      "A verification code has been sent to ${controller.email.value}. Please enter the code from your email address.",
                      style: AppTextStyles.adaptiveText(context, 16).copyWith(
                          color: AppColors.blackColor,
                          fontWeight: FontWeight.normal)),
                ),
                SizedBox(
                  height: 20.h,
                ),
                Obx(
                  () => Text(" Your Otp is ${controller.otp.value}",
                      style: AppTextStyles.adaptiveText(context, 16).copyWith(
                          color: AppColors.blackColor,
                          fontWeight: FontWeight.normal)),
                ),
                SizedBox(
                  height: 20.h,
                ),
                CustomTextField(
                    controller: controller.verificationController,
                    title: "Verification Code",
                    keyboardType: TextInputType.number,
                    inputFormatter: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    hintText: "Enter Otp",
                    validator: (p0) {
                      if (p0!.isEmpty) {
                        return "Please enter your verification code";
                      } else if (p0.length < 6) {
                        return "Please enter a valid verification code";
                      }

                      return null;
                    },
                    prefixIcon: Icons.pin_outlined),
                SizedBox(
                  height: 20.h,
                ),
                SizedBox(
                  height: 20.h,
                ),
                Obx(
                  () => CustomButton(
                    loading: controller.isLoading.value,
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        controller.verifyEmail();
                      }
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
