import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageHelper {
  final FlutterSecureStorage _storage;
  final Map<String, String> _memoryFallback = {};

  SecureStorageHelper({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            );

  static const String _tokenKey = 'KICK_EXCHANGE_AUTH_TOKEN';
  static const String _userKey  = 'KICK_EXCHANGE_CURRENT_USER_JSON';

  Future<void> saveToken(String token) async {
    _memoryFallback[_tokenKey] = token;
    try {
      await _storage.write(key: _tokenKey, value: token);
    } catch (_) {}
  }

  Future<String?> getToken() async {
    try {
      final val = await _storage.read(key: _tokenKey);
      if (val != null && val.isNotEmpty) return val;
    } catch (_) {}
    return _memoryFallback[_tokenKey];
  }

  Future<void> saveUserJson(String jsonStr) async {
    _memoryFallback[_userKey] = jsonStr;
    try {
      await _storage.write(key: _userKey, value: jsonStr);
    } catch (_) {}
  }

  Future<String?> getUserJson() async {
    try {
      final val = await _storage.read(key: _userKey);
      if (val != null && val.isNotEmpty) return val;
    } catch (_) {}
    return _memoryFallback[_userKey];
  }

  Future<void> clearAuth() async {
    _memoryFallback.remove(_tokenKey);
    _memoryFallback.remove(_userKey);
    try {
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _userKey);
    } catch (_) {}
  }
}
