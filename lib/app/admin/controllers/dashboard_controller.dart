import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'dart:async';

class DashboardController extends GetxController {
  final auth = FirebaseAuth.instance;
  final totalRevenue = 0.0.obs;

  RxList<Map<String, dynamic>> usersList = <Map<String, dynamic>>[].obs;
  RxInt totalUsers = 0.obs; // ✅ Total Users Count
  RxInt totalBannedUsers = 0.obs;
  final isLoading = true.obs;

  StreamSubscription<QuerySnapshot>? _usersSubscription;

  @override
  void onInit() {
    super.onInit();
    Get.log("[DASHBOARD] [INFO] DashboardController initialized");
    getUsers();
    calculateTotalRevenue(); // ✅ Automatically fetch users on screen load
  }

  @override
  void onClose() {
    _usersSubscription?.cancel();
    super.onClose();
  }

  void logout() async {
    await auth.signOut();
    Get.offAllNamed('/login');
  }

  // 🔹 Firestore سے تمام Users حاصل کرنے کا Function
  void getUsers() {
    try {
      Get.log("[DASHBOARD] [INFO] Fetching users...");
      isLoading.value = true;
      _usersSubscription?.cancel();
      _usersSubscription = FirebaseFirestore.instance
          .collection('users')
          // Limit to 50 users for efficiency; adjust as needed
          .snapshots()
          .listen((snapshot) {
        final updatedUsers = snapshot.docs.map((doc) => doc.data()).toList();

        // ✅ Efficiently update the observable list
        usersList.assignAll(updatedUsers);

        // ✅ Total Users Count
        totalUsers.value = updatedUsers.length;

        // ✅ Count Banned Users (isUserBanned == true)
        totalBannedUsers.value =
            updatedUsers.where((user) => user['isUserBanned'] == true).length;

        Get.log(
            "[DASHBOARD] [SUCCESS] Users loaded - Total: ${totalUsers.value}, Banned: ${totalBannedUsers.value}");
        isLoading.value = false;
      }, onError: (e) {
        Get.log("[DASHBOARD] [ERROR] Failed to fetch users: $e");
        isLoading.value = false;
        Get.snackbar("Error", "Failed to fetch users: $e");
      });
    } catch (e) {
      Get.log("[DASHBOARD] [ERROR] Exception in getUsers: $e");
      isLoading.value = false;
      Get.snackbar("Error", "Failed to fetch users: $e");
    }
  }

  Future<void> calculateTotalRevenue() async {
    try {
      Get.log(
          "[DASHBOARD] [INFO] Calculating net revenue (deposits - withdrawals)...");
      FirebaseFirestore firestore = FirebaseFirestore.instance;

      // 1️⃣ Get total number of users
      QuerySnapshot usersSnapshot = await firestore.collection('users').get();
      int totalUsersCount = usersSnapshot.size;
      Get.log("[DASHBOARD] [DEBUG] Total users: $totalUsersCount");

      // 2️⃣ Calculate total deposits (completed)
      double totalDeposits = 0.0;
      QuerySnapshot depositsSnapshot = await firestore
          .collection('payments')
          .where('transactionType', isEqualTo: 'Deposit')
          .where('status', isEqualTo: 'completed')
          .get();

      for (var doc in depositsSnapshot.docs) {
        Map<String, dynamic> paymentData =
            Map<String, dynamic>.from(doc.data() as Map);
        double amount = 0.0;
        final amountRaw = paymentData['amount'];

        if (amountRaw is int) {
          amount = amountRaw.toDouble();
        } else if (amountRaw is double) {
          amount = amountRaw;
        } else if (amountRaw is String) {
          amount = double.tryParse(amountRaw) ?? 0.0;
        }
        totalDeposits += amount;
        Get.log(
            "[DASHBOARD] [DEBUG] Deposit ${doc.id}: amount=$amount, total=$totalDeposits");
      }

      // 3️⃣ Calculate total withdrawals (completed)
      double totalWithdrawals = 0.0;
      QuerySnapshot withdrawalsSnapshot = await firestore
          .collection('payments')
          .where('transactionType', isEqualTo: 'Withdraw')
          .where('status', isEqualTo: 'completed')
          .get();

      for (var doc in withdrawalsSnapshot.docs) {
        Map<String, dynamic> paymentData =
            Map<String, dynamic>.from(doc.data() as Map);
        double amount = 0.0;
        final amountRaw = paymentData['amount'];

        if (amountRaw is int) {
          amount = amountRaw.toDouble();
        } else if (amountRaw is double) {
          amount = amountRaw;
        } else if (amountRaw is String) {
          amount = double.tryParse(amountRaw) ?? 0.0;
        }
        totalWithdrawals += amount;
        Get.log(
            "[DASHBOARD] [DEBUG] Withdrawal ${doc.id}: amount=$amount, total=$totalWithdrawals");
      }

      // 4️⃣ Calculate NET REVENUE (Deposits - Withdrawals)
      double netRevenue = totalDeposits - totalWithdrawals;

      Get.log("[DASHBOARD] [DEBUG] Revenue breakdown:");
      Get.log(
          "[DASHBOARD] [DEBUG] - Total completed deposits: ${depositsSnapshot.size}");
      Get.log("[DASHBOARD] [DEBUG] - Total deposits amount: Rs.$totalDeposits");
      Get.log(
          "[DASHBOARD] [DEBUG] - Total completed withdrawals: ${withdrawalsSnapshot.size}");
      Get.log(
          "[DASHBOARD] [DEBUG] - Total withdrawals amount: Rs.$totalWithdrawals");
      Get.log(
          "[DASHBOARD] [DEBUG] - NET REVENUE: Rs.$netRevenue (Deposits - Withdrawals)");

      // Set the net revenue
      Get.log("[DASHBOARD] [SUCCESS] Net revenue calculated: Rs.$netRevenue");
      totalRevenue.value = netRevenue;
    } catch (e) {
      Get.log("[DASHBOARD] [ERROR] Error calculating net revenue: $e");
      totalRevenue.value = 0.0;
    }
  }
}
