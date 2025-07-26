import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'dart:async';

class WithdrawRecordController extends GetxController
    with GetSingleTickerProviderStateMixin {
  var pendingPayments = <Map<String, dynamic>>[].obs;
  var completedPayments = <Map<String, dynamic>>[].obs;
  var cancelledPayments = <Map<String, dynamic>>[].obs;

  var isLoading = false.obs;
  var errorMessage = ''.obs;
  var currentTab = 0.obs;

  // Real-time listeners
  StreamSubscription<QuerySnapshot>? _paymentsSubscription;

  void changeTab(int index) {
    currentTab.value = index;
  }

  @override
  void onInit() {
    super.onInit();
    startRealTimeListener();
  }

  @override
  void onClose() {
    _paymentsSubscription?.cancel();
    super.onClose();
  }

  void startRealTimeListener() {
    Get.log("[WITHDRAW] [INFO] Starting real-time withdraw listener...");

    Timestamp oneMonthAgo = Timestamp.fromDate(
      DateTime.now().subtract(Duration(days: 30)),
    );

    _paymentsSubscription = FirebaseFirestore.instance
        .collection('payments')
        .where('transactionType', isEqualTo: 'Withdraw')
        .where('createdAt', isGreaterThanOrEqualTo: oneMonthAgo)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
      (querySnapshot) async {
        Get.log(
            "[WITHDRAW] [DEBUG] Real-time update received: ${querySnapshot.docs.length} documents");

        try {
          // Temporary lists
          List<Map<String, dynamic>> pendingList = [];
          List<Map<String, dynamic>> completedList = [];
          List<Map<String, dynamic>> cancelledList = [];

          for (var doc in querySnapshot.docs) {
            Map<String, dynamic> paymentData =
                Map<String, dynamic>.from(doc.data());
            paymentData['id'] = doc.id;

            String userId = paymentData['userId'] ?? '';

            // Fetch user details
            try {
              var userDoc = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .get();
              if (userDoc.exists) {
                paymentData['username'] =
                    userDoc.data()?['username'] ?? 'Unknown';
                paymentData['email'] = userDoc.data()?['email'] ?? 'Unknown';
                paymentData['cashVault'] = double.parse(
                    userDoc.data()?['cashVault'].toString() ?? "0");
              } else {
                paymentData['username'] = 'Unknown';
                paymentData['email'] = 'Unknown';
                paymentData['cashVault'] = 0.0;
              }
            } catch (e) {
              Get.log("[WITHDRAW] [ERROR] Failed to fetch user details: $e");
              paymentData['username'] = 'Unknown';
              paymentData['email'] = 'Unknown';
              paymentData['cashVault'] = 0.0;
            }

            // Categorize payments
            if (paymentData['status'] == 'pending') {
              pendingList.add(paymentData);
            } else if (paymentData['status'] == 'completed') {
              completedList.add(paymentData);
            } else if (paymentData['status'] == 'cancelled') {
              cancelledList.add(paymentData);
            }
          }

          // Update lists
          pendingPayments.value = pendingList;
          completedPayments.value = completedList;
          cancelledPayments.value = cancelledList;

          Get.log(
              "[WITHDRAW] [SUCCESS] Real-time update completed - Pending: ${pendingList.length}, Completed: ${completedList.length}, Cancelled: ${cancelledList.length}");
        } catch (e) {
          Get.log("[WITHDRAW] [ERROR] Error processing real-time update: $e");
          errorMessage.value = 'Failed to process updates: ${e.toString()}';
        }
      },
      onError: (error) {
        Get.log("[WITHDRAW] [ERROR] Real-time listener error: $error");
        errorMessage.value = 'Real-time connection failed: ${error.toString()}';
      },
    );
  }

  // Legacy function for manual refresh (if needed)
  Future<void> fetchPayments() async {
    Get.log("[WITHDRAW] [INFO] Manual refresh requested");
    startRealTimeListener();
  }

  Future<void> deleteOldWithdrawals(Timestamp oneMonthAgo) async {
    try {
      QuerySnapshot oldPaymentsSnapshot = await FirebaseFirestore.instance
          .collection('payments')
          .where('transactionType', isEqualTo: 'Withdraw')
          .where('createdAt', isLessThan: oneMonthAgo)
          .get();

      WriteBatch batch = FirebaseFirestore.instance.batch();

      for (var doc in oldPaymentsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      Get.log("🔥 Old withdraw transactions deleted successfully.");
    } catch (e) {
      Get.log("❌ Error deleting old withdraw transactions: $e");
    }
  }
}
