import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:leasure_nft/app/core/widgets/toas_message.dart';
import 'package:leasure_nft/app/routes/app_routes.dart';
import 'package:universal_html/html.dart' as html;
import 'package:uuid/uuid.dart';

class SignupController extends GetxController {
  var isObsure = true.obs;
  var isloding = false.obs;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  final phoneNumberController = TextEditingController();
  final refferalCodeController = TextEditingController();
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final GetStorage storage = GetStorage();

  @override
  void onInit() {
    Get.log("[SIGNUP] [INFO] ===== SIGNUP CONTROLLER INITIALIZED =====");
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
    Get.log("[SIGNUP] [DEBUG] Starting device ID retrieval...");
    String deviceId = 'unknown_device';

    if (kIsWeb) {
      Get.log("[SIGNUP] [DEBUG] Running on Web platform");
      // SAFELY read deviceId from localStorage and handle type errors
      final stored = html.window.localStorage['deviceId'];
      if (stored is String && stored.isNotEmpty) {
        deviceId = stored;
        Get.log("[SIGNUP] [DEBUG] Existing Web Device ID found: $deviceId");
      } else {
        deviceId = const Uuid().v4();
        html.window.localStorage['deviceId'] = deviceId;
        Get.log("[SIGNUP] [DEBUG] New Web Device ID generated: $deviceId");
      }
    } else {
      Get.log("[SIGNUP] [DEBUG] Running on Native platform");
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      if (GetPlatform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id;
        Get.log("[SIGNUP] [DEBUG] Android Device ID: $deviceId");
      } else if (GetPlatform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? 'unknown_ios_device';
        Get.log("[SIGNUP] [DEBUG] iOS Device ID: $deviceId");
      } else {
        deviceId = 'unsupported_platform';
        Get.log("[SIGNUP] [DEBUG] Unsupported platform detected");
      }
    }

    Get.log("[SIGNUP] [DEBUG] Final Device ID: $deviceId");
    return deviceId;
  }

  void getReferralFromCookie() {
    Get.log("[SIGNUP] [DEBUG] Checking for referral code in cookies...");
    try {
      if (kIsWeb) {
        Get.log("[SIGNUP] [DEBUG] Running on Web, checking cookies...");
        final rawCookies = html.document.cookie;
        if (rawCookies == null || rawCookies.isEmpty) {
          Get.log("[SIGNUP] [INFO] No cookies found.");
          return;
        }

        Get.log("[SIGNUP] [DEBUG] Raw cookies: $rawCookies");
        final cookies = rawCookies.split('; ');
        for (var cookie in cookies) {
          final parts = cookie.split('=');
          if (parts.length == 2) {
            final key = parts[0].trim();
            final value = parts[1].trim();
            Get.log("[SIGNUP] [DEBUG] Cookie - Key: $key, Value: $value");
            if (key == 'ref') {
              refferalCodeController.text = value;
              Get.log(
                  "[SIGNUP] [SUCCESS] Referral code found in cookie: $value");
              return;
            }
          }
        }

        Get.log("[SIGNUP] [INFO] 'ref' cookie not found.");
      } else {
        Get.log("[SIGNUP] [INFO] Not running on Web. Skipping cookie check.");
      }
    } catch (e, stackTrace) {
      Get.log("[SIGNUP] [ERROR] Failed to get referral from cookie: $e");
      Get.log("[SIGNUP] [ERROR] Stack trace: $stackTrace");
    }
  }

  Future<bool> canCreateAccount() async {
    Get.log("[SIGNUP] [DEBUG] ===== CHECKING IF ACCOUNT CAN BE CREATED =====");
    String deviceId = await getDeviceId();

    if (deviceId.isEmpty ||
        deviceId == 'unknown_device' ||
        deviceId == 'unsupported_platform') {
      Get.log(
          "[SIGNUP] [ERROR] Invalid or empty device ID. Skipping Firestore check.");
      Get.log("[SIGNUP] [DEBUG] Device ID: $deviceId");
      return false;
    }

    try {
      Get.log("[SIGNUP] [DEBUG] Checking device ID in Firestore: $deviceId");
      Get.log(
          "[SIGNUP] [DEBUG] Querying users collection for deviceId: $deviceId");

      final users = await firestore
          .collection('users')
          .where('deviceId', isEqualTo: deviceId)
          .get();

      Get.log("[SIGNUP] [SUCCESS] Firestore query completed");
      Get.log(
          "[SIGNUP] [DEBUG] Accounts found with this device ID: ${users.docs.length}");

      final canCreate = users.docs.length < 2;
      Get.log(
          "[SIGNUP] [DEBUG] Can create account: $canCreate (max 2 accounts per device)");

      return canCreate;
    } catch (e, stackTrace) {
      Get.log(
          "[SIGNUP] [ERROR] Firestore query failed in canCreateAccount: $e");
      Get.log("[SIGNUP] [ERROR] Stack trace: $stackTrace");
      return false;
    }
  }

  Future<void> signUpUser() async {
    Get.log("[SIGNUP] [INFO] ===== SIGNUP PROCESS STARTED =====");
    Get.log("[SIGNUP] [DEBUG] Form data:");
    Get.log("[SIGNUP] [DEBUG] - Email: ${emailController.text.trim()}");
    Get.log("[SIGNUP] [DEBUG] - Name: ${nameController.text.trim()}");
    Get.log(
        "[SIGNUP] [DEBUG] - Password length: ${passwordController.text.length}");
    Get.log(
        "[SIGNUP] [DEBUG] - Referral code: ${refferalCodeController.text.trim()}");

    isloding.value = true;

    try {
      // Step 1: Check if account can be created
      Get.log("[SIGNUP] [DEBUG] Step 1: Checking if account can be created...");
      if (!await canCreateAccount()) {
        Get.log(
            "[SIGNUP] [ERROR] Account creation blocked - device limit reached");
        isloding.value = false;
        showToast("You cannot create more than 2 accounts from this device",
            isError: true);
        return;
      }
      Get.log("[SIGNUP] [SUCCESS] Account creation allowed");

      // Step 2: Create user with Firebase Auth
      Get.log("[SIGNUP] [DEBUG] Step 2: Creating user with Firebase Auth...");
      Get.log("[SIGNUP] [DEBUG] Email: ${emailController.text.trim()}");
      Get.log(
          "[SIGNUP] [DEBUG] Password length: ${passwordController.text.length}");

      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
              email: emailController.text.trim(),
              password: passwordController.text.trim());

      Get.log("[SIGNUP] [SUCCESS] Firebase Auth user created successfully!");
      Get.log("[SIGNUP] [DEBUG] User UID: ${userCredential.user?.uid}");
      Get.log("[SIGNUP] [DEBUG] User email: ${userCredential.user?.email}");
      Get.log(
          "[SIGNUP] [DEBUG] Email verified: ${userCredential.user?.emailVerified}");

      // Step 3: Get refreshed user
      Get.log("[SIGNUP] [DEBUG] Step 3: Getting refreshed user...");
      final refreshedUser = FirebaseAuth.instance.currentUser;

      if (refreshedUser == null) {
        Get.log("[SIGNUP] [ERROR] Refreshed user is null");
        throw Exception("Failed to get refreshed user");
      }

      Get.log("[SIGNUP] [SUCCESS] Refreshed user obtained");
      Get.log("[SIGNUP] [DEBUG] Refreshed user UID: ${refreshedUser.uid}");

      // Step 4: Get device ID
      Get.log("[SIGNUP] [DEBUG] Step 4: Getting device ID...");
      final deviceId = await getDeviceId();
      Get.log("[SIGNUP] [DEBUG] Device ID for Firestore: $deviceId");

      // Step 5: Save user data to Firestore
      Get.log("[SIGNUP] [DEBUG] Step 5: Saving user data to Firestore...");
      Get.log("[SIGNUP] [DEBUG] Document path: users/${refreshedUser.uid}");

      final userData = {
        'email': emailController.text.trim(),
        'userId': refreshedUser.uid,
        'username': nameController.text.trim(),
        'password': passwordController.text.trim(),
        'deviceId': deviceId,
        'referredBy': refferalCodeController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'isUserBanned': false,
        'cashVault': '0',
        "todayProfit": '0',
        "lastReferralProfit": '0',
        'updatedAt': FieldValue.serverTimestamp(),
        'depositAmount': '0',
        'withdrawAmount': '0',
        'reward': '0',
        'refferralProfit': '0',
        'image': '',
      };

      Get.log("[SIGNUP] [DEBUG] User data to save:");
      userData.forEach((key, value) {
        Get.log("[SIGNUP] [DEBUG] - $key: $value");
      });

      await firestore.collection('users').doc(refreshedUser.uid).set(userData);

      Get.log("[SIGNUP] [SUCCESS] User data saved to Firestore successfully!");

      // Step 6: Signup completed
      Get.log(
          "[SIGNUP] [SUCCESS] ===== SIGNUP PROCESS COMPLETED SUCCESSFULLY =====");
      Get.log("[SIGNUP] [DEBUG] Final user details:");
      Get.log("[SIGNUP] [DEBUG] - UID: ${refreshedUser.uid}");
      Get.log("[SIGNUP] [DEBUG] - Email: ${refreshedUser.email}");
      Get.log("[SIGNUP] [DEBUG] - Username: ${nameController.text.trim()}");
      Get.log("[SIGNUP] [DEBUG] - Device ID: $deviceId");
      Get.log(
          "[SIGNUP] [DEBUG] - Referred by: ${refferalCodeController.text.trim()}");

      showToast('Account verified & created successfully!');
      Get.log("[SIGNUP] [INFO] Redirecting to login screen...");
      Get.offAllNamed(AppRoutes.login);
    } on FirebaseAuthException catch (e) {
      Get.log("[SIGNUP] [ERROR] ===== FIREBASE AUTH EXCEPTION =====");
      Get.log("[SIGNUP] [ERROR] Error code: ${e.code}");
      Get.log("[SIGNUP] [ERROR] Error message: ${e.message}");
      Get.log("[SIGNUP] [ERROR] Error details: ${e.toString()}");

      if (e.code == 'weak-password') {
        Get.log("[SIGNUP] [ERROR] Password is too weak");
        showToast("Password is too weak. Please use a stronger password.",
            isError: true);
      } else if (e.code == 'email-already-in-use') {
        Get.log("[SIGNUP] [ERROR] Email is already in use");
        showToast("Email is already registered. Please use a different email.",
            isError: true);
      } else if (e.code == 'invalid-email') {
        Get.log("[SIGNUP] [ERROR] Invalid email format");
        showToast("Invalid email format. Please enter a valid email.",
            isError: true);
      } else if (e.code == 'operation-not-allowed') {
        Get.log("[SIGNUP] [ERROR] Email/password accounts not enabled");
        showToast(
            "Email/password accounts are not enabled. Please contact support.",
            isError: true);
      } else {
        Get.log("[SIGNUP] [ERROR] Unknown Firebase Auth error");
        showToast("Signup failed: ${e.message}", isError: true);
      }
    } catch (e, stackTrace) {
      Get.log("[SIGNUP] [ERROR] ===== GENERAL EXCEPTION =====");
      Get.log("[SIGNUP] [ERROR] Exception: $e");
      Get.log("[SIGNUP] [ERROR] Stack trace: $stackTrace");
      showToast("Error signing up: $e", isError: true);
    } finally {
      Get.log("[SIGNUP] [DEBUG] Setting loading to false");
      isloding.value = false;
      Get.log("[SIGNUP] [INFO] ===== SIGNUP PROCESS ENDED =====");
    }
  }
}
