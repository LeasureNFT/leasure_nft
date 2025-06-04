import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:leasure_nft/app/auth_controllers/signup_controller.dart';
import 'package:leasure_nft/app/core/app_colors.dart';
import 'package:leasure_nft/app/core/app_textstyle.dart';
import 'package:leasure_nft/app/core/assets/app_images.dart';
import 'package:leasure_nft/app/core/widgets/custom_button.dart';
import 'package:leasure_nft/app/routes/app_routes.dart';
import 'package:leasure_nft/constants.dart';
import 'package:leasure_nft/app/core/widgets/custom_text_field.dart';

class SignUpScreen extends GetView<SignupController> {
  SignUpScreen({super.key});

  final formkey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SignupController>(
        init: SignupController(),
        builder: (controller) => Scaffold(
              body: SingleChildScrollView(
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 15.w, vertical: 20.h),
                  child: Form(
                    key: formkey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 20.h,
                        ),
                        Center(
                          child: SizedBox(
                            height: 180.h,
                            child: Image.asset(AppImages.logo),
                          ),
                        ),
                        SizedBox(
                          height: 15.h,
                        ),
                        // Dynamic spacing
                        Text('Create Account',
                            style: AppTextStyles.adaptiveText(context, 20)
                                .copyWith(fontWeight: FontWeight.bold)),
                        SizedBox(height: 10.h),
                        Text('Let\'s get started',
                            style: AppTextStyles.adaptiveText(context, 18)
                                .copyWith(fontWeight: FontWeight.w500)),
                        SizedBox(height: 20.h),

                        if (controller
                            .refferalCodeController.text.isNotEmpty) ...[
                          CustomTextField(
                            title: 'Refferal Code',
                            readOnly: true,
                            controller: controller.refferalCodeController,
                            hintText: 'Enter your refferal code',
                            prefixIcon: Icons.person,
                            keyboardType: TextInputType.name,
                          ),
                          SizedBox(height: 10.h),
                        ],
                        CustomTextField(
                          title: 'Name',
                          validator: (v) {
                            if (v!.isEmpty) {
                              return 'Name is required';
                            }

                            return null;
                          },
                          controller: controller.nameController,
                          hintText: 'Enter your Name',
                          prefixIcon: Icons.person,
                          keyboardType: TextInputType.name,
                        ),

                        SizedBox(height: 10.h),
                        CustomTextField(
                          title: 'Email',
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Email is required';
                            }

                            String email = v.trim();

                            // Basic structure check
                            if (!email.contains('@') ||
                                !email.endsWith('.com')) {
                              return 'Email must contain "@" and end with ".com"';
                            }

                            // Length check
                            if (email.length > 254) {
                              return 'Email is too long';
                            }

                            // Must be Gmail only
                            if (!email.toLowerCase().endsWith('@gmail.com')) {
                              return 'Only Gmail addresses are allowed';
                            }

                            // Advanced regex for Gmail format
                            final regex = RegExp(
                                r"^(?!\.)(?!.*\.\.)([a-zA-Z0-9]+([._]?[a-zA-Z0-9]+)*)@gmail\.com$");
                            if (!regex.hasMatch(email)) {
                              return 'Enter a valid Gmail address';
                            }

                            // Disposable domain block (edge case)
                            List<String> disposableDomains = [
                              'mailinator.com',
                              '10minutemail.com',
                              'tempmail.com',
                              'guerrillamail.com',
                              'fakeinbox.com',
                              'yopmail.com',
                            ];

                            String domain = email.split('@').last.toLowerCase();
                            if (disposableDomains.contains(domain)) {
                              return 'Disposable email addresses are not allowed';
                            }

                            return null;
                          },
                          controller: controller.emailController,
                          hintText: 'Always use original Gmail',
                          prefixIcon: Icons.email,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        SizedBox(height: 10.h),

                        Obx(
                          () => CustomTextField(
                            validator: (v) {
                              if (v!.isEmpty) {
                                return 'Password is required';
                              } else if (v.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                            title: 'Password',
                            controller: controller.passwordController,
                            hintText: 'Enter your password',
                            prefixIcon: Icons.lock,
                            obscureText: controller.isObsure.value,
                            suffixIcon: IconButton(
                              icon: Icon(
                                controller.isObsure.value
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: kPrimaryColor,
                              ),
                              onPressed: controller.togglePasswordVisibility,
                            ),
                          ),
                        ),

                        SizedBox(height: 50.h),
                        Obx(
                          () => CustomButton(
                            loading: controller.isloding.value,
                            onPressed: () {
                              // Get.to(() => VarificationScreen());
                              if (formkey.currentState!.validate()) {
                                controller.signUpUser();
                              }
                            },
                            text: 'SignUp',
                          ),
                        ),
                        SizedBox(height: 30.h),
                        InkWell(
                          onTap: () {
                            Get.toNamed(AppRoutes.login);
                            controller.clearTextFields();
                          },
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('You have an account? ',
                                  style: AppTextStyles.adaptiveText(context, 14)
                                      .copyWith(fontWeight: FontWeight.w500)),
                              Text('Login',
                                  style: AppTextStyles.adaptiveText(context, 15)
                                      .copyWith(
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.primaryColor)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ));
  }
}
