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
import 'package:leasure_nft/app/core/widgets/toas_message.dart';
import 'package:leasure_nft/app/routes/app_routes.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:universal_html/html.dart' as html;
import 'package:uuid/uuid.dart';

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
    String deviceId = 'unknown_device';

    if (kIsWeb) {
      // SAFELY read deviceId from localStorage and handle type errors
      final stored = html.window.localStorage['deviceId'];
      if (stored is String && stored.isNotEmpty) {
        deviceId = stored;
        Get.log("[DEBUG] Existing Web Device ID: $deviceId");
      } else {
        deviceId = const Uuid().v4();
        html.window.localStorage['deviceId'] = deviceId;
        Get.log("[DEBUG] New Web Device ID: $deviceId");
      }
    } else {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      if (GetPlatform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id;
      } else if (GetPlatform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? 'unknown_ios_device';
      } else {
        deviceId = 'unsupported_platform';
      }
      Get.log("[DEBUG] Native Device ID: $deviceId");
    }

    return deviceId;
  }

  void getReferralFromCookie() {
    try {
      if (kIsWeb) {
        final rawCookies = html.document.cookie;
        if (rawCookies == null || rawCookies.isEmpty) {
          Get.log("[INFO] No cookies found.");
          return;
        }

        final cookies = rawCookies.split('; ');
        for (var cookie in cookies) {
          final parts = cookie.split('=');
          if (parts.length == 2) {
            final key = parts[0].trim();
            final value = parts[1].trim();
            if (key == 'ref') {
              refferalCodeController.text = value;
              Get.log("[DEBUG] Referral code found in cookie: $value");
              return;
            }
          }
        }

        Get.log("[INFO] 'ref' cookie not found.");
      } else {
        Get.log("[INFO] Not running on Web. Skipping cookie check.");
      }
    } catch (e, stackTrace) {
      Get.log("[ERROR] Failed to get referral from cookie: $e");
      Get.log("[STACKTRACE] $stackTrace");
    }
  }

  Future<bool> canCreateAccount() async {
    String deviceId = await getDeviceId();

    if (deviceId.isEmpty ||
        deviceId == 'unknown_device' ||
        deviceId == 'unsupported_platform') {
      Get.log("[ERROR] Invalid or empty device ID. Skipping Firestore check.");
      return false;
    }

    try {
      if (kDebugMode) {
        Get.log("[DEBUG] Checking device ID in Firestore: $deviceId");
      }

      final users = await firestore
          .collection('users')
          .where('deviceId', isEqualTo: deviceId)
          .get();

      if (kDebugMode) {
        Get.log(
            "[DEBUG] Accounts found with this device ID: ${users.docs.length}");
      }

      return users.docs.length < 2;
    } catch (e) {
      Get.log("[ERROR] Firestore query failed in canCreateAccount: $e");
      return false;
    }
  }

  String generateOTP({int length = 6}) {
    final random = Random();
    return List.generate(length, (_) => random.nextInt(10)).join();
  }

//   Future<void> sendOTPEmail(String email, String otp) async {
//     final smtpServer = gmail(
//       'leasurenft.suport@gmail.com',
//       'idyf wzxy yvso bhvx', // App password
//     );

//     final message = Message()
//       ..from = Address('leasurenft.suport@gmail.com', 'LeasureNFT Support')
//       ..recipients.add(email)
//       ..subject = 'Confirm your email for LeasureNFT'
//       ..text = '''
// Hi there,

// Thanks for signing up with LeasureNFT!

// Your verification code is: $otp

// Please do not share this code with anyone.

// Cheers,
// LeasureNFT Team
// https://leasurenft.io
// '''
//       ..html = '''
// <p>Hi there,</p>
// <p>Thanks for signing up with <strong>LeasureNFT</strong>!</p>
// <p>Your verification code is:</p>
// <h2 style="color:#4CAF50;">$otp</h2>
// <p>Please do not share this code with anyone.</p>
// <p>Cheers,<br><strong>LeasureNFT Team</strong><br><a href="https://leasurenft.io">leasurenft.io</a></p>
// ''';

//     try {
//       final sendReport = await send(message, smtpServer);
//       Get.log('✅ Email sent successfully: ${sendReport.toString()}');
//     } on MailerException catch (e) {
//       Get.log('❌ MailerException: Failed to send email.');
//       for (var p in e.problems) {
//         Get.log('Problem: ${p.code} - ${p.msg}');
//       }
//     } on ArgumentError catch (e) {
//       Get.log('❌ ArgumentError: ${e.message}');
//     } catch (e, stacktrace) {
//       Get.log('❌ Unexpected error: $e');
//       Get.log('Stacktrace: $stacktrace');
//     }
//   }
  Future<bool> sendOTPEmail(String email, String otp) async {
  final smtpServer =  SmtpServer(
    '144.126.143.170', // Direct IP as SMTP host
    port: 25, // Port 25 is usually used for SMTP
    ssl: false, // Port 25 doesn't use SSL usually
    username: 'admin@livinservices.com',
    password: 'livinservices',
  );

  final message = Message()
    ..from = Address('admin@livinservices.com', 'LeasureNFT Support') // Must match verified sender
    ..recipients.add(email)
    ..subject = 'Confirm your email for LeasureNFT'
    ..text = 'Your OTP is: $otp'
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
    Get.log('✅ Email sent: ${sendReport.toString()}');
    return true;
  } on MailerException catch (e) {
    Get.log('❌ MailerException:');
    for (var p in e.problems) {
      Get.log('Problem: ${p.code} - ${p.msg}');
    }
    return false;
  } catch (e, stacktrace) {
    Get.log('❌ Error: $e');
    Get.log('Stacktrace: $stacktrace');
    return false;
  }
}


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
      // final isOTPSent = await sendOTPEmail(emailController.text, otp);
      // Get.log("[STEP 1] Sending OTP email...");

      // if (!isOTPSent) {
      //   showToast("Failed to send OTP. Please try again." , isError: true) ;
      //   return; // Stop the flow, don’t go to next screen
      // }
showToast("Sending OTP... $otp");
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
        "otp": otp,
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
