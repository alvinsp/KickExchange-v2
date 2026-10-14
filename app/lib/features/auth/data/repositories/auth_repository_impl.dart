import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  }) async {
    final isConnected = await networkInfo.isConnected;
    if (!isConnected) {
      return const Left(NetworkFailure('Tidak ada koneksi internet untuk login ke server.'));
    }

    try {
      final result = await remoteDataSource.login(email: email, password: password);
      await localDataSource.saveAuthSession(token: result.token, user: result.user);
      return Right(result.user);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Gagal melakukan login: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> register({
    required String name,
    required String email,
    String? phone,
    required String password,
  }) async {
    final isConnected = await networkInfo.isConnected;
    if (!isConnected) {
      return const Left(NetworkFailure('Tidak ada koneksi internet untuk pendaftaran akun.'));
    }

    try {
      final result = await remoteDataSource.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
      );
      await localDataSource.saveAuthSession(token: result.token, user: result.user);
      return Right(result.user);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Gagal mendaftar akun: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async {
    try {
      // 1. Try local cache first
      final cachedUser = await localDataSource.getCachedUser();
      final token = await localDataSource.getCachedToken();

      if (token == null) {
        return const Right(null);
      }

      // If connected, sync latest profile
      final isConnected = await networkInfo.isConnected;
      if (isConnected) {
        try {
          final remoteUser = await remoteDataSource.fetchCurrentUser();
          await localDataSource.saveAuthSession(token: token, user: remoteUser);
          return Right(remoteUser);
        } catch (_) {
          // If remote fails, return cached
        }
      }

      return Right(cachedUser);
    } catch (e) {
      return Left(CacheFailure('Gagal memuat sesi pengguna: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await localDataSource.clearSession();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Gagal menghapus sesi: ${e.toString()}'));
    }
  }
}
