import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class RegisterParams {
  final String name;
  final String email;
  final String? phone;
  final String password;

  RegisterParams({
    required this.name,
    required this.email,
    this.phone,
    required this.password,
  });
}

class RegisterUseCase implements UseCase<UserEntity, RegisterParams> {
  final AuthRepository repository;
  RegisterUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(RegisterParams params) async {
    if (params.name.trim().length < 2) {
      return const Left(ValidationFailure('Nama minimal 2 karakter.'));
    }
    if (params.email.trim().isEmpty || !params.email.contains('@')) {
      return const Left(ValidationFailure('Email tidak valid.'));
    }
    if (params.password.length < 8) {
      return const Left(ValidationFailure('Password minimal 8 karakter dengan kombinasi huruf dan angka.'));
    }
    return await repository.register(
      name: params.name.trim(),
      email: params.email.trim(),
      phone: params.phone?.trim(),
      password: params.password,
    );
  }
}
