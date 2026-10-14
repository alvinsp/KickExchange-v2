import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../sync/presentation/widgets/sync_status_banner.dart';
import '../../domain/entities/transaction_entity.dart';
import '../bloc/transaction_bloc.dart';
import '../bloc/transaction_event.dart';
import '../bloc/transaction_state.dart';
import 'payment_detail_page.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  void _fetchTransactions() {
    context.read<TransactionBloc>().add(LoadTransactionsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RIWAYAT TRANSAKSI 💳'),
      ),
      body: Column(
        children: [
          const SyncStatusBanner(),
          Expanded(
            child: BlocBuilder<TransactionBloc, TransactionState>(
              builder: (context, state) {
                if (state is TransactionLoading) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(color: AppColors.neonVolt),
                        const SizedBox(height: AppDimens.space16),
                        Text(
                          state.message,
                          style: const TextStyle(color: AppColors.textGreySecondary),
                        ),
                      ],
                    ),
                  );
                }

                if (state is TransactionFailureState) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppDimens.space24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: AppColors.stateDanger),
                          const SizedBox(height: AppDimens.space16),
                          Text(state.errorMessage, textAlign: TextAlign.center),
                          const SizedBox(height: AppDimens.space16),
                          ElevatedButton(
                            onPressed: _fetchTransactions,
                            child: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (state is TransactionEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppDimens.space32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.borderGrey),
                          const SizedBox(height: AppDimens.space16),
                          const Text(
                            'Belum Ada Transaksi',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: AppDimens.space8),
                          const Text(
                            'Transaksi pembelian atau pembayaran selisih barter akan tercatat di sini.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textGreySecondary),
                          ),
                          const SizedBox(height: AppDimens.space24),
                          OutlinedButton(
                            onPressed: _fetchTransactions,
                            child: const Text('Refresh Data'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (state is TransactionLoaded) {
                  return RefreshIndicator(
                    color: AppColors.neonVolt,
                    onRefresh: () async => _fetchTransactions(),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(AppDimens.space16),
                      itemCount: state.transactions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: AppDimens.space12),
                      itemBuilder: (context, index) {
                        final tx = state.transactions[index];
                        return _buildTransactionCard(tx);
                      },
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(TransactionEntity tx) {
    final isPaid = tx.status.toUpperCase() == 'PAID' || tx.status.toUpperCase() == 'PAID_SETTLED';
    final isPending = tx.status.toUpperCase() == 'PENDING_PAYMENT';

    Color statusColor;
    String statusText = tx.status.replaceAll('_', ' ').toUpperCase();
    if (isPaid) {
      statusColor = AppColors.stateSuccess;
      statusText = 'LUNAS (PAID)';
    } else if (isPending) {
      statusColor = AppColors.stateWarning;
      statusText = 'MENUNGGU BAYAR';
    } else {
      statusColor = AppColors.stateDanger;
    }

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PaymentDetailPage(transaction: tx),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top row: Ref & Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    tx.reference,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimens.space8),
              // Item / Sneaker name
              Text(
                tx.product != null
                    ? '${tx.product!.brand.toUpperCase()} - ${tx.product!.name}'
                    : tx.type == 'TRADE_CASH_DIFF'
                        ? 'Pembayaran Selisih Barter Sepatu 🔄'
                        : 'Sneaker Purchase Order',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: AppDimens.space8),
              // Details: Date, channel, and Total Amount
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormatter.formatDateTime(tx.transactionDate),
                        style: const TextStyle(color: AppColors.textGreySecondary, fontSize: 11),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Kanal: ${tx.paymentChannel}',
                        style: const TextStyle(color: AppColors.textGreySecondary, fontSize: 11),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        CurrencyFormatter.format(tx.totalAmount),
                        style: const TextStyle(
                          color: AppColors.neonVolt,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        'Kode Verif: ${tx.uniqueCode}',
                        style: const TextStyle(color: AppColors.electricCyan, fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
