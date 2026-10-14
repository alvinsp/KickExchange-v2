import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../injection_container.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../sync/presentation/widgets/sync_status_banner.dart';
import '../../../transactions/presentation/pages/checkout_page.dart';
import '../../domain/entities/trade_offer_entity.dart';
import '../bloc/trade_bloc.dart';
import '../bloc/trade_event.dart';
import '../bloc/trade_state.dart';

class TradeOffersPage extends StatefulWidget {
  const TradeOffersPage({super.key});

  @override
  State<TradeOffersPage> createState() => _TradeOffersPageState();
}

class _TradeOffersPageState extends State<TradeOffersPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCurrentUser();
    _fetchTrades();
  }

  void _loadCurrentUser() async {
    final userRes = await sl<AuthRepository>().getCurrentUser();
    userRes.fold((_) => null, (u) {
      if (mounted) setState(() => _currentUserId = u?.id);
    });
  }

  void _fetchTrades() {
    context.read<TradeBloc>().add(const LoadTradesEvent(type: 'all'));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BARTER & TRADE SNEAKER 🔄'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.neonVolt,
          labelColor: AppColors.neonVolt,
          unselectedLabelColor: AppColors.textGreySecondary,
          tabs: const [
            Tab(text: 'Semua'),
            Tab(text: 'Tawaran Masuk'),
            Tab(text: 'Tawaran Saya'),
          ],
        ),
      ),
      body: Column(
        children: [
          const SyncStatusBanner(),
          Expanded(
            child: BlocConsumer<TradeBloc, TradeState>(
              listener: (context, state) {
                if (state is TradeActionSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.stateSuccess,
                      content: Text(state.message),
                    ),
                  );
                } else if (state is TradeFailureState) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.stateDanger,
                      content: Text(state.errorMessage),
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is TradeLoading) {
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

                if (state is TradeFailureState) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: AppColors.stateDanger),
                        const SizedBox(height: AppDimens.space16),
                        Text(state.errorMessage, textAlign: TextAlign.center),
                        const SizedBox(height: AppDimens.space16),
                        ElevatedButton(
                          onPressed: _fetchTrades,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is TradeEmpty) {
                  return _buildEmptyState();
                }

                if (state is TradeLoaded) {
                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTradeList(state.trades),
                      _buildTradeList(
                        state.trades.where((t) => t.receiverId == _currentUserId).toList(),
                        emptyMessage: 'Belum ada tawaran barter masuk dari pengguna lain.',
                      ),
                      _buildTradeList(
                        state.trades.where((t) => t.senderId == _currentUserId).toList(),
                        emptyMessage: 'Anda belum mengajukan tawaran barter ke sneaker manapun.',
                      ),
                    ],
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

  Widget _buildEmptyState([String message = 'Belum ada riwayat tawaran barter sepatu.']) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.space32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.swap_horiz_rounded, size: 64, color: AppColors.borderGrey),
            const SizedBox(height: AppDimens.space16),
            const Text(
              'Belum Ada Trade Aktif',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppDimens.space8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textGreySecondary),
            ),
            const SizedBox(height: AppDimens.space24),
            OutlinedButton(
              onPressed: _fetchTrades,
              child: const Text('Refresh Data'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTradeList(List<TradeOfferEntity> list, {String? emptyMessage}) {
    if (list.isEmpty) {
      return _buildEmptyState(emptyMessage ?? 'Tidak ada data barter pada tab ini.');
    }

    return RefreshIndicator(
      color: AppColors.neonVolt,
      onRefresh: () async => _fetchTrades(),
      child: ListView.separated(
        padding: const EdgeInsets.all(AppDimens.space16),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppDimens.space16),
        itemBuilder: (context, index) {
          final trade = list[index];
          return _buildTradeCard(trade);
        },
      ),
    );
  }

  Widget _buildTradeCard(TradeOfferEntity trade) {
    final isSender = trade.senderId == _currentUserId;
    final isReceiver = trade.receiverId == _currentUserId;
    final isPending = trade.status.toUpperCase() == 'PENDING';
    final isAccepted = trade.status.toUpperCase() == 'ACCEPTED';

    Color statusColor;
    String statusLabel = trade.status.toUpperCase();
    switch (statusLabel) {
      case 'ACCEPTED':
        statusColor = AppColors.stateSuccess;
        break;
      case 'PENDING':
        statusColor = AppColors.stateWarning;
        break;
      case 'REJECTED':
      case 'CANCELLED':
        statusColor = AppColors.stateDanger;
        break;
      default:
        statusColor = AppColors.electricCyan;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Row: Status badge & Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: statusColor),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: AppDimens.space8),
                    if (!trade.isSynced)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.stateOffline,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.cloud_off, size: 10, color: Colors.white),
                            SizedBox(width: 2),
                            Text(
                              'OFFLINE QUEUED',
                              style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                Text(
                  DateFormatter.formatDateTime(trade.createdAt),
                  style: const TextStyle(color: AppColors.textGreySecondary, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: AppDimens.space16),

            // Sneakers Comparison Visual
            Container(
              padding: const EdgeInsets.all(AppDimens.space12),
              decoration: BoxDecoration(
                color: AppColors.elevatedCardDark,
                borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
              ),
              child: Row(
                children: [
                  // Offered Sneaker
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isSender ? 'Sepatu Saya (Ditawarkan)' : 'Sepatu Penawar',
                          style: const TextStyle(fontSize: 10, color: AppColors.textGreySecondary, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          trade.offeredProduct?.name ?? 'Sneaker Ditawarkan',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        if (trade.offeredProduct != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'US ${trade.offeredProduct!.sizeUs} • ${trade.offeredProduct!.condition}',
                            style: const TextStyle(color: AppColors.textGreySecondary, fontSize: 11),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Swap Icon
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppDimens.space8),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.surfaceCardDark,
                      child: Icon(Icons.swap_horiz, color: AppColors.solarOrange, size: 20),
                    ),
                  ),

                  // Target Sneaker
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          isReceiver ? 'Sepatu Saya (Target)' : 'Sepatu Tujuan',
                          style: const TextStyle(fontSize: 10, color: AppColors.textGreySecondary, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          trade.targetProduct?.name ?? 'Sneaker Target',
                          textAlign: TextAlign.end,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        if (trade.targetProduct != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'US ${trade.targetProduct!.sizeUs} • ${trade.targetProduct!.condition}',
                            textAlign: TextAlign.end,
                            style: const TextStyle(color: AppColors.textGreySecondary, fontSize: 11),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.space12),

            // Cash Adjustment Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.space12, vertical: AppDimens.space8),
              decoration: BoxDecoration(
                color: AppColors.inputFillDark,
                borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Penyesuaian Nilai (Cash Diff):', style: TextStyle(fontSize: 12, color: AppColors.textGreySecondary)),
                  Text(
                    trade.cashAdjustment == 0
                        ? 'Tukar Lepas (Rp 0)'
                        : trade.cashAdjustment > 0
                            ? '+ ${CurrencyFormatter.format(trade.cashAdjustment)} (Penawar Nombok)'
                            : '- ${CurrencyFormatter.format(trade.cashAdjustment.abs())} (Penerima Nombok)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: trade.cashAdjustment == 0 ? AppColors.textWhitePrimary : AppColors.neonVolt,
                    ),
                  ),
                ],
              ),
            ),

            if (trade.notes.isNotEmpty) ...[
              const SizedBox(height: AppDimens.space8),
              Text(
                'Catatan: "${trade.notes}"',
                style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textGreySecondary),
              ),
            ],

            const SizedBox(height: AppDimens.space16),

            // Action Buttons
            if (isPending) ...[
              if (isReceiver)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          context.read<TradeBloc>().add(
                                ApplyTradeActionEvent(tradeId: trade.id, action: 'reject'),
                              );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.stateDanger,
                          side: const BorderSide(color: AppColors.stateDanger),
                        ),
                        child: const Text('TOLAK'),
                      ),
                    ),
                    const SizedBox(width: AppDimens.space12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          context.read<TradeBloc>().add(
                                ApplyTradeActionEvent(tradeId: trade.id, action: 'accept'),
                              );
                        },
                        child: const Text('TERIMA BARTER'),
                      ),
                    ),
                  ],
                ),
              if (isSender)
                OutlinedButton(
                  onPressed: () {
                    context.read<TradeBloc>().add(
                          ApplyTradeActionEvent(tradeId: trade.id, action: 'cancel'),
                        );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.stateDanger,
                    side: const BorderSide(color: AppColors.stateDanger),
                  ),
                  child: const Text('BATALKAN TAWARAN'),
                ),
            ],

            // If trade accepted and user owes cash adjustment, show Checkout button
            if (isAccepted &&
                ((isSender && trade.cashAdjustment > 0) || (isReceiver && trade.cashAdjustment < 0))) ...[
              const SizedBox(height: AppDimens.space8),
              ElevatedButton.icon(
                icon: const Icon(Icons.payment, color: Colors.black),
                label: Text(
                  'BAYAR SELISIH (${CurrencyFormatter.format(trade.cashAdjustment.abs())})',
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CheckoutPage(tradeOffer: trade),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
