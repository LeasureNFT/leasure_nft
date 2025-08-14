import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:leasure_nft/app/core/utils/cache_manager.dart';

class UserTaskController extends GetxController with WidgetsBindingObserver {
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
    super.onInit();
    WidgetsBinding.instance.addObserver(this); // Listen to app lifecycle
    await checkAndResetTasks();
    await loadCompletedTasks();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await getTasks();
    });
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this); // Clean up observer
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      await checkAndResetTasks();
      await loadCompletedTasks();
      await getTasks();
    }
  }

  Future<void> checkAndResetTasks() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String uid = user.uid;
    final box = GetStorage();
    String currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    String? lastResetDate = box.read<String>('lastResetDate');

    if (lastResetDate == null || lastResetDate != currentDate) {
      // New day, reset the tasks
      completedTasks.value = List.generate(taskList.length, (index) => false);

      // Clear old cache data
      await CacheManager.clearTaskCache();

      box.write('completedTasks_$uid', completedTasks.value);
      box.write("cashValue_$uid", 0);
      box.write('lastResetDate', currentDate);

      // Update cache timestamp
      CacheManager.updateCacheTimestamp('tasks_$uid');

      try {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'todayProfit': 0.0,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        Get.log("✅ todayProfit reset to 0 for user $uid");
      } catch (e) {
        Get.log("❌ Failed to reset todayProfit: $e");
      }
    }
  }

  Future<void> loadCompletedTasks() async {
    final box = GetStorage();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String uid = user.uid;
    // Load the saved completedTasks list from GetStorage
    var savedTasks = box.read('completedTasks_$uid');

    if (savedTasks != null && savedTasks is List) {
      // Ensure the saved list is a List<bool>
      completedTasks.value = List<bool>.from(savedTasks);
    }
  }

  void saveCompletedTasks() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final box = GetStorage();
    String uid = user.uid;

    box.write('completedTasks_$uid', completedTasks.value);
  }

  void updateRating(double newRating) {
    rating.value = newRating;
  }

  void isCompleted(int index) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String uid = user.uid;

    // Ensure the list is large enough
    if (index >= completedTasks.length) {
      completedTasks
          .addAll(List.filled(index - completedTasks.length + 1, false));
    }

    // Mark task as completed
    completedTasks[index] = true;

    // Save updated tasks
    saveCompletedTasks();

    // Check if all tasks are completed
    bool allDone = completedTasks.every((element) => element == true);

    if (allDone) {
      box.remove('cashValue_$uid');
      Fluttertoast.showToast(
        msg: "All tasks completed. Profit tracking reset.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    }
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

      // Ban check
      if (userDoc['isUserBanned'] == true) {
        Fluttertoast.showToast(
          msg: "Your account has been banned. Please contact admin.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        await FirebaseAuth.instance.signOut();
        Get.offAllNamed('/login');
        isLoading.value = false;
        return;
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
      errorMessage.value = 'Please wait...';
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
        errorMessage.value = "User is not logged in.";
        throw Exception("User is not logged in.");
      }
      String userId = user.uid;
      Get.log("✅ User ID: $userId");

      // Step 2: Reference Firestore
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      DocumentReference userRef = firestore.collection('users').doc(userId);

      // Step 3: Fetch user document
      DocumentSnapshot userDoc;
      errorMessage.value = 'Fetching user data...';
      try {
        userDoc = await userRef.get();
        // Ban check
        if (userDoc['isUserBanned'] == true) {
          Fluttertoast.showToast(
            msg: "Your account has been banned. Please contact admin.",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.red,
            textColor: Colors.white,
          );
          await FirebaseAuth.instance.signOut();
          Get.offAllNamed('/login');
          isLoading.value = false;
          return;
        }
      } catch (e) {
        isLoading.value = false;
        errorMessage.value = "Failed to retrieve user data: $e";
        throw Exception("Failed to retrieve user data: $e");
      }
      // double todayProfit = 0.0;
      // if (!userDoc.data().toString().contains('todayProfit')) {
      //   await userRef.update({'todayProfit': 0.0});
      // } else {

      // }

      // Step 4: Get current cashVault and refferralProfit
      double cashValue = double.tryParse(userDoc['cashVault'].toString()) ?? 0;
      double refferrelProfit =
          double.tryParse(userDoc['refferralProfit'].toString()) ?? 0;
      double todayProfit =
          double.tryParse(userDoc.get('todayProfit')?.toString() ?? '0.0') ??
              0.0;

      Get.log("🧮 Fetched cashVault: $cashValue");
      Get.log("🧮 Fetched referralProfit: $refferrelProfit");

      errorMessage.value = 'Calculating profit... Please wait';

      // Step 5: Calculate profit
      double profit = 0.0;

      var existingCashValue = box.read("cashValue_$userId");
      Get.log("📦 Local stored cashValue: $existingCashValue");

      if (existingCashValue == null || existingCashValue == 0) {
        box.write("cashValue_$userId", cashValue);
        existingCashValue = box.read("cashValue_$userId");
        Get.log("📦 Updated local storage cashValue: $existingCashValue");
      }

      if (refferrelProfit >= 0) {
        profit = existingCashValue * 0.005;

        Get.log("💰 Calculated profit (0.5% of $existingCashValue): $profit");

        Get.log("📦 today profit: $todayProfit");

        cashValue += profit;
        todayProfit += profit;
        refferrelProfit += profit;

        Get.log("📈 New cashVault after profit: $cashValue");
        Get.log("📈 New referralProfit after profit: $refferrelProfit");

        errorMessage.value = 'Updating cashVault and referral profit...';

        try {
          await userRef.update({
            'cashVault': cashValue,
            'refferralProfit': refferrelProfit,
            'todayProfit': todayProfit,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          Get.log("✅ Updated Firestore with new cashVault and referralProfit.");
        } catch (e) {
          errorMessage.value = "Failed to update user's cashVault: $e";
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

      // Step 6: Save task details in Firestore
      CollectionReference tasks = firestore.collection('task_details');
      try {
        await tasks.add({
          'userId': userId,
          'url': "",
          'profit': profit,
          'rating': rating.value,
          'command': commandController.text,
          'taskName': taskName,
          'taskDesc': taskDesc,
          'isComplete': true,
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
          errorMessage.value = 'Task submitted successfully!';
          commandController.clear();
          Get.log("✅ Task submitted: Profit Rs $profit");
          Get.back();
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
