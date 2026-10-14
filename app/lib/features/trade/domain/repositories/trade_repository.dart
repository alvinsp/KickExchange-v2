import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/trade_offer_entity.dart';

abstract class TradeRepository {
  Future<Either<Failure, List<TradeOfferEntity>>> getTrades({String type = 'all'});
  Future<Either<Failure, TradeOfferEntity>> getTradeById(String tradeId);

  Future<Either<Failure, TradeOfferEntity>> createTradeOffer({
    required String offeredProductId,
    required String targetProductId,
    required double cashAdjustment,
    required String notes,
  });

  Future<Either<Failure, TradeOfferEntity>> applyTradeAction({
    required String tradeId,
    required String action, // accept, reject, cancel
  });
}
