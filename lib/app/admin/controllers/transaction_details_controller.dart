import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:leasure_nft/app/admin/screens/deposit/controller/deposit_record_controller.dart';
import 'package:leasure_nft/app/admin//screens/withdraw/controller/withdraw_record_controller.dart';

class TransactionDetailsController extends GetxController {
  final isLoading = false.obs;
  final isLoading1 = false.obs;
  final depositController = Get.put(DepositRecordController());
  final withdrawController = Get.put(WithdrawRecordController());
  String formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return DateFormat('MMMM dd, yyyy hh:mm a').format(dateTime);
  }

  Future<void> confirmDeposit({userId, amount, docId}) async {
    try {
      isLoading.value = true;
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      // 🔥 Get User ID from transaction
      double am =
          double.tryParse(amount.toString()) ?? 0.0; // ✅ Convert to double

      await firestore.runTransaction((transactions) async {
        // 🔹 Update payment status to "completed"
        DocumentReference paymentRef =
            firestore.collection('payments').doc(docId);
        transactions.update(paymentRef, {'status': 'completed'});

        // 🔹 Update user's depositAmount & cashVault (Increment by amount)
        DocumentReference userRef = firestore.collection('users').doc(userId);
        transactions.update(userRef, {
          'depositAmount': FieldValue.increment(am), // 🔥 Add to existing value
          'cashVault': FieldValue.increment(am) // 🔥 Add to existing value
        });
      }).then((v) async {
        await depositController.fetchPayments();
      });
      Fluttertoast.showToast(
        msg: "Payment Confirmed successfully!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      // 🔥 Show success message

      // 🔄 Refresh data

      isLoading.value = true;
    } catch (e) {
      Get.snackbar("Error", "Failed to confirm deposit: ${e.toString()}",
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red);
      isLoading.value = false;
    } finally {
      isLoading.value = false;
      Get.back();
    }
  }

  Future<void> cancel({docId, withdrawAM}) async {
    try {
      isLoading1.value = true;

      // Get the payment document first to check transaction type
      final paymentDoc = await FirebaseFirestore.instance
          .collection('payments')
          .doc(docId)
          .get();

      if (!paymentDoc.exists) {
        Fluttertoast.showToast(
          msg: "Payment document not found",
          backgroundColor: Colors.red,
        );
        return;
      }

      final transactionType = paymentDoc.data()?['transactionType'];
      final userId = paymentDoc.data()?['userId'];
      final amount = double.tryParse(withdrawAM.toString()) ?? 0.0;

      // Update payment status to cancelled
      await FirebaseFirestore.instance
          .collection('payments')
          .doc(docId)
          .update({'status': 'cancelled'});

      // Only refund for WITHDRAW transactions, NOT for DEPOSIT transactions
      if (transactionType == 'Withdraw') {
        // For withdraw cancellation, refund the amount to user's cashVault
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({
          'cashVault': FieldValue.increment(amount),
        });
        Fluttertoast.showToast(
          msg: "Withdraw Cancelled. Amount has been refunded to your account",
          backgroundColor: Colors.green,
        );
      } else if (transactionType == 'Deposit') {
        // For deposit cancellation, DO NOT add amount to cashVault
        // Just cancel the payment, no refund needed
        Fluttertoast.showToast(
          msg: "Deposit Cancelled. No amount will be added to your account",
          backgroundColor: Colors.orange,
        );
      }

      final depositController = Get.put(DepositRecordController());
      await depositController.fetchPayments();
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error cancelling payment: ${e.toString()}",
        backgroundColor: Colors.red,
      );
      Get.log("Error cancelling payment: ${e.toString()}");
    } finally {
      isLoading1.value = false;
      Get.back();
    }
  }

  Future<void> confirmWithdraw(
      {required String userId,
      required String amount,
      required String docId}) async {
    try {
      isLoading.value = true;
      FirebaseFirestore firestore = FirebaseFirestore.instance;

      await firestore.runTransaction((transaction) async {
        // 🔹 Reference to payment document
        DocumentReference paymentRef =
            firestore.collection('payments').doc(docId);

        // 🔹 Reference to user document
        DocumentReference userRef = firestore.collection('users').doc(userId);

        // 🔹 Fetch current user data to verify balance
        // final userSnapshot = await transaction.get(userRef);

        // if (!userSnapshot.exists) {
        //   throw Exception("User not found");
        // }

        // double currentVault = double.parse(userSnapshot['cashVault'] ?? 0.0);

        double am = double.tryParse(amount.toString()) ?? 0.0;
        // 🔥 Ensure user has enough balance

        // if (currentVault < am) {
        //   Fluttertoast.showToast(
        //     msg: "Insufficient balance in cash vault.",
        //     toastLength: Toast.LENGTH_SHORT,
        //     gravity: ToastGravity.BOTTOM,
        //     backgroundColor: Colors.red,
        //     textColor: Colors.white,
        //     fontSize: 16.0,
        //   );
        //   return;
        // }

        // 🔹 Update payment status to "completed"

        transaction.update(paymentRef, {'status': 'completed'});

        // 🔹 Update user's withdrawAmount and cashVault
        transaction.update(userRef, {
          'withdrawAmount':
              FieldValue.increment(am), // ✅ Add to Withdraw Amount
          // ✅ Deduct from Cash Vault
        });
      });

      // 🔄 Refresh payment data
      await withdrawController.fetchPayments();

      // ✅ Success message
      Fluttertoast.showToast(
        msg: "Payment Confirmed successfully!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    } catch (e) {
      // ❌ Error handling
      Get.snackbar("Error", "Failed to confirm withdrawal: ${e.toString()}",
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red);
    } finally {
      isLoading.value = false;
      Get.back();
    }
  }
}
