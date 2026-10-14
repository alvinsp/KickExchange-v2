import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/trade_offer_entity.dart';
import '../repositories/trade_repository.dart';

class ApplyTradeActionParams {
  final String tradeId;
  final String action; // accept, reject, cancel

  ApplyTradeActionParams({required this.tradeId, required this.action});
}

class ApplyTradeActionUseCase implements UseCase<TradeOfferEntity, ApplyTradeActionParams> {
  final TradeRepository repository;
  ApplyTradeActionUseCase(this.repository);

  @override
  Future<Either<Failure, TradeOfferEntity>> call(ApplyTradeActionParams params) async {
    return await repository.applyTradeAction(
      tradeId: params.tradeId,
      action: params.action,
    );
  }
}
