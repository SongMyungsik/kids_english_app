import 'dart:convert';

import 'package:http/http.dart' as http;

/// GitHub Pages는 정적 파일만 서빙해 자체 서버가 없으므로, 모든 방문자를
/// 합산한 전역 카운트를 위해 Abacus(https://abacus.jasoncameron.dev)
/// 카운터 API를 사용한다. 실패해도(오프라인 등) 화면이 멈추지 않도록
/// 짧은 타임아웃과 함께 null을 반환해 조용히 넘어간다.
class LaunchCounterService {
  static const _namespace = 'kids-english-app-songmyungsik';
  static const _key = 'home-loads';

  static Future<int?> incrementAndGet() async {
    try {
      final uri =
          Uri.parse('https://abacus.jasoncameron.dev/hit/$_namespace/$_key');
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['value'] as int?;
    } catch (_) {
      return null;
    }
  }
}
