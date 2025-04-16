import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class DepositRecordController extends GetxController with GetSingleTickerProviderStateMixin {
  var pendingPayments = <Map<String, dynamic>>[].obs;
  var completedPayments = <Map<String, dynamic>>[].obs;
  var cancelledPayments = <Map<String, dynamic>>[].obs;

  var isLoading = false.obs;
  var errorMessage = ''.obs;
  var currentTab = 0.obs;

  void changeTab(int index) {
    currentTab.value = index;
  }

  @override
  void onInit() {
    super.onInit();
    fetchPayments();
  }

  Future<void> fetchPayments() async {
    try {
      isLoading(true);
      errorMessage.value = '';

      Timestamp oneMonthAgo = Timestamp.fromDate(
        DateTime.now().subtract(Duration(days: 30)),
      );

      var querySnapshot = await FirebaseFirestore.instance
          .collection('payments')
          .where('transactionType', isEqualTo: 'Deposit')
          .where('createdAt', isGreaterThanOrEqualTo: oneMonthAgo)
          .orderBy('createdAt', descending: true)
          .get();

      // ✅ Temporary lists
      List<Map<String, dynamic>> pendingList = [];
      List<Map<String, dynamic>> completedList = [];
      List<Map<String, dynamic>> cancelledList = [];

      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> paymentData = Map<String, dynamic>.from(doc.data()); // ✅ Correct Type Conversion
        paymentData['id'] = doc.id; // Add document ID

        String userId = paymentData['userId'] ?? '';

        // 🔥 Fetch user details
        var userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
        if (userDoc.exists) {
          paymentData['username'] = userDoc.data()?['username'] ?? 'Unknown';
          paymentData['email'] = userDoc.data()?['email'] ?? 'Unknown';
        } else {
          paymentData['username'] = 'Unknown';
          paymentData['email'] = 'Unknown';
        }

        // 🔥 Categorize payments
        if (paymentData['status'] == 'pending') {
          pendingList.add(paymentData);
        } else if (paymentData['status'] == 'completed') {
          completedList.add(paymentData);
        } else if (paymentData['status'] == 'cancelled') {
          cancelledList.add(paymentData);
        }
      }

      // ✅ Correct way to update RxList
      pendingPayments.value = pendingList;
      completedPayments.value = completedList;
      cancelledPayments.value = cancelledList;

      await deleteOldPayments(oneMonthAgo);
    } catch (e) {
      errorMessage.value = 'Failed to fetch payments: ${e.toString()}';
    } finally {
      isLoading(false);
    }
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
