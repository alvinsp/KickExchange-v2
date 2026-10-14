import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../domain/usecases/create_checkout_order_usecase.dart';
import 'transaction_event.dart';
import 'transaction_state.dart';

class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final CreateCheckoutOrderUseCase createCheckoutOrderUseCase;
  final TransactionRepository transactionRepository;

  TransactionBloc({
    required this.createCheckoutOrderUseCase,
    required this.transactionRepository,
  }) : super(TransactionInitial()) {
    on<LoadTransactionsEvent>(_onLoadTransactions);
    on<CreateTransactionSubmittedEvent>(_onCreateTransaction);
    on<SimulatePaymentEvent>(_onSimulatePayment);
  }

  Future<void> _onLoadTransactions(
    LoadTransactionsEvent event,
    Emitter<TransactionState> emit,
  ) async {
    emit(const TransactionLoading());
    final result = await transactionRepository.getTransactions();
    result.fold(
      (failure) => emit(TransactionFailureState(failure.message)),
      (transactions) {
        if (transactions.isEmpty) {
          emit(TransactionEmpty());
        } else {
          emit(TransactionLoaded(transactions));
        }
      },
    );
  }

  Future<void> _onCreateTransaction(
    CreateTransactionSubmittedEvent event,
    Emitter<TransactionState> emit,
  ) async {
    emit(const TransactionLoading(message: 'Mengunci harga & membuat kode pembayaran...'));
    final result = await createCheckoutOrderUseCase(
      CreateOrderParams(
        productId: event.productId,
        tradeId: event.tradeId,
        paymentChannel: event.paymentChannel,
      ),
    );

    result.fold(
      (failure) => emit(TransactionFailureState(failure.message)),
      (transaction) {
        emit(TransactionCreatedSuccess(transaction));
        add(LoadTransactionsEvent());
      },
    );
  }

  Future<void> _onSimulatePayment(
    SimulatePaymentEvent event,
    Emitter<TransactionState> emit,
  ) async {
    emit(const TransactionLoading(message: 'Memverifikasi pembayaran...'));
    final result = await transactionRepository.simulatePayment(event.reference);

    result.fold(
      (failure) => emit(TransactionFailureState(failure.message)),
      (transaction) {
        emit(PaymentSettledSuccess(transaction));
        add(LoadTransactionsEvent());
      },
    );
  }
}
