import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get_storage/get_storage.dart';
import 'package:universal_html/html.dart' as html;
import 'package:get/get.dart';

class CacheManager {
  static final GetStorage _storage = GetStorage();

  /// Clear all application cache
  static Future<void> clearAllCache() async {
    try {
      // Clear GetStorage
      await _storage.erase();

      // Clear web-specific cache
      if (kIsWeb) {
        // Clear localStorage except deviceId
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

      Get.log("✅ All cache cleared successfully");
    } catch (e) {
      Get.log("❌ Error clearing cache: $e");
    }
  }

  /// Clear specific cache types
  static Future<void> clearTaskCache() async {
    try {
      final keys = _storage.getKeys();
      for (String key in keys) {
        if (key.contains('completedTasks') ||
            key.contains('cashValue') ||
            key.contains('lastResetDate')) {
          _storage.remove(key);
        }
      }
      Get.log("✅ Task cache cleared");
    } catch (e) {
      Get.log("❌ Error clearing task cache: $e");
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
