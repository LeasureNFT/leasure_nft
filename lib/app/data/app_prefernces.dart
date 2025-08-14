import 'package:get_storage/get_storage.dart';

const String _admin = 'admin';

class AppPrefernces {
  static setAdmin(value) => GetStorage().write(_admin, value);
  static get getAdmin => GetStorage().read(_admin);
  static removeAdmin() => GetStorage().remove(_admin);

  // Clear all cached data
  static clearAllCache() {
    GetStorage().erase();
  }

  // Clear specific cache keys
  static clearTaskCache() {
    GetStorage().remove('completedTasks');
    GetStorage().remove('cashValue');
    GetStorage().remove('lastResetDate');
  }

  // Clear device-specific cache
  static clearDeviceCache() {
    GetStorage().remove('deviceId');
  }
}
