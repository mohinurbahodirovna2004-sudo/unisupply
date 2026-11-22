import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Server manzili. Android emulyatorida 10.0.2.2 — kompyuterning localhost'i.
/// O‘zgartirish: flutter run --dart-define=API_URL=https://api.sizning-domen.uz
const baseUrl = String.fromEnvironment('API_URL', defaultValue: 'http://10.0.2.2:8000');

const roleNames = {
  'admin': 'Administrator',
  'leader': 'Rektorat',
  'faculty': 'Fakultet mas’uli',
  'supply': 'Ta’minot xodimi',
  'warehouse': 'Ombor mudiri',
};

class ApiException implements Exception {
  ApiException(this.message, [this.status]);
  final String message;
  final int? status;
  @override
  String toString() => message;
}

class Api {
  static String? _access, _refresh;
  static Map<String, dynamic> me = {};
  static String get role => (me['role'] ?? '') as String;

  static Future<void> _save(String? a, String? r) async {
    _access = a;
    _refresh = r ?? _refresh;
    final p = await SharedPreferences.getInstance();
    if (a == null) {
      await p.remove('access');
      await p.remove('refresh');
    } else {
      await p.setString('access', a);
      if (_refresh != null) await p.setString('refresh', _refresh!);
    }
  }

  /// Ilova ochilganda saqlangan sessiyani tiklaydi.
  static Future<bool> restore() async {
    final p = await SharedPreferences.getInstance();
    _access = p.getString('access');
    _refresh = p.getString('refresh');
    if (_refresh == null) return false;
    try {
      me = Map<String, dynamic>.from(await get('/api/me/'));
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> login(String username, String password) async {
    http.Response r;
    try {
      r = await http.post(Uri.parse('$baseUrl/api/auth/login/'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'username': username, 'password': password}));
    } catch (_) {
      throw ApiException('Serverga ulanib bo‘lmadi. Internetni tekshiring.');
    }
    if (r.statusCode != 200) throw ApiException('Login yoki parol noto‘g‘ri.');
    final d = jsonDecode(r.body);
    await _save(d['access'], d['refresh']);
    me = Map<String, dynamic>.from(await get('/api/me/'));
  }

  static Future<void> logout() async {
    me = {};
    _refresh = null;
    await _save(null, null);
  }

  static Future<bool> _refreshToken() async {
    if (_refresh == null) return false;
    try {
      final r = await http.post(Uri.parse('$baseUrl/api/auth/refresh/'),
          headers: {'Content-Type': 'application/json'}, body: jsonEncode({'refresh': _refresh}));
      if (r.statusCode != 200) return false;
      await _save(jsonDecode(r.body)['access'], null);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<dynamic> _send(String method, String path, [Map<String, dynamic>? body]) async {
    Future<http.Response> go() {
      final h = {'Content-Type': 'application/json', if (_access != null) 'Authorization': 'Bearer $_access'};
      final u = Uri.parse('$baseUrl$path');
      final b = jsonEncode(body ?? {});
      return switch (method) {
        'GET' => http.get(u, headers: h),
        'PATCH' => http.patch(u, headers: h, body: b),
        _ => http.post(u, headers: h, body: b),
      };
    }

    http.Response r;
    try {
      r = await go();
      if (r.statusCode == 401 && await _refreshToken()) r = await go();
    } catch (_) {
      throw ApiException('Serverga ulanib bo‘lmadi. Internetni tekshiring.');
    }
    final data = r.body.isEmpty ? null : jsonDecode(utf8.decode(r.bodyBytes));
    if (r.statusCode >= 400) throw ApiException(_message(data, r.statusCode), r.statusCode);
    return data;
  }

  static String _message(dynamic d, int code) {
    if (d is Map) {
      if (d['detail'] is String) return d['detail'] as String;
      for (final v in d.values) {
        return v is List && v.isNotEmpty ? '${v.first}' : '$v';
      }
    }
    if (d is List && d.isNotEmpty) return '${d.first}';
    return code == 403 ? 'Bu amal uchun ruxsat yo‘q.' : 'Xatolik ($code)';
  }

  static Future<dynamic> get(String path) => _send('GET', path);
  static Future<dynamic> post(String path, [Map<String, dynamic>? body]) => _send('POST', path, body);
  static Future<dynamic> patch(String path, Map<String, dynamic> body) => _send('PATCH', path, body);

  /// Sahifalangan ({results: []}) yoki oddiy ro‘yxatni List sifatida qaytaradi.
  static Future<List<dynamic>> list(String path) async {
    final d = await get(path);
    return d is Map ? List<dynamic>.from(d['results'] as List) : List<dynamic>.from(d as List);
  }
}
