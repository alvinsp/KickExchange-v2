import 'package:flutter_test/flutter_test.dart';
import 'package:kick_exchange/core/security/data_masking.dart';
import 'package:kick_exchange/core/utils/currency_formatter.dart';
import 'package:kick_exchange/features/products/domain/entities/product_entity.dart';
import 'package:kick_exchange/features/trade/domain/entities/trade_offer_entity.dart';
import 'package:kick_exchange/features/transactions/domain/entities/transaction_entity.dart';

void main() {
  group('Clean Architecture Core Utilities & Domain Tests', () {
    test('CurrencyFormatter formats IDR correctly', () {
      final formatted = CurrencyFormatter.format(2500000);
      expect(formatted.contains('2.500.000'), isTrue);
      expect(formatted.startsWith('Rp'), isTrue);
    });

    test('DataMasking masks email according to UU PDP guidelines', () {
      expect(DataMasking.maskEmail('alvin@example.com'), 'al***@example.com');
      expect(DataMasking.maskEmail('user@test.org'), 'us***@test.org');
      expect(DataMasking.maskEmail(null), '-');
    });

    test('DataMasking masks phone numbers', () {
      final masked = DataMasking.maskPhone('081234567890');
      expect(masked.startsWith('0812-****-'), isTrue);
      expect(masked.endsWith('7890'), isTrue);
    });

    test('ProductEntity instantiation and copyWith', () {
      final now = DateTime.now();
      final product = ProductEntity(
        id: 'prod-1',
        ownerId: 'user-1',
        name: 'Air Jordan 1 Chicago',
        brand: 'Jordan',
        sizeUs: 10.5,
        price: 3500000,
        condition: 'BNIB',
        createdAt: now,
        updatedAt: now,
      );

      expect(product.isForSale, isTrue);
      expect(product.isForTrade, isTrue);
      expect(product.isSold, isFalse);

      final updated = product.copyWith(price: 3600000, isSold: true);
      expect(updated.price, 3600000);
      expect(updated.isSold, isTrue);
      expect(updated.name, 'Air Jordan 1 Chicago');
    });

    test('TradeOfferEntity cash adjustment calculation semantics', () {
      final now = DateTime.now();
      final trade = TradeOfferEntity(
        id: 'trd-1',
        senderId: 'user-1',
        receiverId: 'user-2',
        offeredProductId: 'prod-1',
        targetProductId: 'prod-2',
        cashAdjustment: 250000,
        status: 'PENDING',
        createdAt: now,
        updatedAt: now,
      );

      expect(trade.cashAdjustment, 250000);
      expect(trade.status, 'PENDING');
    });

    test('TransactionEntity 3-digit verification code calculation semantics', () {
      final now = DateTime.now();
      final tx = TransactionEntity(
        id: 'tx-1',
        reference: 'ORD-20261014-419',
        idempotencyKey: 'IDEM-TRX-1234',
        type: 'PURCHASE',
        payerId: 'user-1',
        payeeId: 'user-2',
        baseAmount: 3500000,
        uniqueCode: 419,
        totalAmount: 3500419,
        status: 'PENDING_PAYMENT',
        paymentChannel: 'QRIS',
        transactionDate: now,
        expiresAt: now.add(const Duration(minutes: 15)),
      );

      expect(tx.uniqueCode, 419);
      expect(tx.totalAmount, tx.baseAmount + tx.uniqueCode);
      expect(tx.status, 'PENDING_PAYMENT');
    });
  });
}
