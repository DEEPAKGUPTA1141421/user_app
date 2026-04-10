import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static final _storage = FlutterSecureStorage();

  // 🔑 Keys
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  // =============================
  // ✅ SAVE TOKENS
  // =============================
  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  // =============================
  // ✅ GET TOKENS
  // =============================
  static Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  // =============================
  // ❌ DELETE TOKENS (LOGOUT)
  // =============================
  static Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  // =============================
  // 🔍 CHECK AUTH
  // =============================
  static Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}