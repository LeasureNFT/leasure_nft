import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:leasure_nft/app/core/app_colors.dart';
import 'package:leasure_nft/app/core/app_textstyle.dart';
import 'package:leasure_nft/app/core/widgets/custom_button.dart';
import 'package:leasure_nft/app/core/widgets/custom_text_field.dart';
import 'package:leasure_nft/app/core/widgets/header.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:leasure_nft/app/users/screens/dashboard/task/controller/user_task_controller.dart';

class ViewTaskScreen extends StatefulWidget {
  const ViewTaskScreen({super.key});

  @override
  State<ViewTaskScreen> createState() => _ViewTaskScreenState();
}

class _ViewTaskScreenState extends State<ViewTaskScreen> {
  final formkey = GlobalKey<FormState>();
  final random = Random();
  final UserTaskController controller = Get.put(UserTaskController());

  late Map<String, dynamic> task;
  late String randomSubtask;
  var index;

  @override
  void initState() {
    super.initState();
    final getTask = Get.arguments;
    Get.log(getTask.toString()); // Log the arguments to check their structure

    if (getTask != null && getTask is Map<String, dynamic>) {
      index = getTask['index'];
      Get.log("Task data: ${getTask['task']}"); // Log the task data

      task = getTask["task"];

// Check if task is a Map before using it
      final subtasks = task['subtasks'];
      if (subtasks != null && subtasks is List && subtasks.isNotEmpty) {
        randomSubtask = subtasks[Random().nextInt(subtasks.length)]['subtask'];
      } else {
        randomSubtask = 'No subtask available.';
      }
    } else {
      task = {};
      randomSubtask = 'Invalid task data.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 15.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Header(
                title: "Task Details",
                ontap: () {
                  Get.back();
                },
              ),
              SizedBox(height: 20.h),
              Text(
                "Read the script, leave your comments, and provide a rating:",
                style: AppTextStyles.adaptiveText(context, 18)
                    .copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20.h),
              Text(
                randomSubtask,
                style: AppTextStyles.adaptiveText(context, 16)
                    .copyWith(fontWeight: FontWeight.normal),
              ),
              SizedBox(height: 10.h),
              Divider(
                color: AppColors.hintTextColor,
                thickness: 1,
              ),
              SizedBox(height: 10.h),
              CustomTextField(
                controller: controller.commandController,
                validator: (value) {
                  if (value!.isEmpty) {
                    return "Please enter a command";
                  }
                  return null;
                },
                hintText: "Write Something About Script",
                prefixIcon: Icons.edit,
                title: "Command",
              ),
              SizedBox(height: 10.h),
              Text(
                "Rating:",
                style: AppTextStyles.adaptiveText(context, 16)
                    .copyWith(fontWeight: FontWeight.normal),
              ),
              Obx(
                () => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    RatingBar.builder(
                      initialRating: controller.rating.value,
                      minRating: 1,
                      direction: Axis.horizontal,
                      allowHalfRating: true,
                      itemCount: 5,
                      itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                      itemBuilder: (context, _) =>
                          const Icon(Icons.star, color: Colors.amber),
                      onRatingUpdate: (rating) =>
                          controller.updateRating(rating),
                    ),
                    Text(
                      "${controller.rating.value}",
                      style: AppTextStyles.adaptiveText(context, 14)
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10.h),
              Divider(
                color: AppColors.hintTextColor,
                thickness: 1,
              ),
              SizedBox(height: 20.h),
              Obx(
                () => Text(
                  "Status: ${controller.errorMessage.value}",
                  style: AppTextStyles.adaptiveText(context, 16)
                      .copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 10.h),
              Obx(
                () => CustomButton(
                  onPressed: () async {
                    if (controller.commandController.text.isEmpty) {
                      Get.snackbar(
                        "Error",
                        "Please enter a command",
                        duration: const Duration(seconds: 1),
                        backgroundColor: Colors.red,
                        colorText: Colors.white,
                      );
                      return;
                    }
                    await controller.submitTask(
                      index: index,
                      taskName: task["task"],
                      taskDesc: task["description"],
                    );
                  },
                  loading: controller.isLoading.value,
                  text: "Done",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
