import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:leasure_nft/app/core/utils/cache_manager.dart';
import 'package:leasure_nft/app/core/assets/constant.dart';

class UserTaskController extends GetxController with WidgetsBindingObserver {
  RxBool isLoading = false.obs;
  RxBool isTaskLoading = true.obs; // For task fetching shimmer
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

    // Start loading shimmer
    isTaskLoading.value = true;

    try {
      // First get tasks to check balance
      await getTasks();

      // Always initialize completedTasks list for proper length
      if (taskList.isNotEmpty) {
        // Initialize completedTasks with correct length
        if (completedTasks.isEmpty) {
          completedTasks.value =
              List.generate(taskList.length, (index) => false);
        }

        // FIRST: Load completed tasks to check current state
        await loadCompletedTasks();

        // SECOND: Check and reset tasks (only if new day)
        await checkAndResetTasks();

        // Debug storage contents
        debugStorageContents();
      }
    } finally {
      // Stop loading shimmer
      isTaskLoading.value = false;
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this); // Clean up observer
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      Get.log("🔄 App resumed - checking task status...");

      // Show loading shimmer
      isTaskLoading.value = true;

      try {
        // Ensure taskList is initialized
        if (taskList.isEmpty) {
          taskList.value = taskPool;
        }

        await checkAndResetTasks();
        await loadCompletedTasks();
        await getTasks();

        Get.log("✅ Task status refreshed after app resume");
      } finally {
        // Hide loading shimmer
        isTaskLoading.value = false;
      }
    }
  }

  Future<void> checkAndResetTasks() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Don't proceed if no tasks available (insufficient balance)
    if (taskList.isEmpty) {
      Get.log(
          "⚠️ Skipping task reset - no tasks available (insufficient balance)");
      return;
    }

    String uid = user.uid;
    final box = GetStorage();
    String currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    String? lastResetDate = box.read<String>('lastResetDate');

    // Check if we have completed tasks loaded from Firebase/local storage
    bool hasCompletedTasks = completedTasks.any((task) => task == true);

    if (lastResetDate == null) {
      // First time - set the date but don't reset tasks if they're already completed
      Get.log("🔄 First time setup: setting lastResetDate to $currentDate");
      box.write('lastResetDate', currentDate);

      if (!hasCompletedTasks) {
        // Only reset if no tasks are completed
        completedTasks.value = List.generate(taskList.length, (index) => false);
        box.write('completedTasks_$uid', completedTasks.value);
        Get.log("✅ First time: initialized fresh tasks");
      } else {
        Get.log("✅ First time: preserving existing completed tasks");
      }
    } else if (lastResetDate != currentDate) {
      // New day, reset the tasks
      Get.log("🔄 New day detected: $lastResetDate -> $currentDate");
      completedTasks.value = List.generate(taskList.length, (index) => false);

      // Task cache clearing removed - preserve task-related data

      box.write('completedTasks_$uid', completedTasks.value);
      box.write("cashValue_$uid", 0);
      box.write('lastResetDate', currentDate);

      // Update cache timestamp
      CacheManager.updateCacheTimestamp('tasks_$uid');

      try {
        // Reset Firebase data for new day
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'todayProfit': 0.0,
          'completedTasks_$currentDate':
              completedTasks.value, // Initialize new day's tasks
          'lastTaskUpdate': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        Get.log(
            "✅ New day reset: todayProfit=0, tasks initialized for $currentDate");
      } catch (e) {
        Get.log("❌ Failed to reset Firebase data for new day: $e");
      }
    } else {
      // Same day - tasks already loaded, just log
      Get.log("🔄 Same day detected: $currentDate - tasks already loaded");
    }
  }

  Future<void> loadCompletedTasks() async {
    final box = GetStorage();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Don't proceed if no tasks available (insufficient balance)
    if (taskList.isEmpty) {
      Get.log(
          "⚠️ Skipping load completed tasks - no tasks available (insufficient balance)");
      return;
    }

    String uid = user.uid;
    String currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    Get.log(
        "🔄 Loading completed tasks for user $uid for date: $currentDate...");

    // FIRST: Load from local storage (fast access)
    var savedTasks = box.read('completedTasks_$uid');
    Get.log("📦 Raw saved tasks from local storage: $savedTasks");

    if (savedTasks != null && savedTasks is List) {
      // Ensure the saved list is a List<bool> and has correct length
      List<bool> savedList = List<bool>.from(savedTasks);
      Get.log(
          "📋 Converted local saved list: $savedList (length: ${savedList.length})");

      if (savedList.length == taskList.length) {
        completedTasks.value = savedList;
        Get.log(
            "✅ Loaded ${savedList.where((task) => task).length} completed tasks from local storage");

        // SECOND: Sync with Firebase in background (don't wait)
        _syncWithFirebase(uid, currentDate, savedList);
        return;
      } else {
        Get.log(
            "⚠️ Local task count mismatch. Expected: ${taskList.length}, Got: ${savedList.length}");
      }
    }

    // If no local data or mismatch, try Firebase
    try {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (userDoc.exists) {
        Map<String, dynamic>? data = userDoc.data() as Map<String, dynamic>?;
        var firebaseTasks = data?['completedTasks_$currentDate'];
        Get.log("📦 Raw Firebase tasks for $currentDate: $firebaseTasks");

        if (firebaseTasks != null && firebaseTasks is List) {
          List<bool> firebaseList = List<bool>.from(firebaseTasks);
          Get.log(
              "📦 Converted Firebase tasks: $firebaseList (length: ${firebaseList.length})");

          if (firebaseList.length == taskList.length) {
            completedTasks.value = firebaseList;
            // Save to local storage for next time
            box.write('completedTasks_$uid', completedTasks.value);
            Get.log(
                "✅ Loaded ${firebaseList.where((task) => task).length} completed tasks from Firebase");
            return;
          } else {
            Get.log(
                "⚠️ Firebase task count mismatch. Expected: ${taskList.length}, Got: ${firebaseList.length}");
          }
        }
      }
    } catch (e) {
      Get.log("❌ Failed to load tasks from Firebase: $e");
    }

    // If both local and Firebase fail, initialize fresh
    completedTasks.value = List.generate(taskList.length, (index) => false);
    Get.log(
        "ℹ️ No saved tasks found, initialized completedTasks with length ${taskList.length}");

    Get.log(
        "📊 Final completedTasks status: ${completedTasks.where((task) => task).length}/${completedTasks.length} completed");
  }

  // Background sync with Firebase (non-blocking)
  void _syncWithFirebase(
      String uid, String currentDate, List<bool> localTasks) async {
    try {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (userDoc.exists) {
        Map<String, dynamic>? data = userDoc.data() as Map<String, dynamic>?;
        var firebaseTasks = data?['completedTasks_$currentDate'];

        if (firebaseTasks != null && firebaseTasks is List) {
          List<bool> firebaseList = List<bool>.from(firebaseTasks);

          // If Firebase has more completed tasks, update local
          bool hasMoreCompleted = false;
          for (int i = 0;
              i < firebaseList.length && i < localTasks.length;
              i++) {
            if (firebaseList[i] && !localTasks[i]) {
              hasMoreCompleted = true;
              break;
            }
          }

          if (hasMoreCompleted) {
            completedTasks.value = firebaseList;
            final box = GetStorage();
            box.write('completedTasks_$uid', firebaseList);
            Get.log("🔄 Synced with Firebase - updated local tasks");
          }
        }
      }
    } catch (e) {
      Get.log("❌ Background Firebase sync failed: $e");
    }
  }

  void saveCompletedTasks() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final box = GetStorage();
    String uid = user.uid;
    String currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Save to local storage
    box.write('completedTasks_$uid', completedTasks.value);

    // Save to Firebase
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'completedTasks_$currentDate': completedTasks.value,
        'lastTaskUpdate': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      Get.log(
          "✅ Task completion data saved to Firebase for date: $currentDate");
    } catch (e) {
      Get.log("❌ Failed to save task completion to Firebase: $e");
    }

    // Debug logging
    int completedCount = completedTasks.where((task) => task).length;
    Get.log(
        "💾 Saved ${completedCount}/${completedTasks.length} completed tasks for user $uid (Local + Firebase)");
  }

  void updateRating(double newRating) {
    rating.value = newRating;
  }

  /// Check if user can access tasks based on balance
  bool canAccessTasks() {
    return taskList.isNotEmpty;
  }

  /// Get current user balance
  double getCurrentBalance() {
    // This should be updated when user balance changes
    // For now, we'll rely on the error message from getTasks()
    return 0.0;
  }

  /// Force refresh completed tasks from storage
  Future<void> refreshCompletedTasks() async {
    Get.log("🔄 Force refreshing completed tasks from storage...");
    await loadCompletedTasks();
    Get.log(
        "✅ Completed tasks refreshed. Current status: ${completedTasks.where((task) => task).length}/${completedTasks.length} completed");
  }

  /// Refresh all tasks with loading shimmer
  Future<void> refreshAllTasks() async {
    isTaskLoading.value = true;

    try {
      await getTasks();
      if (taskList.isNotEmpty) {
        await loadCompletedTasks();
        await checkAndResetTasks();
      }
      Get.log("✅ All tasks refreshed successfully");
    } finally {
      isTaskLoading.value = false;
    }
  }

  /// Debug method to check storage contents
  void debugStorageContents() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String uid = user.uid;
    final box = GetStorage();

    Get.log("🔍 === STORAGE DEBUG INFO ===");
    Get.log("User ID: $uid");
    Get.log("Task List Length: ${taskList.length}");
    Get.log("Completed Tasks Length: ${completedTasks.length}");
    Get.log("Completed Tasks Value: ${completedTasks.value}");

    var savedTasks = box.read('completedTasks_$uid');
    Get.log("Raw Storage Value: $savedTasks");
    Get.log("Storage Type: ${savedTasks.runtimeType}");

    if (savedTasks is List) {
      Get.log("Storage List Length: ${savedTasks.length}");
      Get.log("Storage List Content: $savedTasks");
    }
    Get.log("===============================");
  }

  void isCompleted(int index) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String uid = user.uid;

    Get.log("🔄 Marking task $index as completed");

    // Ensure completedTasks list is properly initialized
    if (completedTasks.isEmpty || completedTasks.length != taskList.length) {
      completedTasks.value = List.generate(taskList.length, (index) => false);
      Get.log(
          "⚠️ Reinitialized completedTasks list with length ${taskList.length}");
    }

    // Ensure the list is large enough
    if (index >= completedTasks.length) {
      completedTasks
          .addAll(List.filled(index - completedTasks.length + 1, false));
      Get.log(
          "⚠️ Extended completedTasks list to length ${completedTasks.length}");
    }

    // Mark task as completed
    completedTasks[index] = true;
    Get.log("✅ Task $index marked as completed");
    Get.log("📊 Current completed tasks: ${completedTasks.value}");

    // Save updated tasks immediately
    saveCompletedTasks();

    // Check if all tasks are completed
    bool allDone = completedTasks.every((element) => element == true);
    Get.log(
        "📊 Completed tasks: ${completedTasks.where((task) => task).length}/${completedTasks.length}");

    if (allDone) {
      box.remove('cashValue_$uid');
      Fluttertoast.showToast(
        msg: "All tasks completed. Profit tracking reset.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
      Get.log("🎉 All tasks completed! Profit tracking reset.");
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

      // Check if cashVault is below minimum balance
      if (cashVault < MINIMUM_BALANCE_FOR_TASKS) {
        errorMsg.value = LOW_BALANCE_TASK_MESSAGE;

        throw Exception(LOW_BALANCE_TASK_MESSAGE);
      }

      // Only fetch tasks if cashVault is 500 or more
      if (cashVault >= MINIMUM_BALANCE_FOR_TASKS) {
        taskList.value = taskPool;
        if (completedTasks.isEmpty) {
          // Initialize completedTasks if it's empty
          completedTasks.value =
              List.generate(taskList.length, (index) => false);
        }
      } else {
        // Clear tasks if balance is insufficient
        taskList.clear();
        completedTasks.clear();
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
// [GETX] ✅ User ID: H5vT4Rei47REOZjL7li92KJdFCE2
// [GETX] 🧮 Fetched cashVault: 1099.0190146848367
// [GETX] 🧮 Fetched referralProfit: 99.019014684837
// [GETX] 📦 Local stored cashValue: 1093.5512583928723
// [GETX] 💰 Calculated profit (0.5% of 1093.5512583928723): 5.467756291964362
// [GETX] 📦 today profit: 5.467756291964362
// [GETX] 📈 New cashVault after profit: 1104.4867709768012
// [GETX] 📈 New referralProfit after profit: 104.48677097680137
// ✅ Real-time User Data Updated: imran
// [GETX] ✅ Updated Firestore with new cashVault and referralProfit.
// ✅ Real-time User Data Updated: imran
// [GETX] 🔄 Marking task 1 as completed
// [GETX] ✅ Task 1 marked as completed
// [GETX] 📊 Current completed tasks: [true, true, false, false]
// [GETX] 📊 Completed tasks: 2/4
// [GETX] ✅ Task submitted: Profit Rs 5.467756291964362
// [GETX] CLOSE TO ROUTE /viewTaskDetail
// ✅ Task submitted successfully! Profit: Rs 5.467756291964362 added.
// ✅ Real-time User Data Updated: imran
// [GETX] ✅ Task completion data saved to Firebase for date: 2025-09-05
// [GETX] 💾 Saved 2/4 completed tasks for user H5vT4Rei47REOZjL7li92KJdFCE2 (Local + Firebase)
// ✅ Real-time User Data Updated: imran
