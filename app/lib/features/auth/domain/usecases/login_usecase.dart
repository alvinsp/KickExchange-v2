import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class LoginParams {
  final String email;
  final String password;
  LoginParams({required this.email, required this.password});
}

class LoginUseCase implements UseCase<UserEntity, LoginParams> {
  final AuthRepository repository;
  LoginUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(LoginParams params) async {
    if (params.email.trim().isEmpty || !params.email.contains('@')) {
      return const Left(ValidationFailure('Email tidak valid.'));
    }
    if (params.password.length < 6) {
      return const Left(ValidationFailure('Password minimal 6 karakter.'));
    }
    return await repository.login(
      email: params.email.trim(),
      password: params.password,
    );
  }
}
