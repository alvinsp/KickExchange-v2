import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? emailMasked;
  final String? phoneMasked;
  final DateTime? createdAt;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.emailMasked,
    this.phoneMasked,
    this.createdAt,
  });

  @override
  List<Object?> get props => [id, name, email, phone, emailMasked, phoneMasked, createdAt];
}
