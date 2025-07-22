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
        isLoading.value = false;
      }, onError: (e) {
        isLoading.value = false;
        Get.snackbar("Error", "Failed to fetch users: $e");
      });
    } catch (e) {
      isLoading.value = false;
      Get.snackbar("Error", "Failed to fetch users: $e");
    }
  }

  Future<void> calculateTotalRevenue() async {
    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;

      // 1️⃣ Get total number of users
      QuerySnapshot usersSnapshot = await firestore.collection('users').get();
      int totalUsers = usersSnapshot.size;

      // 2️⃣ Get total tasks assigned to each user
      QuerySnapshot tasksSnapshot = await firestore.collection('tasks').get();
      int tasksPerUser =
          tasksSnapshot.size; // Assuming all users get equal tasks

      // 3️⃣ Calculate total profit from task_details
      QuerySnapshot taskDetailsSnapshot =
          await firestore.collection('task_details').get();

      double totalProfit = 0.0;

      for (var doc in taskDetailsSnapshot.docs) {
        double profit = 0.0;
        final profitRaw = doc['profit'];
        if (profitRaw is int) {
          profit = double.parse(profitRaw.toString());
        } else if (profitRaw is double) {
          profit = profitRaw;
        } else if (profitRaw is String) {
          profit = double.tryParse(profitRaw) ?? 0.0;
        }
        totalProfit += profit;
      }

      // 4️⃣ Calculate Total Revenue Formula
      double totalRevenueAm =
          totalUsers * tasksPerUser * (totalProfit / taskDetailsSnapshot.size);

      print("Total Revenue: $totalRevenueAm");
      totalRevenue.value = totalRevenueAm;
    } catch (e) {
      print("Error calculating total revenue: $e");
    }
  }
}
