import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class CheckAuthSessionEvent extends AuthEvent {}

class LoginSubmittedEvent extends AuthEvent {
  final String email;
  final String password;

  const LoginSubmittedEvent({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class RegisterSubmittedEvent extends AuthEvent {
  final String name;
  final String email;
  final String? phone;
  final String password;

  const RegisterSubmittedEvent({
    required this.name,
    required this.email,
    this.phone,
    required this.password,
  });

  @override
  List<Object?> get props => [name, email, phone, password];
}

class LogoutRequestedEvent extends AuthEvent {}
