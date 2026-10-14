import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/transaction_entity.dart';
import '../bloc/transaction_bloc.dart';
import '../bloc/transaction_event.dart';
import '../bloc/transaction_state.dart';
import 'order_history_page.dart';

class PaymentDetailPage extends StatefulWidget {
  final TransactionEntity transaction;

  const PaymentDetailPage({super.key, required this.transaction});

  @override
  State<PaymentDetailPage> createState() => _PaymentDetailPageState();
}

class _PaymentDetailPageState extends State<PaymentDetailPage> {
  late TransactionEntity _currentTx;
  Timer? _countdownTimer;
  Duration _remainingTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _currentTx = widget.transaction;
    _initCountdown();
  }

  void _initCountdown() {
    final now = DateTime.now();
    if (_currentTx.expiresAt.isAfter(now)) {
      _remainingTime = _currentTx.expiresAt.difference(now);
    } else {
      _remainingTime = Duration.zero;
    }

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remainingTime.inSeconds <= 0) {
        timer.cancel();
      } else {
        setState(() {
          _remainingTime = _remainingTime - const Duration(seconds: 1);
        });
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    if (d.inSeconds <= 0) return '00:00 (KADALUARSA)';
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.stateSuccess,
        content: Text('$label berhasil disalin ke papan klip.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPaid = _currentTx.status.toUpperCase() == 'PAID' ||
        _currentTx.status.toUpperCase() == 'PAID_SETTLED';
    final isQris = _currentTx.paymentChannel.toUpperCase() == 'QRIS';
    final hasVa = _currentTx.vaNumber != null && _currentTx.vaNumber!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('TAGIHAN PEMBAYARAN'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: AppColors.neonVolt),
            tooltip: 'Riwayat Transaksi',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OrderHistoryPage()),
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<TransactionBloc, TransactionState>(
        listener: (context, state) {
          if (state is PaymentSettledSuccess) {
            setState(() {
              _currentTx = state.transaction;
            });
            _showPaymentSuccessDialog();
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
          final isSimulating = state is TransactionLoading;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimens.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Status Header Banner
                _buildStatusBanner(isPaid),
                const SizedBox(height: AppDimens.space20),

                // Total Payable Card with 3-digit highlight
                _buildAmountCard(isPaid),
                const SizedBox(height: AppDimens.space20),

                // Channel Detail: QRIS or Bank VA
                if (!isPaid) ...[
                  if (isQris) _buildQrisSection(),
                  if (!isQris && hasVa) _buildVaSection(),
                  const SizedBox(height: AppDimens.space24),
                ],

                // Transaction Meta Info
                _buildTransactionMetaCard(),
                const SizedBox(height: AppDimens.space24),

                // Simulator or Action Buttons
                if (!isPaid) ...[
                  ElevatedButton.icon(
                    icon: isSimulating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                          )
                        : const Icon(Icons.flash_on, color: Colors.black),
                    label: Text(
                      isSimulating
                          ? 'Memproses Pelunasan...'
                          : 'SIMULASI BAYAR SEKARANG (INSTANT SETTLE)',
                    ),
                    onPressed: isSimulating
                        ? null
                        : () {
                            context.read<TransactionBloc>().add(
                                  SimulatePaymentEvent(_currentTx.reference),
                                );
                          },
                  ),
                  const SizedBox(height: AppDimens.space12),
                  const Center(
                    child: Text(
                      'Mode Simulasi / Xendit Sandbox: Tekan tombol di atas untuk melunasi tagihan seketika.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: AppColors.textGreySecondary),
                    ),
                  ),
                ] else ...[
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const OrderHistoryPage()),
                      );
                    },
                    child: const Text('LIHAT DAFTAR TRANSAKSI SAYA'),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusBanner(bool isPaid) {
    if (isPaid) {
      return Container(
        padding: const EdgeInsets.all(AppDimens.space16),
        decoration: BoxDecoration(
          color: AppColors.stateSuccess.withOpacity(0.15),
          borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
          border: Border.all(color: AppColors.stateSuccess),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.stateSuccess, size: 32),
            SizedBox(width: AppDimens.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PEMBAYARAN LUNAS (PAID)', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.stateSuccess, fontSize: 16)),
                  SizedBox(height: 2),
                  Text('Pesanan sneaker berhasil diverifikasi & dikunci.', style: TextStyle(color: AppColors.textWhitePrimary, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppDimens.space16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCardDark,
        borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
        border: Border.all(color: AppColors.stateWarning),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.timer_outlined, color: AppColors.stateWarning, size: 28),
              SizedBox(width: AppDimens.space12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('MENUNGGU PEMBAYARAN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  SizedBox(height: 2),
                  Text('Selesaikan sebelum waktu habis', style: TextStyle(color: AppColors.textGreySecondary, fontSize: 11)),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.backgroundBlack,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.borderGrey),
            ),
            child: Text(
              _formatDuration(_remainingTime),
              style: const TextStyle(
                color: AppColors.neonVolt,
                fontWeight: FontWeight.w900,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountCard(bool isPaid) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.space20),
      decoration: BoxDecoration(
        color: AppColors.surfaceCardDark,
        borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total yang Harus Ditransfer:', style: TextStyle(color: AppColors.textGreySecondary, fontSize: 13)),
              if (!isPaid)
                GestureDetector(
                  onTap: () => _copyToClipboard(_currentTx.totalAmount.toStringAsFixed(0), 'Total nominal'),
                  child: const Row(
                    children: [
                      Icon(Icons.copy, size: 14, color: AppColors.neonVolt),
                      SizedBox(width: 4),
                      Text('Salin', style: TextStyle(color: AppColors.neonVolt, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppDimens.space8),
          Text(
            CurrencyFormatter.format(_currentTx.totalAmount),
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: AppColors.neonVolt,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: AppDimens.space8),
          Container(
            padding: const EdgeInsets.all(AppDimens.space8),
            decoration: BoxDecoration(
              color: AppColors.inputFillDark,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: AppColors.electricCyan),
                const SizedBox(width: AppDimens.space8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 11, color: AppColors.textGreySecondary),
                      children: [
                        const TextSpan(text: 'Transfer tepat hingga 3 digit terakhir ('),
                        TextSpan(
                          text: 'Kode Unik: ${_currentTx.uniqueCode}',
                          style: const TextStyle(color: AppColors.electricCyan, fontWeight: FontWeight.bold),
                        ),
                        const TextSpan(text: ') untuk verifikasi otomatis.'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrisSection() {
    final qrData = _currentTx.qrString ?? _currentTx.reference;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.space20),
        child: Column(
          children: [
            const Text(
              'Pindai QRIS Dinamis',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            const Text(
              'Buka BCA Mobile, GoPay, OVO, Dana, Livin atau ShopeePay lalu scan QR di bawah:',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textGreySecondary, fontSize: 12),
            ),
            const SizedBox(height: AppDimens.space20),
            // QR Container on pure white background
            Container(
              padding: const EdgeInsets.all(AppDimens.space16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 220.0,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: AppDimens.space16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.qr_code, size: 16, color: AppColors.textGreySecondary),
                const SizedBox(width: 6),
                Text(
                  'NMID / Ref: ${_currentTx.reference}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textGreySecondary, fontFamily: 'monospace'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVaSection() {
    final va = _currentTx.vaNumber ?? '-';
    final bank = _currentTx.paymentChannel.toUpperCase();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.space20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Nomor Virtual Account $bank',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: AppDimens.space12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.space16, vertical: AppDimens.space12),
              decoration: BoxDecoration(
                color: AppColors.inputFillDark,
                borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                border: Border.all(color: AppColors.borderGrey),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    va,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: AppColors.textWhitePrimary,
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    icon: const Icon(Icons.copy, size: 14, color: Colors.black),
                    label: const Text('Salin VA', style: TextStyle(fontSize: 12)),
                    onPressed: () => _copyToClipboard(va, 'Nomor Virtual Account'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.space16),
            const Text(
              'Petunjuk Transfer M-Banking:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 6),
            const Text('1. Buka Mobile Banking bank Anda lalu pilih menu Transfer / Pembayaran.', style: TextStyle(fontSize: 11, color: AppColors.textGreySecondary)),
            const Text('2. Pilih Virtual Account / Tagihan dan masukkan nomor VA di atas.', style: TextStyle(fontSize: 11, color: AppColors.textGreySecondary)),
            const Text('3. Periksa kesesuaian nama & jumlah total tagihan, lalu konfirmasi pembayaran.', style: TextStyle(fontSize: 11, color: AppColors.textGreySecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionMetaCard() {
    return Container(
      padding: const EdgeInsets.all(AppDimens.space16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCardDark,
        borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Column(
        children: [
          _buildMetaRow('No. Referensi', _currentTx.reference),
          const Divider(height: 16, color: AppColors.borderGrey),
          _buildMetaRow('Metode Pembayaran', _currentTx.paymentChannel),
          const Divider(height: 16, color: AppColors.borderGrey),
          _buildMetaRow('Waktu Transaksi', DateFormatter.formatDateTime(_currentTx.transactionDate)),
          const Divider(height: 16, color: AppColors.borderGrey),
          _buildMetaRow('Batas Waktu', DateFormatter.formatDateTime(_currentTx.expiresAt)),
          const Divider(height: 16, color: AppColors.borderGrey),
          _buildMetaRow('Sinkronisasi Lokal', _currentTx.isSynced ? 'Synced Online' : 'Disimpan Lokal (Queue)'),
        ],
      ),
    );
  }

  Widget _buildMetaRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textGreySecondary, fontSize: 12)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
      ],
    );
  }

  void _showPaymentSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceCardDark,
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.stateSuccess, size: 28),
              SizedBox(width: 8),
              Text('Pembayaran Berhasil!'),
            ],
          ),
          content: const Text(
            'Selamat! Pembayaran sneaker telah terverifikasi secara instan. Kepemilikan sneaker kini terdaftar pada akun Anda.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const OrderHistoryPage()),
                );
              },
              child: const Text('Buka Riwayat Pesanan'),
            ),
          ],
        );
      },
    );
  }
}
