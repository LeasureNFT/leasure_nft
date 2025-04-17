import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';

class UserTaskController extends GetxController {
  RxBool isLoading = false.obs;
  final commandController = TextEditingController();
  final descriptionController = TextEditingController();
  final urlController = TextEditingController();
  final taskList = <Map<String, dynamic>>[].obs;

  var currentDay = DateTime.now().day; // Track current day
  var completedTasks = <bool>[].obs;
  var errorMessage = ''.obs;
  final box = GetStorage();

  final errorMsg = ''.obs;
  // RxList<QueryDocumentSnapshot> taskList = <QueryDocumentSnapshot>[].obs;
  var rating = 2.0.obs;

  @override
  void onInit() async {
    super.onInit(); // Ensure GetStorage is initialized
    await checkAndResetTasks();
    await loadCompletedTasks(); // Load the saved completedTasks if available
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await getTasks();
    });
  }

  Future<void> checkAndResetTasks() async {
    // Get the stored date of the last reset
    String? lastResetDate = box.read<String>('lastResetDate');
    String currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    if (lastResetDate == null || lastResetDate != currentDate) {
      // If it's a new day, reset the completedTasks list
      completedTasks.value = List.generate(taskList.length, (index) => false);

      // Clear the saved 'completedTasks' from local storage (empty list for the new day)
      box.remove('completedTasks');
      box.remove("cashValue");
      // Save the updated 'completedTasks' list (as an empty list or initialized state)
      box.write('completedTasks', completedTasks.value);

      // Store the new date to track the last reset
      box.write('lastResetDate', currentDate);
    }
  }

  Future<void> loadCompletedTasks() async {
    // Load the saved completedTasks list from GetStorage
    var savedTasks = box.read('completedTasks');

    if (savedTasks != null && savedTasks is List) {
      // Ensure the saved list is a List<bool>
      completedTasks.value = List<bool>.from(savedTasks);
    }
  }

  void saveCompletedTasks() {
    // Save the completedTasks list in GetStorage
    box.write('completedTasks', completedTasks.value);
  }

  void updateRating(double newRating) {
    rating.value = newRating;
  }

  void isCompleted(int index) {
    // Ensure the list is large enough for the given index
    if (index >= completedTasks.length) {
      // If the index is larger, expand the list to accommodate the index with 'false' (not completed)
      completedTasks
          .addAll(List.filled(index - completedTasks.length + 1, false));
    }

    // Toggle the completion status for the task at the given index
    completedTasks[index] = !completedTasks[index];

    // Save the updated completedTasks list locally
    saveCompletedTasks();
  }

  Future<void> getTasks() async {
    try {
      isLoading.value = true;

      // Get current user ID
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception("User is not logged in.");
      }

      // Fetch user data from Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        errorMsg.value = "User document not found.";
        throw Exception("User document not found.");
      }

      // Get cashVault value (default to 0 if null)
      double cashVault = double.parse(userDoc['cashVault'].toString());

      // Check if cashVault is below 500
      if (cashVault < 500) {
        errorMsg.value =
            "Your balance is too low. Please deposit at least 500 to access tasks.";

        throw Exception(
            "Your balance is too low. Please deposit at least 500 to access tasks.");
      }

      // Fetch tasks if cashVault is 500 or more
      taskList.value = taskPool;
      if (completedTasks.isEmpty) {
        // Initialize completedTasks if it's empty
        completedTasks.value = List.generate(taskList.length, (index) => false);
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: e.toString(),
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> submitTask({
    required String taskName,
    required int index,
    required String taskDesc,
  }) async {
    try {
      errorMessage.value = 'Please wait...'; // Show loading message
      isLoading.value = true;

      // Step 1: Get current user ID
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        isLoading.value = false;
        Fluttertoast.showToast(
          msg: "User is not logged in.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        errorMessage.value = "User is not logged in."; // Set error message
        throw Exception("User is not logged in.");
      }
      String userId = user.uid;

      // Step 2: Reference Firestore
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      DocumentReference userRef = firestore.collection('users').doc(userId);

      // Step 3: Fetch user document
      DocumentSnapshot userDoc;
      errorMessage.value = ' Fetching user data...'; // Show loading message

      try {
        userDoc = await userRef.get();
        if (!userDoc.exists) {
          isLoading.value = false;
          errorMessage.value = "User document does not exist.";
          throw Exception("User document does not exist.");
        }
      } catch (e) {
        isLoading.value = false;
        errorMessage.value = "Failed to retrieve user data: $e";
        throw Exception("Failed to retrieve user data: $e");
      }
      errorMessage.value = 'Calculating profit...'; // Show loading message

      // Step 4: Fetch current cashVault & referral profit (default to 0 if null)
      double cashValue = double.tryParse(userDoc['cashVault'].toString()) ?? 0;
      double refferrelProfit =
          double.tryParse(userDoc['refferralProfit'].toString()) ?? 0;

      errorMessage.value =
          'Calculating profit... Please wait'; // Show loading message;

      // Step 5: Calculate profit ONLY if referral profit is greater than 0
      double profit = 0.0;
      var existingCashValue = box.read("cashValue");
      if (existingCashValue == null) {
        box.write("cashValue", cashValue);
        existingCashValue = box.read("cashValue");
      }
      if (refferrelProfit >= 0) {
        profit = existingCashValue * 0.005; // 2% of cashVault

        cashValue += existingCashValue * 0.005;
        refferrelProfit += profit;

        errorMessage.value = 'Updating cashVault and referral profit...';

        // Step 6: Update cashVault & referral profit in Firestore
        try {
          await userRef.update({
            'cashVault': cashValue, // Corrected: Using actual double
            //  total profit hai
            'refferralProfit':
                refferrelProfit // Keeping as double // total profit
          });
        } catch (e) {
          errorMessage.value =
              "Failed to update user's cashVault: $e"; // Set error message
          Fluttertoast.showToast(
            msg: "Failed to update user's cashVault: $e",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0,
          );
          isLoading.value = false;
          throw Exception("Failed to update user's cashVault: $e");
        }
      }
      errorMessage.value = 'Submitting task...';

      // Step 7: Save task details in Firestore
      CollectionReference tasks = firestore.collection('task_details');
      try {
        await tasks.add({
          'userId': userId,
          'url': "",
          'profit': profit, // Calculated profit
          'rating': rating.value,
          'command': commandController.text,
          'taskName': taskName,
          'taskDesc': taskDesc,
          'isComplete': true, // Task marked as completed
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'videoCompletedAt': FieldValue.serverTimestamp(),
        }).then((value) async {
          Fluttertoast.showToast(
            msg: "Task submitted successfully!",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.green,
            textColor: Colors.white,
            fontSize: 16.0,
          );
          isCompleted(index);
          isLoading.value = false;
          errorMessage.value =
              'Task submitted successfully!'; // Set success message
          Get.back();
          commandController.clear();
        });
      } catch (e) {
        isLoading.value = false;
        Get.snackbar(
          "Error",
          "Failed to save task details: $e",
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        throw Exception("Failed to save task details: $e");
      }

      print("✅ Task submitted successfully! Profit: Rs $profit added.");
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to submit task: $e",
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      Fluttertoast.showToast(msg: "Failed to submit task: $e");
      isLoading.value = false;
      print("❌ Error in submitTask: $e");
    }
  }

  List<Map<String, dynamic>> taskPool = [
    {
      'task': 'Organization Insights',
      'description':
          'Explore the dynamics of organizations and their structures.',
      'subtasks': [
        {'subtask': 'Read a business organization script'},
        {'subtask': 'Research organizational strategies'},
        {'subtask': 'Explore leadership within organizations'},
        {'subtask': 'Watch a corporate culture video'},
        {'subtask': 'Complete an organizational behavior quiz'},
      ],
    },
    {
      'task': 'Education & Learning',
      'description': 'Enhance your knowledge in modern education techniques.',
      'subtasks': [
        {'subtask': 'Read a motivation script from an educator'},
        {'subtask': 'Study modern education techniques'},
        {'subtask': 'Complete an online course quiz'},
        {'subtask': 'Watch a teacher’s seminar video'},
        {'subtask': 'Research educational psychology'},
        {'subtask': 'Explore active learning strategies'},
      ],
    },
    {
      'task': 'Social Media Strategies',
      'description': 'Learn effective strategies for social media marketing.',
      'subtasks': [
        {'subtask': 'Read a social media marketing article'},
        {'subtask': 'Watch a social media growth video'},
        {'subtask': 'Complete a social media management quiz'},
        {'subtask': 'Research social media analytics'},
        {'subtask': 'Create a social media campaign'},
      ],
    },
    {
      'task': 'Politics and Governance',
      'description': 'Understand the intricacies of politics and governance.',
      'subtasks': [
        {'subtask': 'Read a political theory script'},
        {'subtask': 'Watch a political debate video'},
        {'subtask': 'Complete a governance analysis quiz'},
        {'subtask': 'Research political movements'},
        {'subtask': 'Analyze global political trends'},
      ],
    },
  ];
}
