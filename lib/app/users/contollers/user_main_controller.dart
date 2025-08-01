import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:leasure_nft/app/users/models/user_model.dart';
import 'package:leasure_nft/app/auth_controllers/login_controller.dart';

enum DashboardTab { home, deposit, task, withdraw, network, profile }

class UserDashboardController extends GetxController {
  Rx<UserModel?> userModel = Rx<UserModel?>(null); // 🔥 Reactive UserModel
  RxDouble pendingAmount = 0.0.obs;
  final RxDouble todayProfit = 0.0.obs;
  final RxDouble pendingWithdraw = 0.0.obs;
  RxDouble totalProfit = 0.0.obs;
  final RxInt totalRefferral = 0.obs;
  final currentIndex = DashboardTab.home.index.obs;
  final isloading = false.obs;
  final refferralProfit = 0.0.obs;
  late PageController pageController;

  void changePage(int index) {
    currentIndex.value = index;
  }

  @override
  void onInit() {
    super.onInit();

    // Check if user is banned before initializing dashboard
    checkUserBanStatus();

    pageController = PageController(initialPage: currentIndex.value);
    if (pageController.hasClients) {
      pageController.jumpToPage(currentIndex.value);
    }
    ever(currentIndex, (_) {
      if (pageController.hasClients) {
        pageController.jumpToPage(currentIndex.value);
      }
    });

    isloading.value = true;

    listenToUserData();
    listenToPendingAmount();
    getTotalRefferral();

    updateReferralProfit();

    isloading.value = false;
  }

  void checkUserBanStatus() async {
    try {
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        Get.log("[DASHBOARD] [ERROR] No user logged in, redirecting to login");
        Get.offAllNamed('/login');
        return;
      }

      // Check global banned flag first
      if (LoginController.isUserBanned) {
        Get.log(
            "[DASHBOARD] [ERROR] Global banned flag is true, redirecting to login");
        Get.offAllNamed('/login');
        return;
      }

      // Double-check with Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>?;
        final isBanned = data?['isUserBanned'] ?? false;

        if (isBanned == true || isBanned == 'true' || isBanned == 1) {
          Get.log(
              "[DASHBOARD] [ERROR] User is banned in Firestore, redirecting to login");
          await FirebaseAuth.instance.signOut();
          Get.offAllNamed('/login');
          return;
        }
      }

      Get.log("[DASHBOARD] [SUCCESS] User ban check passed");
    } catch (e) {
      Get.log("[DASHBOARD] [ERROR] Error checking user ban status: $e");
      Get.offAllNamed('/login');
    }
  }

  void getTotalRefferral() async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      print("❌ No user logged in");
      return;
    }

    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('refferredBy', isEqualTo: userId)
          .get();

      totalRefferral.value = querySnapshot.docs.length;
      update();
      print("✅ Total tatal refferral: Rs $totalRefferral");
    } catch (e) {
      print("❌ Error fetching total refferral: $e");
    }
  }

  void listenToUserData() {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots()
        .listen((userDoc) {
      if (userDoc.exists && userDoc.data() != null) {
        userModel.value = UserModel.fromMap(userDoc.data());
        print("✅ Real-time User Data Updated: ${userModel.value?.username}");
      }
    });
  }

  void listenToPendingAmount() {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    FirebaseFirestore.instance
        .collection('payments')
        .where('userId', isEqualTo: userId)
        .where("transactionType", isEqualTo: "Deposit")
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((querySnapshot) {
      double totalAmount = querySnapshot.docs.fold(0.0, (sum, doc) {
        return sum + double.parse(doc['amount'] ?? '0');
      });

      pendingAmount.value = totalAmount;
      print("✅ Real-time Pending Amount: Rs $totalAmount");
    });
    FirebaseFirestore.instance
        .collection('payments')
        .where('userId', isEqualTo: userId)
        .where('transactionType', isEqualTo: 'Withdraw')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((querySnapshot) {
      double totalWithdraw = querySnapshot.docs.fold(0.0, (sum, doc) {
        return sum + double.tryParse(doc['amount'].toString())!;
      });

      pendingWithdraw.value = totalWithdraw;
      print("📤 Real-time Pending Withdraw Amount: Rs $totalWithdraw");
    });
  }

  Future<void> updateReferralProfit() async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    FirebaseFirestore firestore = FirebaseFirestore.instance;
    DocumentReference userRef = firestore.collection('users').doc(userId);

    DocumentSnapshot userDoc = await userRef.get();
    if (!userDoc.exists) return;

    double totalProfit = 0.0;

    // Get all Level 1 referrals
    QuerySnapshot level1Snapshot = await firestore
        .collection('users')
        .where('refferredBy', isEqualTo: userId)
        .get();

    for (var level1Doc in level1Snapshot.docs) {
      double level1Profit =
          (double.tryParse(level1Doc['refferralProfit'].toString()) ?? 0.0) *
              0.06;
      totalProfit += level1Profit;

      QuerySnapshot level2Snapshot = await firestore
          .collection('users')
          .where('refferredBy', isEqualTo: level1Doc.id)
          .get();

      for (var level2Doc in level2Snapshot.docs) {
        double level2Profit =
            (double.tryParse(level2Doc['refferralProfit'].toString()) ?? 0.0) *
                0.04;
        totalProfit += level2Profit;

        QuerySnapshot level3Snapshot = await firestore
            .collection('users')
            .where('refferredBy', isEqualTo: level2Doc.id)
            .get();

        for (var level3Doc in level3Snapshot.docs) {
          double level3Profit =
              (double.tryParse(level3Doc['refferralProfit'].toString()) ??
                      0.0) *
                  0.02;
          totalProfit += level3Profit;
        }
      }
    }

    // **Calculate the difference to avoid duplicate addition**

    await userRef.update({
      "cashVault": FieldValue.increment(totalProfit),
      // Store the latest calculated profit
    });

    refferralProfit.value = totalProfit;
    print("✅ Referral Profit Updated: Rs $totalProfit");
  }
}
