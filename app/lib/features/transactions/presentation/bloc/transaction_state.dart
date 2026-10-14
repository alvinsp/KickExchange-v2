import 'package:equatable/equatable.dart';
import '../../domain/entities/transaction_entity.dart';

abstract class TransactionState extends Equatable {
  const TransactionState();

  @override
  List<Object?> get props => [];
}

class TransactionInitial extends TransactionState {}

class TransactionLoading extends TransactionState {
  final String message;
  const TransactionLoading({this.message = 'Memproses transaksi...'});

  @override
  List<Object?> get props => [message];
}

class TransactionLoaded extends TransactionState {
  final List<TransactionEntity> transactions;
  const TransactionLoaded(this.transactions);

  @override
  List<Object?> get props => [transactions];
}

class TransactionCreatedSuccess extends TransactionState {
  final TransactionEntity transaction;
  const TransactionCreatedSuccess(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

class PaymentSettledSuccess extends TransactionState {
  final TransactionEntity transaction;
  const PaymentSettledSuccess(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

class TransactionEmpty extends TransactionState {}

class TransactionFailureState extends TransactionState {
  final String errorMessage;
  const TransactionFailureState(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}
