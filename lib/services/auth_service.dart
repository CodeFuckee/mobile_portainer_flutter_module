import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/platform_detector.dart';
import 'platform/http_helper.dart';
import 'platform/preferences_service.dart';

class AuthResult {
  final bool success;
  final String? token;
  final String? error;

  AuthResult._({required this.success, this.token, this.error});

  factory AuthResult.ok(String token) => AuthResult._(success: true, token: token);
  factory AuthResult.fail(String error) => AuthResult._(success: false, error: error);
}

class AuthService {
  static const _tokenKey = 'docker_auth_token';
  static const _serverUrlKey = 'docker_auth_server_url';

  /// Web 端：通过 /admin/keys 获取 API Key
  /// 原生端：通过 Portainer /api/auth 获取 JWT
  static Future<AuthResult> login({
    required String serverUrl,
    required String username,
    required String password,
    bool ignoreSsl = false,
  }) async {
    if (PlatformDetector.isWeb) {
      return _loginWeb(serverUrl, username, password);
    }
    return _loginNative(serverUrl, username, password, ignoreSsl);
  }

  /// Web 端登录：GET /admin/keys，通过 X-Admin-User / X-Admin-Pass 认证
  static Future<AuthResult> _loginWeb(
    String serverUrl,
    String username,
    String password,
  ) async {
    final cleanUrl = serverUrl.endsWith('/')
        ? serverUrl.substring(0, serverUrl.length - 1)
        : serverUrl;

    final url = Uri.parse('$cleanUrl/admin/login');
    final client = http.Client();

    try {
      final response = await client.post(
        url,
        headers: {
          'X-Admin-User': username,
          'X-Admin-Pass': password,
        },
      );

      if (response.statusCode == 200) {
        final apiKey = _extractApiKey(response.body);
        if (apiKey != null && apiKey.isNotEmpty) {
          final prefs = await PreferencesService.getInstance();
          await prefs.setString(_tokenKey, apiKey);
          await prefs.setString(_serverUrlKey, cleanUrl);
          await prefs.setString('docker_api_key', apiKey);
          await prefs.setString('docker_api_url', cleanUrl);
          return AuthResult.ok(apiKey);
        }
        return AuthResult.fail('响应中未找到 API Key');
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        return AuthResult.fail('用户名或密码错误');
      } else {
        return AuthResult.fail('服务器错误 (${response.statusCode})');
      }
    } catch (e) {
      return AuthResult.fail('无法连接到服务器: $e');
    } finally {
      client.close();
    }
  }

  /// 原生端登录：POST /api/auth（Portainer 标准）
  static Future<AuthResult> _loginNative(
    String serverUrl,
    String username,
    String password,
    bool ignoreSsl,
  ) async {
    final cleanUrl = serverUrl.endsWith('/')
        ? serverUrl.substring(0, serverUrl.length - 1)
        : serverUrl;

    final authUrl = Uri.parse('$cleanUrl/api/auth');
    final client = HttpHelper.createClient(ignoreSsl: ignoreSsl);

    try {
      final response = await client.post(
        authUrl,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final token = data['jwt'] as String?;
        if (token != null && token.isNotEmpty) {
          final prefs = await PreferencesService.getInstance();
          await prefs.setString(_tokenKey, token);
          await prefs.setString(_serverUrlKey, cleanUrl);
          await prefs.setString('docker_api_key', token);
          await prefs.setString('docker_api_url', cleanUrl);
          await prefs.setString('docker_ignore_ssl', ignoreSsl.toString());
          return AuthResult.ok(token);
        }
        return AuthResult.fail('响应中未找到认证令牌');
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        return AuthResult.fail('用户名或密码错误');
      } else {
        String detail = '服务器错误 (${response.statusCode})';
        try {
          final data = json.decode(response.body);
          if (data is Map && data.containsKey('message')) {
            detail = data['message'].toString();
          }
        } catch (_) {}
        return AuthResult.fail(detail);
      }
    } catch (e) {
      return AuthResult.fail('无法连接到服务器: $e');
    } finally {
      client.close();
    }
  }

  /// 从响应中提取 API Key，兼容多种返回格式
  static String? _extractApiKey(String body) {
    try {
      final data = json.decode(body);
      if (data is Map<String, dynamic>) {
        if (data.containsKey('key')) return data['key']?.toString();
        if (data.containsKey('apiKey')) return data['apiKey']?.toString();
        if (data.containsKey('token')) return data['token']?.toString();
        if (data.containsKey('api_key')) return data['api_key']?.toString();
      }
    } catch (_) {}
    // 纯文本格式：响应体直接就是 key
    final trimmed = body.trim();
    if (trimmed.isNotEmpty && !trimmed.contains('{') && !trimmed.contains('<')) {
      return trimmed;
    }
    return null;
  }

  /// 检查是否已登录（web 端使用）
  static Future<bool> isLoggedIn() async {
    if (!PlatformDetector.isWeb) return true;
    final prefs = await PreferencesService.getInstance();
    final token = await prefs.getString(_tokenKey);
    final url = await prefs.getString(_serverUrlKey);
    return token != null && token.isNotEmpty && url != null && url.isNotEmpty;
  }

  /// 获取存储的认证令牌（供 DockerService 使用）
  static Future<String?> getToken() async {
    final prefs = await PreferencesService.getInstance();
    return await prefs.getString(_tokenKey);
  }

  /// 获取存储的服务器 URL
  static Future<String?> getServerUrl() async {
    final prefs = await PreferencesService.getInstance();
    return await prefs.getString(_serverUrlKey);
  }

  /// 获取 API Key 列表（Web 端）
  static Future<List<Map<String, dynamic>>> getApiKeys() async {
    final prefs = await PreferencesService.getInstance();
    final serverUrl = await prefs.getString(_serverUrlKey);
    final token = await prefs.getString(_tokenKey);

    if (serverUrl == null || token == null) {
      throw Exception('未登录');
    }

    final cleanUrl = serverUrl.endsWith('/')
        ? serverUrl.substring(0, serverUrl.length - 1)
        : serverUrl;

    final url = Uri.parse('$cleanUrl/admin/keys');
    final client = http.Client();

    try {
      final response = await client.get(
        url,
        headers: {'x-api-key': token},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('获取 API Key 列表失败 (${response.statusCode})');
      }
    } finally {
      client.close();
    }
  }

  /// 创建 API Key（Web 端），key 为空时由后端自动生成
  static Future<Map<String, dynamic>> createApiKey({
    required String name,
    String? key,
    String? expiresAt,
  }) async {
    final prefs = await PreferencesService.getInstance();
    final serverUrl = await prefs.getString(_serverUrlKey);
    final token = await prefs.getString(_tokenKey);

    if (serverUrl == null || token == null) {
      throw Exception('未登录');
    }

    final cleanUrl = serverUrl.endsWith('/')
        ? serverUrl.substring(0, serverUrl.length - 1)
        : serverUrl;

    final url = Uri.parse('$cleanUrl/admin/keys');
    final client = http.Client();

    try {
      final body = <String, dynamic>{'name': name};
      if (key != null && key.isNotEmpty) {
        body['key'] = key;
      }
      if (expiresAt != null) {
        body['expires_at'] = expiresAt;
      }

      final response = await client.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('创建 API Key 失败 (${response.statusCode})');
      }
    } finally {
      client.close();
    }
  }

  /// 删除 API Key（Web 端）
  static Future<void> deleteApiKey(String keyId) async {
    final prefs = await PreferencesService.getInstance();
    final serverUrl = await prefs.getString(_serverUrlKey);
    final token = await prefs.getString(_tokenKey);

    if (serverUrl == null || token == null) {
      throw Exception('未登录');
    }

    final cleanUrl = serverUrl.endsWith('/')
        ? serverUrl.substring(0, serverUrl.length - 1)
        : serverUrl;

    final url = Uri.parse('$cleanUrl/admin/keys/$keyId');
    final client = http.Client();

    try {
      final response = await client.delete(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('删除 API Key 失败 (${response.statusCode})');
      }
    } finally {
      client.close();
    }
  }

  /// 登出，清除认证信息
  static Future<void> logout() async {
    final prefs = await PreferencesService.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_serverUrlKey);
    await prefs.remove('docker_api_key');
    await prefs.remove('docker_api_url');
  }
}
