import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/trade_repository.dart';
import '../../domain/usecases/apply_trade_action_usecase.dart';
import '../../domain/usecases/submit_trade_offer_usecase.dart';
import 'trade_event.dart';
import 'trade_state.dart';

class TradeBloc extends Bloc<TradeEvent, TradeState> {
  final SubmitTradeOfferUseCase submitTradeOfferUseCase;
  final ApplyTradeActionUseCase applyTradeActionUseCase;
  final TradeRepository tradeRepository;

  TradeBloc({
    required this.submitTradeOfferUseCase,
    required this.applyTradeActionUseCase,
    required this.tradeRepository,
  }) : super(TradeInitial()) {
    on<LoadTradesEvent>(_onLoadTrades);
    on<SubmitTradeOfferEvent>(_onSubmitTradeOffer);
    on<ApplyTradeActionEvent>(_onApplyTradeAction);
  }

  Future<void> _onLoadTrades(
    LoadTradesEvent event,
    Emitter<TradeState> emit,
  ) async {
    emit(const TradeLoading());
    final result = await tradeRepository.getTrades(type: event.type);
    result.fold(
      (failure) => emit(TradeFailureState(failure.message)),
      (trades) {
        if (trades.isEmpty) {
          emit(const TradeEmpty());
        } else {
          emit(TradeLoaded(trades));
        }
      },
    );
  }

  Future<void> _onSubmitTradeOffer(
    SubmitTradeOfferEvent event,
    Emitter<TradeState> emit,
  ) async {
    emit(const TradeLoading(message: 'Mengajukan penawaran barter sepatu...'));
    final result = await submitTradeOfferUseCase(
      SubmitTradeParams(
        offeredProductId: event.offeredProductId,
        targetProductId: event.targetProductId,
        cashAdjustment: event.cashAdjustment,
        notes: event.notes,
      ),
    );

    result.fold(
      (failure) => emit(TradeFailureState(failure.message)),
      (trade) {
        final offlineNote = trade.isSynced ? '' : ' (Disimpan offline, antrean sync aktif)';
        emit(TradeActionSuccess('Tawaran barter berhasil dikirim!$offlineNote', trade: trade));
        add(const LoadTradesEvent());
      },
    );
  }

  Future<void> _onApplyTradeAction(
    ApplyTradeActionEvent event,
    Emitter<TradeState> emit,
  ) async {
    emit(TradeLoading(message: 'Memproses aksi ${event.action}...'));
    final result = await applyTradeActionUseCase(
      ApplyTradeActionParams(
        tradeId: event.tradeId,
        action: event.action,
      ),
    );

    result.fold(
      (failure) => emit(TradeFailureState(failure.message)),
      (trade) {
        emit(TradeActionSuccess('Aksi berhasil diterapkan: Status kini ${trade.status}', trade: trade));
        add(const LoadTradesEvent());
      },
    );
  }
}
