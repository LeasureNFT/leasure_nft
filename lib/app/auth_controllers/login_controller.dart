import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leasure_nft/app/core/widgets/toas_message.dart';
import 'package:leasure_nft/app/data/app_prefernces.dart';
import 'package:leasure_nft/app/routes/app_routes.dart';

class LoginController extends GetxController {
  TextEditingController passwordController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final obscurePassword = true.obs;
  final isLoading = false.obs;

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  // Future<String> getDeviceId() async {
  //   DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  //   String deviceId;

  //   if (GetPlatform.isAndroid) {
  //     AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
  //     deviceId = androidInfo.id;
  //     Get.log("[DEBUG] Android Device ID: $deviceId");
  //   } else if (GetPlatform.isIOS) {
  //     IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
  //     deviceId = iosInfo.identifierForVendor ?? 'unknown_ios_device';
  //     Get.log("[DEBUG] iOS Device ID: $deviceId");
  //   } else if (GetPlatform.isWeb) {
  //     WebBrowserInfo webInfo = await deviceInfo.webBrowserInfo;
  //     deviceId = webInfo.userAgent ?? 'unknown_web_device';
  //     Get.log("[DEBUG] Web Device ID: $deviceId");
  //   } else {
  //     deviceId = 'unknown_device';
  //     Get.log("[DEBUG] Fallback Device ID: $deviceId");
  //   }

  //   return deviceId;
  // }

  void clearControllers() {
    emailController.clear();
    passwordController.clear();
  }

  Future<void> loginUser() async {
    isLoading.value = true;

    try {
      // Step 1: Get current device ID
      showToast("Fetching device ID...");
      // final currentDeviceId = await getDeviceId();
      // if (currentDeviceId.isEmpty) {
      //   showToast('Device ID retrieval failed', isError: true);
      //   return;
      // }

      // Step 2: Authenticate user
      final email = emailController.text.trim();
      final password = passwordController.text.trim();
      if (email.isEmpty || password.isEmpty) {
        showToast('Email and password cannot be empty', isError: true);
        return;
      }

      UserCredential userCredential = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        showToast('User authentication failed', isError: true);
        return;
      }

      // Step 3: Check for admin login
      if (user.email == "admin@gmail.com") {
        AppPrefernces.setAdmin("admin");
        showToast("Admin logged in successfully");
        Get.offAllNamed(AppRoutes.adminDashboard);
        return;
      }

      // Step 4: Fetch user document
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        showToast('User not found in database', isError: true);
        return;
      }

      final data = userDoc.data();
      final isBanned = data?['isUserBanned'] ?? false;
      // final storedDeviceId = data?['deviceId'];

      // Step 5: Banned user check
      if (isBanned) {
        showToast(
          'Your account has been banned. Please contact admin.',
          isError: true,
        );
        return;
      }

      // Step 6: Device restriction logic
      // if (storedDeviceId == null) {
      //   // Save current device ID if not already set
      //   await FirebaseFirestore.instance
      //       .collection('users')
      //       .doc(user.uid)
      //       .update({'deviceId': currentDeviceId});
      // } else if (storedDeviceId != currentDeviceId) {
      //   showToast(
      //     'Your account is already logged in on another device.',
      //     isError: true,
      //   );
      //   return;
      // }

      // Step 7: Login successful
      showToast('Login successful');
      Get.offAllNamed(AppRoutes.userDashboard);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        showToast('Invalid Password', isError: true);
      } else if (e.code == 'user-not-found') {
        showToast('User not found', isError: true);
      } else {
        showToast('Authentication error: ${e.message}', isError: true);
      }
    } catch (e) {
      showToast('Something went wrong: $e', isError: true);
    } finally {
      isLoading.value = false;
    }
  }
}
