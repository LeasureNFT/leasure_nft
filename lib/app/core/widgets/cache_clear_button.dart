import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leasure_nft/app/core/utils/cache_manager.dart';
import 'package:leasure_nft/app/core/widgets/toas_message.dart';

class CacheClearButton extends StatelessWidget {
  final bool showText;
  final Color? backgroundColor;
  final Color? textColor;

  const CacheClearButton({
    Key? key,
    this.showText = true,
    this.backgroundColor,
    this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _showCacheClearDialog(context),
      icon: const Icon(Icons.clear_all, size: 18),
      label: showText ? const Text('Clear Cache') : const SizedBox.shrink(),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? Colors.orange,
        foregroundColor: textColor ?? Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _showCacheClearDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear Cache'),
          content: const Text(
              'This will clear all cached data and force the app to reload fresh data from the server. Continue?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _clearCache();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Clear Cache'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _clearCache() async {
    try {
      // Show loading
      Get.dialog(
        const Center(
          child: CircularProgressIndicator(),
        ),
        barrierDismissible: false,
      );

      // Clear cache
      await CacheManager.clearAllCache();

      // Close loading dialog
      Get.back();

      // Show success message
      showToast('All cached data has been cleared successfully.', isError: false);

      // Force refresh after a short delay
      Future.delayed(const Duration(seconds: 2), () {
        CacheManager.forceRefresh();
      });
    } catch (e) {
      // Close loading dialog
      Get.back();

      // Show error message
      showToast('Failed to clear cache: $e', isError: true);
    }
  }
}
