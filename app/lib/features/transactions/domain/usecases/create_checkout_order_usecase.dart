import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/transaction_entity.dart';
import '../repositories/transaction_repository.dart';

class CreateOrderParams {
  final String? productId;
  final String? tradeId;
  final String paymentChannel; // QRIS, BCA, BNI, BRI, MANDIRI

  CreateOrderParams({
    this.productId,
    this.tradeId,
    required this.paymentChannel,
  });
}

class CreateCheckoutOrderUseCase implements UseCase<TransactionEntity, CreateOrderParams> {
  final TransactionRepository repository;
  CreateCheckoutOrderUseCase(this.repository);

  @override
  Future<Either<Failure, TransactionEntity>> call(CreateOrderParams params) async {
    if (params.productId == null && params.tradeId == null) {
      return const Left(ValidationFailure('Pilih sepatu yang ingin dibeli atau trade yang ingin dilunasi.'));
    }
    return await repository.createTransaction(
      productId: params.productId,
      tradeId: params.tradeId,
      paymentChannel: params.paymentChannel,
    );
  }
}
