import 'package:get_storage/get_storage.dart';

const String _admin = 'admin';

class AppPrefernces {
  static setAdmin(value) => GetStorage().write(_admin, value);
  static get getAdmin => GetStorage().read(_admin);
  static removeAdmin() => GetStorage().remove(_admin);

  // Clear all cached data (excluding task-related data)
  static clearAllCache() {
    // Preserve task-related data before clearing
    final storage = GetStorage();
    final keys = storage.getKeys();
    Map<String, dynamic> taskData = {};

    // Save task-related data
    for (String key in keys) {
      if (key.contains('completedTasks') ||
          key.contains('cashValue') ||
          key.contains('lastResetDate')) {
        taskData[key] = storage.read(key);
      }
    }

    // Clear all storage
    storage.erase();

    // Restore task-related data
    for (String key in taskData.keys) {
      storage.write(key, taskData[key]);
    }
  }

  // Clear specific cache keys (excluding task-related data)
  static clearTaskCache() {
    // Task cache clearing disabled - preserve task-related data
    // completedTasks, cashValue, lastResetDate are now preserved
  }

  // Clear device-specific cache
  static clearDeviceCache() {
    GetStorage().remove('deviceId');
  }
}
