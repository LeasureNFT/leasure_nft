import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_simple_treeview/flutter_simple_treeview.dart';
import 'package:get/get.dart';

class NetworkController extends GetxController {
  var referralTree =
      <Map<String, dynamic>>[].obs; // Store referrals as list of maps
  String? userId;
  final isloading = false.obs;
  final level1 = <Map<String, dynamic>>[].obs;
final level2 = <Map<String, dynamic>>[].obs;
final level3 = <Map<String, dynamic>>[].obs;
  
final currentTab = 0.obs;
  void changeTab(int index) {
    currentTab.value = index;
  }
  @override
  void onInit() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
     
      isloading.value = true;
      userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        await fetchReferrals(userId!);
      }
      isloading.value = false;
    });
    super.onInit();
  }
  Future<void> fetchReferrals(String userId) async {
  try {
    level1.clear();
    level2.clear();
    level3.clear();

    QuerySnapshot level1Snap = await FirebaseFirestore.instance
        .collection('users')
        .where('refferredBy', isEqualTo: userId)
        .get();

    for (var doc1 in level1Snap.docs) {
      final user1 = {
        "id": doc1.id,
        "name": doc1["username"] ?? "Unknown",
      };
      level1.add(user1);

      QuerySnapshot level2Snap = await FirebaseFirestore.instance
          .collection('users')
          .where('refferredBy', isEqualTo: doc1.id)
          .get();

      for (var doc2 in level2Snap.docs) {
        final user2 = {
          "id": doc2.id,
          "name": doc2["username"] ?? "Unknown",
        };
        level2.add(user2);

        QuerySnapshot level3Snap = await FirebaseFirestore.instance
            .collection('users')
            .where('refferredBy', isEqualTo: doc2.id)
            .get();

        for (var doc3 in level3Snap.docs) {
          final user3 = {
            "id": doc3.id,
            "name": doc3["username"] ?? "Unknown",
          };
          level3.add(user3);
        }
      }
    }
  } catch (e) {
    print("Error: $e");
  }
}


  Future<List<Map<String, dynamic>>> getReferralNodes(String userId) async {
    isloading.value = true;
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('refferredBy', isEqualTo: userId)
        .get();

    List<Map<String, dynamic>> nodes = [];

    for (var doc in snapshot.docs) {
      List<Map<String, dynamic>> childNodes =
          await getReferralNodes(doc.id); // Recursion for nested referrals
      nodes.add({
        "id": doc.id,
        "name": doc["username"] ?? "Unknown",
        "children": childNodes,
      });
    }

    return nodes;
  }

 
}
