import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:leasure_nft/app/core/app_colors.dart';
import 'package:leasure_nft/app/routes/app_routes.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';

class VerificationController extends GetxController {
  final verificationController = TextEditingController();
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final GetStorage storage = GetStorage();
  final isLoading = false.obs;

  late String email, password, name;
  String? referralCode, deviceId;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = Get.arguments;
      if (args != null) {
        email = args['email'];
        password = args['password'];
        referralCode = args['refferalCode'];
        deviceId = args['deviceId'];
        name = args['name'];
        Get.log(
            "[DEBUG] VerificationController initialized with email: $email, password: $password, referralCode: $referralCode, deviceId: $deviceId, name: $name");
      }
    });
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
  void showToast(String message, {bool isError = false}) {
    if (GetPlatform.isWeb) {
      Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: isError ? AppColors.errorColor : AppColors.greenColor,
        textColor: AppColors.whiteColor,
      );
    } else {
      Get.snackbar(
        isError ? 'Error' : 'Success',
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: isError ? AppColors.errorColor : AppColors.greenColor,
        colorText: AppColors.whiteColor,
        duration: const Duration(seconds: 2),
      );
    }
  }


Future<void>resend() async {
    

    try {
      final otp = generateOTP();
      await sendOTPEmail(email, otp);
      await firestore.collection('email_otps').doc(email).set({
        'otp': otp,
        'createdAt': FieldValue.serverTimestamp(),
      });

      
      showToast('Verification code sent to $email');
    } on FirebaseException catch (e) {
      showToast(e.message ?? 'Failed to send OTP', isError: true);
    } catch (e) {
      showToast('Unexpected error occurred: $e', isError: true);
    } 
  }
  Future<void> verifyEmail() async {
    isLoading.value = true;

    try {
      final doc = await firestore.collection('email_otps').doc(email).get();
      Get.log("[DEBUG] Document data: \${doc.data()}");

      if (!doc.exists || doc.data() == null) {
        showToast('No verification code found for this email', isError: true);
      } else {
        final storedOtp = doc['otp'];
        final enteredOtp = verificationController.text.trim();
        Get.log("[DEBUG] Stored OTP: $storedOtp, Entered OTP: $enteredOtp");

        if (storedOtp == enteredOtp) {
          final userCredential = await auth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );

          final user = userCredential.user;
          if (user != null) {
            await firestore.collection('users').doc(user.uid).set({
              'email': user.email,
              'userId': user.uid,
              'username': name,
              'password': password,
              'depositAmount': '0',
              'withdrawAmount': '0',
              'reward': '0',
              'deviceId': deviceId,
              'cashVault': '0',
              "isUserBanned": false,
              'refferredBy': referralCode,
              'refferralProfit': '0',
              'createdAt': FieldValue.serverTimestamp(),
              'image': ''
            });

            showToast('Account created successfully');
            Get.offAllNamed(AppRoutes.login);
          } else {
            throw Exception("User creation failed");
          }
        } else {
          showToast('Invalid verification code', isError: true);
        }
      }
    } on FirebaseAuthException catch (e) {
      showToast(e.message ?? 'Authentication error', isError: true);
    } on FirebaseException catch (e) {
      showToast(e.message ?? 'Firestore error', isError: true);
    } catch (e) {
      showToast('Unexpected error occurred: \$e', isError: true);
    } finally {
      isLoading.value = false;
    }
  }
}
