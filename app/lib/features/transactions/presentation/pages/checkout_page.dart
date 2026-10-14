import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../products/domain/entities/product_entity.dart';
import '../../../trade/domain/entities/trade_offer_entity.dart';
import '../bloc/transaction_bloc.dart';
import '../bloc/transaction_event.dart';
import '../bloc/transaction_state.dart';
import 'payment_detail_page.dart';

class CheckoutPage extends StatefulWidget {
  final ProductEntity? product;
  final TradeOfferEntity? tradeOffer;

  const CheckoutPage({
    super.key,
    this.product,
    this.tradeOffer,
  }) : assert(product != null || tradeOffer != null, 'Product or TradeOffer must be provided');

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String _selectedPaymentChannel = 'QRIS';

  final List<Map<String, dynamic>> _channels = [
    {
      'id': 'QRIS',
      'name': 'Dynamic QRIS',
      'subtitle': 'Semua E-Wallet & Mobile Banking (GoPay, OVO, Dana, BCA, Livin)',
      'icon': Icons.qr_code_2,
    },
    {
      'id': 'BCA',
      'name': 'BCA Virtual Account',
      'subtitle': 'Transfer otomatis via KlikBCA, myBCA, ATM BCA',
      'icon': Icons.account_balance,
    },
    {
      'id': 'MANDIRI',
      'name': 'Mandiri Virtual Account',
      'subtitle': 'Transfer via Livin by Mandiri & ATM',
      'icon': Icons.account_balance,
    },
    {
      'id': 'BNI',
      'name': 'BNI Virtual Account',
      'subtitle': 'Transfer via BNI Mobile & ATM BNI',
      'icon': Icons.account_balance,
    },
    {
      'id': 'BRI',
      'name': 'BRI Virtual Account (BRIVA)',
      'subtitle': 'Transfer via BRImo & ATM BRI',
      'icon': Icons.account_balance,
    },
  ];

  bool get _isTradeCashDiff => widget.tradeOffer != null;

  double get _baseAmount {
    if (_isTradeCashDiff) {
      return widget.tradeOffer!.cashAdjustment.abs();
    }
    return widget.product!.price;
  }

  String get _title {
    if (_isTradeCashDiff) {
      return 'BAYAR SELISIH BARTER 🔄';
    }
    return 'CHECKOUT SNEAKER 👟';
  }

  void _submitCheckout() {
    context.read<TransactionBloc>().add(
          CreateTransactionSubmittedEvent(
            productId: widget.product?.id,
            tradeId: widget.tradeOffer?.id,
            paymentChannel: _selectedPaymentChannel,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: BlocConsumer<TransactionBloc, TransactionState>(
        listener: (context, state) {
          if (state is TransactionCreatedSuccess) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => PaymentDetailPage(transaction: state.transaction),
              ),
            );
          } else if (state is TransactionFailureState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AppColors.stateDanger,
                content: Text(state.errorMessage),
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is TransactionLoading;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimens.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Item Preview Card
                _buildItemSummaryCard(),
                const SizedBox(height: AppDimens.space20),

                // Payment Method Selector
                const Text(
                  'Pilih Metode Pembayaran (Xendit)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppDimens.space12),
                ..._channels.map((ch) => _buildChannelOption(ch)),

                const SizedBox(height: AppDimens.space24),

                // Price Breakdown Card
                _buildPriceBreakdownCard(),

                const SizedBox(height: AppDimens.space16),

                // Security & Idempotency Note
                Container(
                  padding: const EdgeInsets.all(AppDimens.space12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCardDark,
                    borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                    border: Border.all(color: AppColors.borderGrey),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.shield_outlined, color: AppColors.neonVolt, size: 24),
                      SizedBox(width: AppDimens.space12),
                      Expanded(
                        child: Text(
                          'Pembayaran terenkripsi & aman. Dilengkapi Idempotency Key otomatis guna mencegah double-spend saat offline sync.',
                          style: TextStyle(color: AppColors.textGreySecondary, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppDimens.space32),

                // Checkout Button
                ElevatedButton(
                  onPressed: isLoading ? null : _submitCheckout,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : Text(
                          'KUNCI & BAYAR SEKARANG (${CurrencyFormatter.format(_baseAmount)})',
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildItemSummaryCard() {
    if (_isTradeCashDiff) {
      final trade = widget.tradeOffer!;
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tagihan Barter Sepatu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: AppDimens.space8),
              Text(
                'Sepatu Ditawarkan: ${trade.offeredProduct?.name ?? "Sneaker Penawar"}',
                style: const TextStyle(color: AppColors.textGreySecondary, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                'Sepatu Target: ${trade.targetProduct?.name ?? "Sneaker Target"}',
                style: const TextStyle(color: AppColors.textGreySecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    final p = widget.product!;
    final hasImage = p.imageUrls.isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.space16),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
              child: SizedBox(
                width: 72,
                height: 72,
                child: hasImage
                    ? Image.network(
                        p.imageUrls.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
              ),
            ),
            const SizedBox(width: AppDimens.space16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.brand.toUpperCase(),
                    style: const TextStyle(fontSize: 10, color: AppColors.textGreySecondary, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    p.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Size US ${p.sizeUs} • ${p.condition}',
                    style: const TextStyle(color: AppColors.textGreySecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.format(p.price),
                    style: const TextStyle(color: AppColors.neonVolt, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelOption(Map<String, dynamic> ch) {
    final isSelected = _selectedPaymentChannel == ch['id'];

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.space8),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.neonVolt.withOpacity(0.08) : AppColors.surfaceCardDark,
        borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
        border: Border.all(
          color: isSelected ? AppColors.neonVolt : AppColors.borderGrey,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isSelected ? AppColors.neonVolt : AppColors.elevatedCardDark,
          child: Icon(ch['icon'] as IconData, color: isSelected ? Colors.black : AppColors.textWhitePrimary, size: 20),
        ),
        title: Text(ch['name'] as String, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(ch['subtitle'] as String, style: const TextStyle(fontSize: 11, color: AppColors.textGreySecondary)),
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: AppColors.neonVolt)
            : const Icon(Icons.radio_button_off, color: AppColors.borderGrey),
        onTap: () {
          setState(() => _selectedPaymentChannel = ch['id'] as String);
        },
      ),
    );
  }

  Widget _buildPriceBreakdownCard() {
    return Container(
      padding: const EdgeInsets.all(AppDimens.space16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCardDark,
        borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Rincian Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: AppDimens.space12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Nominal Dasar', style: TextStyle(color: AppColors.textGreySecondary)),
              Text(CurrencyFormatter.format(_baseAmount), style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: AppDimens.space8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Kode Verifikasi Acak (3-Digit)', style: TextStyle(color: AppColors.textGreySecondary)),
              Text('Disematkan Otomatis (Rp 100 - 999)', style: TextStyle(color: AppColors.electricCyan, fontSize: 12)),
            ],
          ),
          const SizedBox(height: AppDimens.space12),
          const Divider(height: 1, color: AppColors.borderGrey),
          const SizedBox(height: AppDimens.space12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Estimasi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Text(
                '~ ${CurrencyFormatter.format(_baseAmount)}',
                style: const TextStyle(color: AppColors.neonVolt, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.elevatedCardDark,
      child: const Center(
        child: Icon(Icons.sports_baseball_outlined, size: 28, color: AppColors.borderGrey),
      ),
    );
  }
}
