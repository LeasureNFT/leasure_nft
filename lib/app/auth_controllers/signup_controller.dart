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

  Future<void> signUpUser() async {
    isloding.value = true;
    try {
      if (!await canCreateAccount()) {
        isloding.value = false;
        showToast("You cannot create more than 2 accounts from this device",
            isError: true);
        return;
      }

      // Create user with email and password
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim());

      // Send email verification

      final refreshedUser = FirebaseAuth.instance.currentUser;

      // Email is verified – Save user data to Firestore
      await firestore.collection('users').doc(refreshedUser!.uid).set({
        'email': emailController.text.trim(),
        'userId': refreshedUser.uid,
        'username': nameController.text.trim(),
        'password': passwordController.text.trim(),
        'deviceId': await getDeviceId(),
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
      });

      showToast('Account verified & created successfully!');
      Get.offAllNamed(AppRoutes.login);
    } on FirebaseAuthException catch (e) {
      showToast("Signup failed: ${e.message}", isError: true);
      Get.log("[ERROR] Firebase Auth Exception: ${e.message}");
    } catch (e) {
      showToast("Error signing up: $e", isError: true);
      Get.log("[ERROR] General Exception: $e");
    } finally {
      isloding.value = false;
    }
  }
}
