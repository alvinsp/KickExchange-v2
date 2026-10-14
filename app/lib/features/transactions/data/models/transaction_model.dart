import '../../domain/entities/transaction_entity.dart';
import '../../../products/data/models/product_model.dart';

class TransactionModel extends TransactionEntity {
  const TransactionModel({
    required super.id,
    required super.reference,
    required super.idempotencyKey,
    required super.type,
    required super.payerId,
    required super.payeeId,
    super.productId,
    super.tradeId,
    required super.baseAmount,
    required super.uniqueCode,
    required super.totalAmount,
    required super.status,
    required super.paymentChannel,
    super.paymentProvider = 'simulator',
    super.providerPaymentId,
    super.qrString,
    super.vaNumber,
    required super.transactionDate,
    required super.expiresAt,
    super.paidAt,
    super.isSynced = true,
    super.payerName,
    super.payeeName,
    super.product,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    ProductModel? product;
    if (json['product'] is Map) {
      product = ProductModel.fromJson(json['product'] as Map<String, dynamic>);
    }

    final payer = json['payer'];
    final payee = json['payee'];

    return TransactionModel(
      id: json['id'] as String,
      reference: json['reference'] as String,
      idempotencyKey: json['idempotency_key'] as String,
      type: json['type'] as String,
      payerId: json['payer_id'] as String,
      payeeId: json['payee_id'] as String,
      productId: json['product_id'] as String?,
      tradeId: json['trade_id'] as String?,
      baseAmount: (json['base_amount'] as num).toDouble(),
      uniqueCode: json['unique_code'] as int,
      totalAmount: (json['total_amount'] as num).toDouble(),
      status: json['status'] as String,
      paymentChannel: json['payment_channel'] as String,
      paymentProvider: (json['payment_provider'] as String?) ?? 'simulator',
      providerPaymentId: json['provider_payment_id'] as String?,
      qrString: json['qr_string'] as String?,
      vaNumber: json['va_number'] as String?,
      transactionDate: DateTime.parse(json['transaction_date'].toString()),
      expiresAt: DateTime.parse(json['expires_at'].toString()),
      paidAt: json['paid_at'] != null ? DateTime.tryParse(json['paid_at'].toString()) : null,
      isSynced: json['is_synced'] == null ? true : (json['is_synced'] == 1 || json['is_synced'] == true),
      payerName: payer is Map ? payer['name'] as String? : json['payer_name'] as String?,
      payeeName: payee is Map ? payee['name'] as String? : json['payee_name'] as String?,
      product: product,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reference': reference,
      'idempotency_key': idempotencyKey,
      'type': type,
      'payer_id': payerId,
      'payee_id': payeeId,
      'product_id': productId,
      'trade_id': tradeId,
      'base_amount': baseAmount.toInt(),
      'unique_code': uniqueCode,
      'total_amount': totalAmount.toInt(),
      'status': status,
      'payment_channel': paymentChannel,
      'payment_provider': paymentProvider,
      'provider_payment_id': providerPaymentId,
      'qr_string': qrString,
      'va_number': vaNumber,
      'transaction_date': transactionDate.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'paid_at': paidAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toSqliteRow() {
    return {
      'id': id,
      'reference': reference,
      'idempotency_key': idempotencyKey,
      'type': type,
      'payer_id': payerId,
      'payee_id': payeeId,
      'product_id': productId,
      'trade_id': tradeId,
      'base_amount': baseAmount,
      'unique_code': uniqueCode,
      'total_amount': totalAmount,
      'status': status,
      'payment_channel': paymentChannel,
      'payment_provider': paymentProvider,
      'qr_string': qrString,
      'va_number': vaNumber,
      'transaction_date': transactionDate.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'paid_at': paidAt?.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
    };
  }
}
