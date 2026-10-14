import '../../../../core/security/secure_storage_helper.dart';
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<void> saveAuthSession({required String token, required UserModel user});
  Future<UserModel?> getCachedUser();
  Future<String?> getCachedToken();
  Future<void> clearSession();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SecureStorageHelper secureStorage;

  AuthLocalDataSourceImpl({required this.secureStorage});

  @override
  Future<void> saveAuthSession({required String token, required UserModel user}) async {
    await secureStorage.saveToken(token);
    await secureStorage.saveUserJson(user.toJsonString());
  }

  @override
  Future<UserModel?> getCachedUser() async {
    final jsonStr = await secureStorage.getUserJson();
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      return UserModel.fromJsonString(jsonStr);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String?> getCachedToken() async {
    return await secureStorage.getToken();
  }

  @override
  Future<void> clearSession() async {
    await secureStorage.clearAuth();
  }
}
