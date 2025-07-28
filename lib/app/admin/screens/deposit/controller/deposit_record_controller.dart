import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'dart:async'; // Added for StreamSubscription

class DepositRecordController extends GetxController
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
    Get.log("[DEPOSIT] [INFO] DepositRecordController initialized");
    isLoading.value = true;
    startRealTimeListener();
  }

  @override
  void onClose() {
    Get.log("[DEPOSIT] [INFO] Cancelling real-time listener");
    _paymentsSubscription?.cancel();
    super.onClose();
  }

  void startRealTimeListener() {
    Get.log("[DEPOSIT] [INFO] Starting real-time deposit listener...");

    try {
      // Cancel existing subscription if any
      _paymentsSubscription?.cancel();

      Timestamp oneMonthAgo = Timestamp.fromDate(
        DateTime.now().subtract(Duration(days: 30)),
      );

      Get.log("[DEPOSIT] [DEBUG] Querying payments from: $oneMonthAgo");

      _paymentsSubscription = FirebaseFirestore.instance
          .collection('payments')
          .where('transactionType', isEqualTo: 'Deposit')
          .where('createdAt', isGreaterThanOrEqualTo: oneMonthAgo)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen(
        (querySnapshot) async {
          Get.log(
              "[DEPOSIT] [DEBUG] Real-time update received: ${querySnapshot.docs.length} documents");

          try {
            // Temporary lists
            List<Map<String, dynamic>> pendingList = [];
            List<Map<String, dynamic>> completedList = [];
            List<Map<String, dynamic>> cancelledList = [];

            for (var doc in querySnapshot.docs) {
              Map<String, dynamic> paymentData =
                  Map<String, dynamic>.from(doc.data());
              paymentData['id'] = doc.id;

              Get.log("[DEPOSIT] [DEBUG] Processing payment: ${doc.id}");

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
                  paymentData['cashVault'] = double.tryParse(
                          userDoc.data()?['cashVault'].toString() ?? "0") ??
                      0.0;
                } else {
                  paymentData['username'] = 'Unknown';
                  paymentData['email'] = 'Unknown';
                  paymentData['cashVault'] = 0.0;
                }
              } catch (e) {
                Get.log("[DEPOSIT] [ERROR] Failed to fetch user details: $e");
                paymentData['username'] = 'Unknown';
                paymentData['email'] = 'Unknown';
                paymentData['cashVault'] = 0.0;
              }

              // Categorize payments
              String status =
                  paymentData['status']?.toString().toLowerCase() ?? 'pending';
              Get.log("[DEPOSIT] [DEBUG] Payment status: $status");

              if (status == 'pending') {
                pendingList.add(paymentData);
              } else if (status == 'completed') {
                completedList.add(paymentData);
              } else if (status == 'cancelled') {
                cancelledList.add(paymentData);
              }
            }

            // Update lists
            pendingPayments.value = pendingList;
            completedPayments.value = completedList;
            cancelledPayments.value = cancelledList;

            Get.log(
                "[DEPOSIT] [SUCCESS] Real-time update completed - Pending: ${pendingList.length}, Completed: ${completedList.length}, Cancelled: ${cancelledList.length}");

            // Clear any previous errors
            errorMessage.value = '';
            isLoading.value = false;
          } catch (e) {
            Get.log("[DEPOSIT] [ERROR] Error processing real-time update: $e");
            errorMessage.value = 'Failed to process updates: ${e.toString()}';
            isLoading.value = false;
          }
        },
        onError: (error) {
          Get.log("[DEPOSIT] [ERROR] Real-time listener error: $error");
          errorMessage.value =
              'Real-time connection failed: ${error.toString()}';
          isLoading.value = false;
        },
      );
    } catch (e) {
      Get.log("[DEPOSIT] [ERROR] Failed to start real-time listener: $e");
      errorMessage.value = 'Failed to start listener: ${e.toString()}';
      isLoading.value = false;
    }
  }

  // Legacy function for manual refresh (if needed)
  Future<void> fetchPayments() async {
    Get.log("[DEPOSIT] [INFO] Manual refresh requested");
    isLoading.value = true;
    startRealTimeListener();
  }

  Future<void> deleteOldPayments(Timestamp oneMonthAgo) async {
    try {
      QuerySnapshot oldPaymentsSnapshot = await FirebaseFirestore.instance
          .collection('payments')
          .where('transactionType', isEqualTo: 'Deposit')
          .where('createdAt', isLessThan: oneMonthAgo)
          .get();

      WriteBatch batch = FirebaseFirestore.instance.batch();

      for (var doc in oldPaymentsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      Get.log("🔥 Old deposit transactions deleted successfully.");
    } catch (e) {
      Get.log("❌ Error deleting old deposit transactions: $e");
    }
  }
}
