import 'package:equatable/equatable.dart';
import '../../domain/entities/trade_offer_entity.dart';

abstract class TradeState extends Equatable {
  const TradeState();

  @override
  List<Object?> get props => [];
}

class TradeInitial extends TradeState {}

class TradeLoading extends TradeState {
  final String message;
  const TradeLoading({this.message = 'Memuat data trade...'});

  @override
  List<Object?> get props => [message];
}

class TradeLoaded extends TradeState {
  final List<TradeOfferEntity> trades;
  const TradeLoaded(this.trades);

  @override
  List<Object?> get props => [trades];
}

class TradeEmpty extends TradeState {
  final String message;
  const TradeEmpty({this.message = 'Belum ada tawaran tukar/barter sepatu.'});

  @override
  List<Object?> get props => [message];
}

class TradeActionSuccess extends TradeState {
  final String message;
  final TradeOfferEntity? trade;

  const TradeActionSuccess(this.message, {this.trade});

  @override
  List<Object?> get props => [message, trade];
}

class TradeFailureState extends TradeState {
  final String errorMessage;
  const TradeFailureState(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}
