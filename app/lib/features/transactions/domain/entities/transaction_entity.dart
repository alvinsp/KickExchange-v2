import 'package:equatable/equatable.dart';
import '../../../products/domain/entities/product_entity.dart';

class TransactionEntity extends Equatable {
  final String id;
  final String reference;
  final String idempotencyKey;
  final String type; // PURCHASE, TRADE_CASH_DIFF
  final String payerId;
  final String payeeId;
  final String? productId;
  final String? tradeId;
  final double baseAmount;
  final int uniqueCode; // 3-digit verification suffix
  final double totalAmount; // baseAmount + uniqueCode
  final String status; // PENDING_PAYMENT, PAID, EXPIRED, CANCELLED, FAILED
  final String paymentChannel; // QRIS, BCA, BNI, BRI, MANDIRI
  final String paymentProvider; // xendit, simulator
  final String? providerPaymentId;
  final String? qrString;
  final String? vaNumber;
  final DateTime transactionDate;
  final DateTime expiresAt;
  final DateTime? paidAt;
  final bool isSynced;
  final String? payerName;
  final String? payeeName;
  final ProductEntity? product;

  const TransactionEntity({
    required this.id,
    required this.reference,
    required this.idempotencyKey,
    required this.type,
    required this.payerId,
    required this.payeeId,
    this.productId,
    this.tradeId,
    required this.baseAmount,
    required this.uniqueCode,
    required this.totalAmount,
    required this.status,
    required this.paymentChannel,
    this.paymentProvider = 'simulator',
    this.providerPaymentId,
    this.qrString,
    this.vaNumber,
    required this.transactionDate,
    required this.expiresAt,
    this.paidAt,
    this.isSynced = true,
    this.payerName,
    this.payeeName,
    this.product,
  });

  @override
  List<Object?> get props => [
        id,
        reference,
        idempotencyKey,
        type,
        payerId,
        payeeId,
        productId,
        tradeId,
        baseAmount,
        uniqueCode,
        totalAmount,
        status,
        paymentChannel,
        paymentProvider,
        providerPaymentId,
        qrString,
        vaNumber,
        transactionDate,
        expiresAt,
        paidAt,
        isSynced,
        payerName,
        payeeName,
        product,
      ];
}
