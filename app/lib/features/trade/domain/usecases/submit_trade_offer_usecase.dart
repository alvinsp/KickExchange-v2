import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/trade_offer_entity.dart';
import '../repositories/trade_repository.dart';

class SubmitTradeParams {
  final String offeredProductId;
  final String targetProductId;
  final double cashAdjustment;
  final String notes;

  SubmitTradeParams({
    required this.offeredProductId,
    required this.targetProductId,
    required this.cashAdjustment,
    required this.notes,
  });
}

class SubmitTradeOfferUseCase implements UseCase<TradeOfferEntity, SubmitTradeParams> {
  final TradeRepository repository;
  SubmitTradeOfferUseCase(this.repository);

  @override
  Future<Either<Failure, TradeOfferEntity>> call(SubmitTradeParams params) async {
    if (params.offeredProductId == params.targetProductId) {
      return const Left(ValidationFailure('Tidak dapat menukar dengan sepatu yang sama.'));
    }
    return await repository.createTradeOffer(
      offeredProductId: params.offeredProductId,
      targetProductId: params.targetProductId,
      cashAdjustment: params.cashAdjustment,
      notes: params.notes,
    );
  }
}
