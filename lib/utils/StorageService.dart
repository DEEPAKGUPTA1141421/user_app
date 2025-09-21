import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static final _storage = FlutterSecureStorage();

  // Save token
  static Future<void> saveToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }

  // Read token
  static Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  // Delete token (logout)
  static Future<void> deleteToken() async {
    await _storage.delete(key: 'jwt_token');
  }

  static Future<bool> checkAuth() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
