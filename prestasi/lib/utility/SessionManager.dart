import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const String keyLastActive = "last_active_time";

  static Future<void> saveLastActive() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(keyLastActive, DateTime.now().millisecondsSinceEpoch);
  }

  static Future<bool> isSessionExpired() async {
    final prefs = await SharedPreferences.getInstance();
    final lastActive = prefs.getInt(keyLastActive);

    if (lastActive == null) return false;

    final now = DateTime.now().millisecondsSinceEpoch;
    final diff = now - lastActive;

    // 3 Jam = 10,800,000 ms
    return diff > 10800000;
  }

  /// Dipanggil saat user logout (manual maupun otomatis),
  /// supaya tidak ada timestamp basi yang nyangkut di sesi berikutnya.
  static Future<void> clearLastActive() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(keyLastActive);
  }
}