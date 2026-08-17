import 'package:shared_preferences/shared_preferences.dart';

/// 홈 화면이 열린 횟수를 기기에 저장해 세는 서비스.
class LaunchCounterService {
  static const _key = 'home_load_count';

  static Future<int> incrementAndGet() async {
    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt(_key) ?? 0) + 1;
    await prefs.setInt(_key, count);
    return count;
  }
}
