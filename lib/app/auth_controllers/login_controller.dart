import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:universal_html/html.dart' as html;
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

  // Global flag to prevent navigation for banned users
  static bool isUserBanned = false;

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  void clearControllers() {
    emailController.clear();
    passwordController.clear();
  }

  Future<String> getDeviceId() async {
    Get.log("[LOGIN] [DEBUG] Starting device ID retrieval...");
    String deviceId = 'unknown_device';

    if (kIsWeb) {
      Get.log("[LOGIN] [DEBUG] Running on Web platform");
      // SAFELY read deviceId from localStorage and handle type errors
      final stored = html.window.localStorage['deviceId'];
      if (stored is String && stored.isNotEmpty) {
        deviceId = stored;
        Get.log("[LOGIN] [DEBUG] Existing Web Device ID found: $deviceId");
      } else {
        deviceId = const Uuid().v4();
        html.window.localStorage['deviceId'] = deviceId;
        Get.log("[LOGIN] [DEBUG] New Web Device ID generated: $deviceId");
      }
    } else {
      Get.log("[LOGIN] [DEBUG] Running on Native platform");
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      if (GetPlatform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id;
        Get.log("[LOGIN] [DEBUG] Android Device ID: $deviceId");
      } else if (GetPlatform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? 'unknown_ios_device';
        Get.log("[LOGIN] [DEBUG] iOS Device ID: $deviceId");
      } else {
        deviceId = 'unsupported_platform';
        Get.log("[LOGIN] [DEBUG] Unsupported platform detected");
      }
    }

    Get.log("[LOGIN] [DEBUG] Final Device ID: $deviceId");
    return deviceId;
  }

  Future<void> loginUser() async {
    Get.log("[LOGIN] [INFO] ===== LOGIN PROCESS STARTED =====");
    isLoading.value = true;
    try {
      final email = emailController.text.trim();
      final password = passwordController.text.trim();
      Get.log("[LOGIN] [DEBUG] Email: $email");
      Get.log("[LOGIN] [DEBUG] Password length: ${password.length}");

      if (email.isEmpty || password.isEmpty) {
        Get.log("[LOGIN] [ERROR] Email or password is empty");
        showToast('Email and password are required.', isError: true);
        return;
      }

      // Firebase Auth
      UserCredential userCredential;
      try {
        Get.log("[LOGIN] [DEBUG] Attempting Firebase sign in...");
        userCredential = await auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        Get.log("[LOGIN] [SUCCESS] Firebase authentication successful!");
      } on FirebaseAuthException catch (e) {
        Get.log(
            "[LOGIN] [ERROR] Firebase Auth Exception: ${e.code} - ${e.message}");
        showToast('Login failed: ${e.message}', isError: true);
        return;
      }

      final user = userCredential.user;
      if (user == null) {
        Get.log("[LOGIN] [ERROR] User object is null after authentication");
        showToast('Login failed. Please try again.', isError: true);
        return;
      }
      Get.log("[LOGIN] [DEBUG] User UID: ${user.uid}");
      Get.log("[LOGIN] [DEBUG] User email: ${user.email}");

      // Admin check: skip Firestore for admin
      if (user.email == "leasurenft.suport@gmail.com") {
        Get.log(
            "[LOGIN] [SUCCESS] Admin user detected. Skipping Firestore check.");
        AppPrefernces.setAdmin("admin");
        showToast("Admin login successful!");
        Get.offAllNamed(AppRoutes.adminDashboard);
        return;
      }

      // Firestore User Collection Check (only for normal users)
      Get.log("[LOGIN] [DEBUG] Fetching user document from Firestore...");
      final userDoc = await firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        Get.log("[LOGIN] [ERROR] User document does not exist in Firestore");
        showToast('User not found in database.', isError: true);
        await auth.signOut(); // Sign out user to clear session
        return;
      }
      final data = userDoc.data();
      if (data == null) {
        Get.log("[LOGIN] [ERROR] User data is null from Firestore");
        showToast('User data is corrupted.', isError: true);
        await auth.signOut(); // Clean session
        return;
      }
      Get.log("[LOGIN] [DEBUG] User data keys: ${data.keys.toList()}");

      // Banned check
      final isUserBanned = data['isUserBanned'] == true;
      Get.log(
          "[LOGIN] [DEBUG] isUserBanned value: ${data['isUserBanned']} (Type: " +
              "${data['isUserBanned']?.runtimeType})");
      if (isUserBanned) {
        Get.log("[LOGIN] [ERROR] User is banned. Blocking login.");
        showToast('Your account has been banned. Please contact admin.',
            isError: true);
        await auth.signOut(); // Sign out after ban
        return;
      }

      /// ✅ If everything is fine, navigate to Dashboard
      Get.log("[LOGIN] [SUCCESS] Login complete. Navigating to dashboard...");
      showToast('Login successful!');
      Get.offAllNamed(AppRoutes.userDashboard); // Navigate only after success
    } catch (e, stackTrace) {
      Get.log("[LOGIN] [ERROR] Exception: $e");
      Get.log("[LOGIN] [ERROR] StackTrace: $stackTrace");
      showToast('Unexpected error occurred. Please try again.', isError: true);
    } finally {
      isLoading.value = false;
      Get.log("[LOGIN] [INFO] ===== LOGIN PROCESS ENDED =====");
    }
  }
}
