import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/transaction_entity.dart';

abstract class TransactionRepository {
  Future<Either<Failure, List<TransactionEntity>>> getTransactions();
  Future<Either<Failure, TransactionEntity>> getTransactionById(String id);

  Future<Either<Failure, TransactionEntity>> createTransaction({
    String? productId,
    String? tradeId,
    required String paymentChannel,
  });

  Future<Either<Failure, TransactionEntity>> simulatePayment(String reference);
}
