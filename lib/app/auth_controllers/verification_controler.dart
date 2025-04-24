import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:leasure_nft/app/core/app_colors.dart';
import 'package:leasure_nft/app/routes/app_routes.dart';

class VerificationController extends GetxController {
  final verificationController = TextEditingController();
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final GetStorage storage = GetStorage();
  final isLoading = false.obs;

  RxBool isResending = false.obs;
  var email = "".obs;
  var password = "".obs;
  var name = "".obs;
  var otp = "".obs;
  var referralCode = "".obs;
  var deviceId = "".obs;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = Get.arguments;
      if (args != null) {
        email.value = args['email'];
        password.value = args['password'];
        referralCode.value = args['refferalCode'];
        deviceId.value = args['deviceId'];
        name.value = args['name'];

        // Retrieve OTP verification ID
        Get.log(
            "[DEBUG] VerificationController initialized with email: $email, name: $name, deviceId: $deviceId");
      }
    });
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

  // Resend OTP
  // Future<void> resendOTP(String phoneNumber) async {
  //   isResending.value = true;
  //   try {
  //     await FirebaseAuth.instance.verifyPhoneNumber(
  //       phoneNumber: phoneNumber,
  //       forceResendingToken: resendToken,
  //       verificationCompleted: (PhoneAuthCredential credential) {},
  //       verificationFailed: (FirebaseAuthException e) {
  //         Fluttertoast.showToast(
  //           msg: "Resend failed: ${e.message}",
  //           backgroundColor: AppColors.errorColor,
  //         );
  //       },
  //       codeSent: (String newVerificationId, int? newResendToken) {
  //         verificationId = newVerificationId;
  //         resendToken = newResendToken;
  //         Fluttertoast.showToast(
  //           msg: "OTP resent to $phoneNumber",
  //           backgroundColor: AppColors.greenColor,
  //         );
  //       },
  //       codeAutoRetrievalTimeout: (String verificationId) {},
  //     );
  //   } catch (e) {
  //     Fluttertoast.showToast(msg: "Error: $e");
  //   } finally {
  //     isResending.value = false;
  //   }
  // }

  // Verify OTP and create the user account
  Future<void> verifyEmailAndCreateAccount() async {
    isLoading.value = true;
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        showToast("No user found. Please sign up first.", isError: true);
        return;
      }

      // Reload user to get the latest verification status
      await user.reload();
      final refreshedUser = FirebaseAuth.instance.currentUser;

      if (refreshedUser != null && refreshedUser.emailVerified) {
        // Email is verified – Save user data to Firestore
        await firestore.collection('users').doc(refreshedUser.uid).set({
          'email': email.value,
          'userId': refreshedUser.uid,
          'username': name.value,
          'password': password.value,
          'deviceId': deviceId.value,
          'referredBy': referralCode.value,
          'createdAt': FieldValue.serverTimestamp(),
          'isUserBanned': false,
          'cashVault': '0',
          'depositAmount': '0',
          'withdrawAmount': '0',
          'reward': '0',
          'refferralProfit': '0',
          'image': '',
        });

        showToast('Account verified & created successfully!');
        Get.offAllNamed(AppRoutes.login);
      } else {
        // Email not verified – Delete unverified user
        await refreshedUser?.delete();
        showToast("Email not verified. Please go back and sigun with original emmail", isError: true);
        Get.offAllNamed(AppRoutes.signUp);
      }
    } catch (e) {
      showToast('Error verifying email: $e', isError: true);
    } finally {
      isLoading.value = false;
    }
  }
}
