import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<({String token, UserModel user})> login({
    required String email,
    required String password,
  });

  Future<({String token, UserModel user})> register({
    required String name,
    required String email,
    String? phone,
    required String password,
  });

  Future<UserModel> fetchCurrentUser();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final DioClient dioClient;

  AuthRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<({String token, UserModel user})> login({
    required String email,
    required String password,
  }) async {
    final response = await dioClient.dio.post(
      ApiEndpoints.login,
      data: {
        'email': email,
        'password': password,
      },
    );

    final data = response.data as Map<String, dynamic>;
    final token = data['token'] as String;
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    return (token: token, user: user);
  }

  @override
  Future<({String token, UserModel user})> register({
    required String name,
    required String email,
    String? phone,
    required String password,
  }) async {
    final response = await dioClient.dio.post(
      ApiEndpoints.register,
      data: {
        'name': name,
        'email': email,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        'password': password,
      },
    );

    final data = response.data as Map<String, dynamic>;
    final token = data['token'] as String;
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    return (token: token, user: user);
  }

  @override
  Future<UserModel> fetchCurrentUser() async {
    final response = await dioClient.dio.get(ApiEndpoints.me);
    final data = response.data as Map<String, dynamic>;
    return UserModel.fromJson(data['user'] as Map<String, dynamic>);
  }
}
