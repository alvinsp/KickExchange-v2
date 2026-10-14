import 'package:equatable/equatable.dart';

abstract class TradeEvent extends Equatable {
  const TradeEvent();

  @override
  List<Object?> get props => [];
}

class LoadTradesEvent extends TradeEvent {
  final String type; // all, incoming, outgoing
  const LoadTradesEvent({this.type = 'all'});

  @override
  List<Object?> get props => [type];
}

class SubmitTradeOfferEvent extends TradeEvent {
  final String offeredProductId;
  final String targetProductId;
  final double cashAdjustment;
  final String notes;

  const SubmitTradeOfferEvent({
    required this.offeredProductId,
    required this.targetProductId,
    required this.cashAdjustment,
    required this.notes,
  });

  @override
  List<Object?> get props => [offeredProductId, targetProductId, cashAdjustment, notes];
}

class ApplyTradeActionEvent extends TradeEvent {
  final String tradeId;
  final String action; // accept, reject, cancel

  const ApplyTradeActionEvent({required this.tradeId, required this.action});

  @override
  List<Object?> get props => [tradeId, action];
}
