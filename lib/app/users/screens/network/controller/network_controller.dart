import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leasure_nft/app/core/widgets/toas_message.dart';

class NetworkController extends GetxController {
  var referralTree =
      <Map<String, dynamic>>[].obs; // Store referrals as list of maps
  String? userId;
  final isloading = false.obs;
  final level1 = <Map<String, dynamic>>[].obs;
  final level2 = <Map<String, dynamic>>[].obs;
  final level3 = <Map<String, dynamic>>[].obs;
  final totalProfit = 0.0.obs;
  final level1Profit = 0.0.obs;
  final level2Profit = 0.0.obs;
  final level3Profit = 0.0.obs;

  final currentTab = 0.obs;
  void changeTab(int index) {
    currentTab.value = index;
  }

  @override
  void onInit() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await fetchReferrals();
      await updateReferralProfit();
    });
    super.onInit();
  }

  Future<void> fetchReferrals() async {
    try {
      isloading.value = true;
      final userId = FirebaseAuth.instance.currentUser?.uid;
      level1.clear();
      level2.clear();
      level3.clear();

      QuerySnapshot level1Snap = await FirebaseFirestore.instance
          .collection('users')
          .where('referredBy', isEqualTo: userId)
          .get();

      for (var doc1 in level1Snap.docs) {
        final user1 = {
          "id": doc1.id,
          "email": doc1["email"] ?? "Unknown",
          "name": doc1["username"] ?? "Unknown",
          "totalProfit": doc1["refferralProfit"] ?? 0,
        };
        level1.add(user1);

        QuerySnapshot level2Snap = await FirebaseFirestore.instance
            .collection('users')
            .where('referredBy', isEqualTo: doc1.id)
            .get();

        for (var doc2 in level2Snap.docs) {
          final user2 = {
            "id": doc2.id,
            "email": doc2["email"] ?? "Unknown",
            "name": doc2["username"] ?? "Unknown",
            "totalProfit": doc2["refferralProfit"] ?? 0,
          };
          level2.add(user2);

          QuerySnapshot level3Snap = await FirebaseFirestore.instance
              .collection('users')
              .where('referredBy', isEqualTo: doc2.id)
              .get();

          for (var doc3 in level3Snap.docs) {
            final user3 = {
              "id": doc3.id,
              "email": doc3["email"] ?? "Unknown",
              "name": doc3["username"] ?? "Unknown",
              "totalProfit": doc3["refferralProfit"] ?? 0,
            };
            level3.add(user3);
          }
        }
      }
    } catch (e) {
      Get.log("Error fetching referrals: $e");
      showToast("Error fetching referrals: $e", isError: true);
    } finally {
      isloading.value = false;
    }
  }

  Future<void> updateReferralProfit() async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    FirebaseFirestore firestore = FirebaseFirestore.instance;
    DocumentReference userRef = firestore.collection('users').doc(userId);

    DocumentSnapshot userDoc = await userRef.get();
    if (!userDoc.exists) return;

    // Get all Level 1 referrals
    QuerySnapshot level1Snapshot = await firestore
        .collection('users')
        .where('referredBy', isEqualTo: userId)
        .get();

    for (var level1Doc in level1Snapshot.docs) {
      double level1 =
          (double.tryParse(level1Doc['refferralProfit'].toString()) ?? 0.0) *
              0.06;
      level1Profit .value+= level1;

      // Level 2 referrals (children of Level 1)
      QuerySnapshot level2Snapshot = await firestore
          .collection('users')
          .where('referredBy', isEqualTo: level1Doc.id)
          .get();

      for (var level2Doc in level2Snapshot.docs) {
        double level2 =
            (double.tryParse(level2Doc['refferralProfit'].toString()) ?? 0.0) *
                0.04;
        level2Profit.value += level2;

        // Level 3 referrals (children of Level 2)
        QuerySnapshot level3Snapshot = await firestore
            .collection('users')
            .where('referredBy', isEqualTo: level2Doc.id)
            .get();

        for (var level3Doc in level3Snapshot.docs) {
          double level3 =
              (double.tryParse(level3Doc['refferralProfit'].toString()) ??
                      0.0) *
                  0.02;
          level3Profit.value += level3;
        }
      }
    }

    // Add profits to the total profit
    totalProfit .value= level1Profit.value + level2Profit.value + level3Profit.value;

    // Update user cash vault with total profit
    await userRef.update({
      "cashVault": FieldValue.increment(totalProfit.value),
    });

    // Update local variables (optional, for UI purposes)

    Get.log("✅ Referral Profit Updated: Rs $totalProfit");
    Get.log("Level 1 Profit: Rs $level1Profit");
    Get.log("Level 2 Profit: Rs $level2Profit");
    Get.log("Level 3 Profit: Rs $level3Profit");
  }
}
