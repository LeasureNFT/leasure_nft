
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:leasure_nft/app/core/app_colors.dart';

void showToast(String message, {bool isError = false}) {
    if (GetPlatform.isWeb) {
      Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: isError ? AppColors.errorColor : AppColors.greenColor,
        textColor: AppColors.whiteColor,
      );
    } else {
      Get.snackbar(
        isError ? 'Error' : 'Success',
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: isError ? AppColors.errorColor : AppColors.greenColor,
        colorText: AppColors.whiteColor,
        duration: const Duration(seconds: 2),
      );
    }
  }
