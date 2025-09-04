import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get_storage/get_storage.dart';
import 'package:universal_html/html.dart' as html;
import 'package:get/get.dart';

class CacheManager {
  static final GetStorage _storage = GetStorage();

  /// Clear all application cache (excluding task-related data)
  static Future<void> clearAllCache() async {
    try {
      // Preserve task-related data before clearing
      final keys = _storage.getKeys();
      Map<String, dynamic> taskData = {};

      // Save task-related data
      for (String key in keys) {
        if (key.contains('completedTasks') ||
            key.contains('cashValue') ||
            key.contains('lastResetDate')) {
          taskData[key] = _storage.read(key);
        }
      }

      // Clear GetStorage
      await _storage.erase();

      // Restore task-related data
      for (String key in taskData.keys) {
        _storage.write(key, taskData[key]);
      }

      // Clear web-specific cache
      if (kIsWeb) {
        // Clear localStorage except deviceId and task data
        final deviceId = html.window.localStorage['deviceId'];
        html.window.localStorage.clear();
        if (deviceId != null) {
          html.window.localStorage['deviceId'] = deviceId;
        }

        // Clear sessionStorage
        html.window.sessionStorage.clear();

        // Clear browser cache if possible
        if (html.window.navigator.serviceWorker != null) {
          try {
            final registrations =
                await html.window.navigator.serviceWorker!.getRegistrations();
            for (var registration in registrations) {
              await registration.unregister();
            }
          } catch (e) {
            Get.log("❌ Error clearing service worker: $e");
          }
        }
      }

      Get.log("✅ Cache cleared successfully (task data preserved)");
    } catch (e) {
      Get.log("❌ Error clearing cache: $e");
    }
  }

  /// Clear specific cache types (excluding task-related data)
  static Future<void> clearTaskCache() async {
    try {
      // Task cache clearing disabled - preserve task-related data
      // Only clear non-task related cache if needed
      Get.log("✅ Task cache clearing disabled - preserving task data");
    } catch (e) {
      Get.log("❌ Error in task cache method: $e");
    }
  }

  /// Clear user-specific cache
  static Future<void> clearUserCache(String userId) async {
    try {
      final keys = _storage.getKeys();
      for (String key in keys) {
        if (key.contains(userId)) {
          _storage.remove(key);
        }
      }
      Get.log("✅ User cache cleared for: $userId");
    } catch (e) {
      Get.log("❌ Error clearing user cache: $e");
    }
  }

  /// Force refresh data from server
  static Future<void> forceRefresh() async {
    try {
      // Clear all local cache
      await clearAllCache();

      // Force reload if on web
      if (kIsWeb) {
        html.window.location.reload();
      }

      Get.log("✅ Force refresh completed");
    } catch (e) {
      Get.log("❌ Error during force refresh: $e");
    }
  }

  /// Check if cache is stale (older than specified hours)
  static bool isCacheStale(String key, int hours) {
    try {
      final timestamp = _storage.read('${key}_timestamp');
      if (timestamp == null) return true;

      final lastUpdate = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();
      final difference = now.difference(lastUpdate);

      return difference.inHours > hours;
    } catch (e) {
      return true; // Consider stale if error
    }
  }

  /// Update cache timestamp
  static void updateCacheTimestamp(String key) {
    try {
      _storage.write('${key}_timestamp', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      Get.log("❌ Error updating cache timestamp: $e");
    }
  }

  /// Get cache size (web only)
  static int getCacheSize() {
    if (kIsWeb) {
      return html.window.localStorage.length +
          html.window.sessionStorage.length;
    }
    return _storage.getKeys().length;
  }
}
