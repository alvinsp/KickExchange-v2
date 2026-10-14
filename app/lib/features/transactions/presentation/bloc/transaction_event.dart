import 'package:equatable/equatable.dart';

abstract class TransactionEvent extends Equatable {
  const TransactionEvent();

  @override
  List<Object?> get props => [];
}

class LoadTransactionsEvent extends TransactionEvent {}

class CreateTransactionSubmittedEvent extends TransactionEvent {
  final String? productId;
  final String? tradeId;
  final String paymentChannel; // QRIS, BCA, BNI, BRI, MANDIRI

  const CreateTransactionSubmittedEvent({
    this.productId,
    this.tradeId,
    required this.paymentChannel,
  });

  @override
  List<Object?> get props => [productId, tradeId, paymentChannel];
}

class SimulatePaymentEvent extends TransactionEvent {
  final String reference;
  const SimulatePaymentEvent(this.reference);

  @override
  List<Object?> get props => [reference];
}
