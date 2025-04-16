import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:leasure_nft/app/core/app_colors.dart';
import 'package:leasure_nft/app/routes/app_routes.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';
import 'package:universal_html/html.dart' as html;

class SignupController extends GetxController {
  var isObsure = true.obs;
  var isloding = false.obs;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  final refferalCodeController = TextEditingController();
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final GetStorage storage = GetStorage();

  @override
  void onInit() {
    getReferralFromCookie();

    super.onInit();
  }

  void togglePasswordVisibility() {
    isObsure.value = !isObsure.value;
  }

  void clearTextFields() {
    emailController.clear();
    passwordController.clear();
    nameController.clear();
    refferalCodeController.clear();
  }

  Future<String> getDeviceId() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String? storedId = storage.read('deviceId');

    if (storedId == null) {
      if (GetPlatform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        storedId = androidInfo.id;
      } else if (GetPlatform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        storedId = iosInfo.identifierForVendor;
      } else if (GetPlatform.isWeb) {
        WebBrowserInfo webInfo = await deviceInfo.webBrowserInfo;
        storedId = webInfo.userAgent ?? 'unknown_web_device';
      } else {
        storedId = 'unknown_device';
      }
      storage.write('deviceId', storedId);
      if (kDebugMode) {
        Get.log("[DEBUG] New Device ID generated: $storedId");
      }
    } else {
      if (kDebugMode) {
        Get.log("[DEBUG] Existing Device ID found: $storedId");
      }
    }
    return storedId!;
  }

  void getReferralFromCookie() {
    if (kIsWeb) {
      final cookies = html.document.cookie?.split('; ') ?? [];
      for (var cookie in cookies) {
        final parts = cookie.split('=');
        if (parts.length == 2 && parts[0] == 'ref') {
          refferalCodeController.text = parts[1];
          break;
        }
      }
    }
  }

  Future<bool> canCreateAccount() async {
    String deviceId = await getDeviceId();
    if (kDebugMode) {
      Get.log("[DEBUG] Checking device ID in Firestore: $deviceId");
    }

    final users = await firestore
        .collection('users')
        .where('deviceId', isEqualTo: deviceId)
        .get();

    if (kDebugMode) {
      Get.log(
          "[DEBUG] Accounts found with this device ID: \${users.docs.length}");
    }
    return users.docs.length < 2;
  }

  String generateOTP({int length = 6}) {
    final random = Random();
    return List.generate(length, (_) => random.nextInt(10)).join();
  }

  Future<void> sendOTPEmail(String email, String otp) async {
    final smtpServer = gmail(
      'leasurenft.suport@gmail.com',
      'idyf wzxy yvso bhvx', // App password
    );

    final message = Message()
      ..from = Address('leasurenft.suport@gmail.com', 'LeasureNFT Support')
      ..recipients.add(email)
      ..subject = 'Confirm your email for LeasureNFT'
      ..text = '''
Hi there,

Thanks for signing up with LeasureNFT!

Your verification code is: $otp

Please do not share this code with anyone.

Cheers,  
LeasureNFT Team
https://leasurenft.io
'''
      ..html = '''
<p>Hi there,</p>
<p>Thanks for signing up with <strong>LeasureNFT</strong>!</p>
<p>Your verification code is:</p>
<h2 style="color:#4CAF50;">$otp</h2>
<p>Please do not share this code with anyone.</p>
<p>Cheers,<br><strong>LeasureNFT Team</strong><br><a href="https://leasurenft.io">leasurenft.io</a></p>
''';

    try {
      final sendReport = await send(message, smtpServer);
      Get.log('✅ Email sent successfully: ${sendReport.toString()}');
    } on MailerException catch (e) {
      Get.log('❌ MailerException: Failed to send email.');
      for (var p in e.problems) {
        Get.log('Problem: ${p.code} - ${p.msg}');
      }
    } on ArgumentError catch (e) {
      Get.log('❌ ArgumentError: ${e.message}');
    } catch (e, stacktrace) {
      Get.log('❌ Unexpected error: $e');
      Get.log('Stacktrace: $stacktrace');
    }
  }

  // Future<void> createUser() async {
  //   isloding.value = true;

  //   try {
  //     // Get.log("[STEP 1] Creating user...");

  //     // UserCredential userCredential = await auth.createUserWithEmailAndPassword(
  //     //   email: emailController.text.trim(),
  //     //   password: passwordController.text.trim(),
  //     // );

  //     // User? user = userCredential.user;

  //     // if (user != null && !user.emailVerified) {
  //     //   Get.log("[STEP 2] Sending verification email...");
  //     //   await user.sendEmailVerification();
  //     //   isloding.value = false;

  //     //   Get.defaultDialog(
  //     //     barrierDismissible: false,
  //     //     backgroundColor: AppColors.whiteColor,
  //     //     title: "Verify Your Email",
  //     //     titleStyle: AppTextStyles.adaptiveText(Get.context!, 20).copyWith(
  //     //       color: AppColors.primaryColor,
  //     //       fontWeight: FontWeight.bold,
  //     //     ),
  //     //     middleTextStyle:
  //     //         AppTextStyles.adaptiveText(Get.context!, 16).copyWith(
  //     //       color: AppColors.blackColor,
  //     //     ),
  //     //     middleText:
  //     //         "A verification link has been sent to ${user.email}. Please verify and then press the button below.",
  //     //     confirm: ElevatedButton(
  //     //       style: ElevatedButton.styleFrom(
  //     //         backgroundColor: AppColors.accentColor,
  //     //         shape: RoundedRectangleBorder(
  //     //           borderRadius: BorderRadius.circular(12),
  //     //         ),
  //     //       ),
  //     //       onPressed: () async {
  //     //         try {
  //     //           isloding.value = true;

  //     //           Get.log("[STEP 3] Checking email verification status...");
  //     //           Fluttertoast.showToast(
  //     //               msg: "Checking email verification status...");

  //     //           bool isVerified = false;
  //     //           int retryCount = 0;

  //     //           while (retryCount < 3 && !isVerified) {
  //     //             await Future.delayed(Duration(seconds: 2));
  //     //             await user.reload();
  //     //             isVerified =
  //     //                 FirebaseAuth.instance.currentUser?.emailVerified ?? false;
  //     //             retryCount++;
  //     //           }

  //     //           if (isVerified) {
  //     //             Get.log(
  //     //                 "[STEP 4] Email verified! Creating Firestore data...");
  //     //             Fluttertoast.showToast(
  //     //                 msg: "Email verified! Creating Firestore data...");

  //     //             String deviceId = await getDeviceId();

  //                 // await firestore.collection('users').doc(user.uid).set({
  //                 //   'email': user.email,
  //                 //   'userId': user.uid,
  //                 //   'username': nameController.text.trim(),
  //                 //   'password': passwordController.text.trim(),
  //                 //   'depositAmount': '0',
  //                 //   'withdrawAmount': '0',
  //                 //   'reward': '0',
  //                 //   'deviceId': deviceId,
  //                 //   'cashVault': '0',
  //                 //   "isUserBanned": false,
  //                 //   'refferredBy': refferalCodeController.text.isEmpty
  //                 //       ? ""
  //                 //       : refferalCodeController.text,
  //                 //   'refferralProfit': '0',
  //                 //   'createdAt': FieldValue.serverTimestamp(),
  //                 //   'image': ''
  //                 // }).then((_) {
  //                 //   Fluttertoast.showToast(msg: 'Account created successfully');
  //                 //   Get.offAllNamed(AppRoutes.login);
  //                 //   clearTextFields();
  //                 // }).catchError((error) {
  //                 //   Get.log("[ERROR] Firestore save failed: $error");
  //                 //   MessageToast.showToast(msg: 'Error saving user data');
  //                 // });
  //     //           } else {
  //     //             Get.log("[INFO] Email not verified. Deleting user...");

  //     //             await user.delete(); // 🧨 Delete the unverified account

  //     //             Fluttertoast.showToast(
  //     //                 msg: "Email not verified. Account has been removed.");
  //     //             Get.back(); // Close dialog
  //     //           }
  //     //         } catch (e) {
  //     //           Get.log("[ERROR] While checking verification: $e");
  //     //           Fluttertoast.showToast(msg: "Error verifying email");
  //     //         } finally {
  //     //           isloding.value = false;
  //     //         }
  //     //       },
  //     //       child: Obx(
  //     //         () => isloding.value
  //     //             ? Padding(
  //     //                 padding: const EdgeInsets.all(8.0),
  //     //                 child: CircularProgressIndicator(
  //     //                   color: AppColors.whiteColor,
  //     //                 ),
  //     //               )
  //     //             : Text("I have verified",
  //     //                 style:
  //     //                     AppTextStyles.adaptiveText(Get.context!, 16).copyWith(
  //     //                   color: AppColors.whiteColor,
  //     //                   fontWeight: FontWeight.bold,
  //     //                 )),
  //     //       ),
  //     //     ),
  //     //   );

  //     //   isloding.value = false;
  //     // }
  //   } on FirebaseAuthException catch (e) {
  //     isloding.value = false;
  //     if (e.code == 'email-already-in-use') {
  //       MessageToast.showToast(msg: 'Email already in use');
  //     } else if (e.code == 'weak-password') {
  //       MessageToast.showToast(msg: 'Password is too weak');
  //     } else if (e.code == 'invalid-email') {
  //       MessageToast.showToast(msg: 'Invalid email address');
  //     } else {
  //       MessageToast.showToast(msg: 'Something went wrong: ${e.message}');
  //     }
  //   } catch (e) {
  //     isloding.value = false;
  //     MessageToast.showToast(msg: 'Something went wrong: $e');
  //   }
  // }

  Future<void> signUpUser() async {
    isloding.value = true;
    try {
      if (!await canCreateAccount()) {
        isloding.value = false;
        GetPlatform.isWeb
            ? Fluttertoast.showToast(
                msg: "You cannot create more than 2 accounts from this device",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
                backgroundColor: AppColors.errorColor,
                textColor: AppColors.whiteColor,
              )
            : Get.snackbar(
                "Account Creation Error",
                "You cannot create more than 2 accounts from this device",
                snackPosition: SnackPosition.BOTTOM,
                duration: const Duration(seconds: 2),
                backgroundColor: AppColors.errorColor,
                colorText: AppColors.whiteColor,
              );
        return;
      }
      final otp = generateOTP();

      // Send OTP
      await sendOTPEmail(emailController.text, otp);
      Get.log("[STEP 1] Sending OTP email...");

      // Save OTP temporarily
      await FirebaseFirestore.instance
          .collection('email_otps')
          .doc(emailController.text)
          .set({
        'otp': otp,
        'timestamp': FieldValue.serverTimestamp(),
        'password': passwordController.text, // temporarily store password
      });
      GetPlatform.isWeb
          ? Fluttertoast.showToast(
              msg: "OTP sent to ${emailController.text}",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              backgroundColor: AppColors.greenColor,
              textColor: AppColors.whiteColor,
            )
          : Get.snackbar(
              "OTP Sent",
              "OTP sent to ${emailController.text}",
              snackPosition: SnackPosition.BOTTOM,
              duration: const Duration(seconds: 2),
              backgroundColor: AppColors.greenColor,
              colorText: AppColors.whiteColor,
            );
      Get.toNamed(AppRoutes.varification, arguments: {
        'email': emailController.text,
        'name': nameController.text,
        'refferalCode': refferalCodeController.text.isEmpty
            ? ""
            : refferalCodeController.text,
        'deviceId': await getDeviceId(),
        'password': passwordController.text,
      });
    } catch (e) {
      isloding.value = false;
      Get.log("[ERROR] While sending OTP: $e");
      Fluttertoast.showToast(msg: "Error sending OTP $e");
    } finally {
      isloding.value = false;
    }
  }
}
