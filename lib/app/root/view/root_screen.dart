import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leasure_nft/app/admin/screens/admin_main_screen.dart';
import 'package:leasure_nft/app/auth_screens/sign_up_screen.dart';
import 'package:leasure_nft/app/auth_screens/user_login_screen.dart';
import 'package:leasure_nft/app/root/controller/root_controller.dart';
import 'package:leasure_nft/app/users/screens/dashboard/user_dashboard_screen.dart';
import 'package:universal_html/html.dart' as html;

class RootScreen extends GetView<RootController> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  RootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ Get `ref` from URL
    final String? refCode = Uri.base.queryParameters['ref'];

    // ✅ Save `ref` to cookies
    if (refCode != null) {
      html.window.document.cookie = "ref=$refCode";
    }

    return GetBuilder<RootController>(
      init: RootController(),
      builder: (controller) => Scaffold(
        key: scaffoldKey,
        resizeToAvoidBottomInset: false,
        body: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            // ⏳ Show loading while checking auth
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // ✅ Referral logic
            if (refCode != null) {
              if (!snapshot.hasData) {
                return SignUpScreen();
              } else {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => AlertDialog(
                      title: Text("Referral Code Detected"),
                      content: Text(
                        "A referral code is detected.\n\n"
                        "You are already logged in as ${snapshot.data?.email}.\n"
                        "Do you want to log out and sign up with the new referral code?",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            Get.off(
                              snapshot.data!.email ==
                                      "leasurenft.suport@gmail.com"
                                  ? AdminMainScreen()
                                  : UserDashboardScreen(),
                            );
                          },
                          child: Text("Cancel"),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            await FirebaseAuth.instance.signOut();
                            Navigator.of(context).pop();
                            Get.off(() => SignUpScreen());
                          },
                          child: Text("Continue with New Referral"),
                        ),
                      ],
                    ),
                  );
                });

                return const Center(child: CircularProgressIndicator());
              }
            }

            // ✅ Authenticated
            if (snapshot.hasData) {
              final User user = snapshot.data!;

              // ✅ Admin user check
              if (user.email == "leasurenft.suport@gmail.com") {
                return AdminMainScreen();
              }

              // ✅ Check if user is banned in Firestore
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .get(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snap.hasData || !snap.data!.exists) {
                    FirebaseAuth.instance.signOut();
                    return UserLoginScreen();
                  }

                  final data = snap.data!.data() as Map<String, dynamic>;

                  if (data['isUserBanned'] == true) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Get.showSnackbar(
                        GetSnackBar(
                          title: "Account Banned",
                          message:
                              "Your account has been banned. Please contact support.",
                          duration: const Duration(seconds: 4),
                          backgroundColor: Colors.red,
                        ),
                      );
                    });

                    FirebaseAuth.instance.signOut();
                    return UserLoginScreen();
                  }

                  // ✅ All checks passed — Show dashboard
                  return UserDashboardScreen();
                },
              );
            }

            // ❌ Not logged in
            return UserLoginScreen();
          },
        ),
      ),
    );
  }
}
