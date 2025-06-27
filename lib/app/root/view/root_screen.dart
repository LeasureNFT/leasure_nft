import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leasure_nft/app/admin/screens/admin_main_screen.dart';
import 'package:leasure_nft/app/auth_screens/sign_up_screen.dart';
import 'package:leasure_nft/app/root/controller/root_controller.dart';
import 'package:leasure_nft/app/auth_screens/user_login_screen.dart';
import 'package:leasure_nft/app/users/screens/dashboard/user_dashboard_screen.dart';
import 'package:universal_html/html.dart' as html; // For cookies

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
      // Check if referral code is in cookies or URL
      if (refCode != null) {
        if (!snapshot.hasData) {
          // Not logged in → Show SignUp
          return SignUpScreen();
        } else {
          // Logged in but referral exists → Show custom dialog
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
                      Navigator.of(context).pop(); // Dismiss dialog
                      Get.off(
                        snapshot.data!.email == "admin@gmail.com"
                            ? AdminMainScreen()
                            : UserDashboardScreen(),
                      );
                    },
                    child: Text("Cancel"),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      // Logout current user
                      await FirebaseAuth.instance.signOut();
                      Navigator.of(context).pop(); // Dismiss dialog
                      Get.off(() => SignUpScreen());
                    },
                    child: Text("Continue with New Referral"),
                  ),
                ],
              ),
            );
          });

          // Show loading screen while dialog is visible
          return const Center(child: CircularProgressIndicator());
        }
      }

      // ✅ Default Auth Check
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      if (snapshot.hasData) {
        final User? user = snapshot.data;
        if (user != null && user.email == "admin@gmail.com") {
          return AdminMainScreen();
        } else {
          return UserDashboardScreen();
        }
      } else {
        return UserLoginScreen();
      }
    },
  ),
)

    );
  }
}
