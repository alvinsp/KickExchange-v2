import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../datasources/transaction_local_data_source.dart';
import '../datasources/transaction_remote_data_source.dart';
import '../models/transaction_model.dart';
import '../../../auth/data/datasources/auth_local_data_source.dart';
import '../../../products/data/datasources/product_local_data_source.dart';
import '../../../sync/data/datasources/sync_local_data_source.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionRemoteDataSource remoteDataSource;
  final TransactionLocalDataSource localDataSource;
  final SyncLocalDataSource syncLocalDataSource;
  final AuthLocalDataSource authLocalDataSource;
  final ProductLocalDataSource productLocalDataSource;
  final NetworkInfo networkInfo;
  final Uuid uuid;

  TransactionRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.syncLocalDataSource,
    required this.authLocalDataSource,
    required this.productLocalDataSource,
    required this.networkInfo,
    this.uuid = const Uuid(),
  });

  @override
  Future<Either<Failure, List<TransactionEntity>>> getTransactions() async {
    final isConnected = await networkInfo.isConnected;
    if (isConnected) {
      try {
        final remote = await remoteDataSource.fetchTransactions();
        await localDataSource.cacheTransactions(remote);
        return Right(remote);
      } catch (_) {}
    }

    try {
      final local = await localDataSource.getLocalTransactions();
      return Right(local);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, TransactionEntity>> getTransactionById(String id) async {
    final local = await localDataSource.getTransactionById(id);
    if (local != null) return Right(local);

    try {
      final remote = await remoteDataSource.fetchTransactionDetail(id);
      await localDataSource.saveTransaction(remote);
      return Right(remote);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return const Left(CacheFailure('Transaksi tidak ditemukan di penyimpanan lokal.'));
    }
  }

  @override
  Future<Either<Failure, TransactionEntity>> createTransaction({
    String? productId,
    String? tradeId,
    required String paymentChannel,
  }) async {
    final currentUser = await authLocalDataSource.getCachedUser();
    if (currentUser == null) {
      return const Left(AuthFailure('Silakan login terlebih dahulu untuk melakukan transaksi.'));
    }

    final txId = uuid.v4();
    final now = DateTime.now().toUtc();
    final idempotencyKey = 'IDEM-TX-$txId';

    final isConnected = await networkInfo.isConnected;
    if (!isConnected) {
      // Offline transaction creation: queue into sync_queue
      final payload = {
        'id': txId,
        if (productId != null) 'product_id': productId,
        if (tradeId != null) 'trade_id': tradeId,
        'payment_channel': paymentChannel,
        'client_created_at': now.toIso8601String(),
      };

      await syncLocalDataSource.enqueue(
        idempotencyKey: idempotencyKey,
        type: 'TRANSACTION_CREATE',
        payloadJson: jsonEncode(payload),
      );

      // Create local placeholder transaction
      final localPlaceholder = TransactionModel(
        id: txId,
        reference: 'OFFLINE-TX-${now.millisecondsSinceEpoch}',
        idempotencyKey: idempotencyKey,
        type: productId != null ? 'PURCHASE' : 'TRADE_CASH_DIFF',
        payerId: currentUser.id,
        payeeId: '',
        productId: productId,
        tradeId: tradeId,
        baseAmount: 0,
        uniqueCode: 0,
        totalAmount: 0,
        status: 'PENDING_PAYMENT',
        paymentChannel: paymentChannel,
        transactionDate: now,
        expiresAt: now.add(const Duration(minutes: 15)),
        isSynced: false,
      );

      await localDataSource.saveTransaction(localPlaceholder);
      return Right(localPlaceholder);
    }

    try {
      final remoteTx = await remoteDataSource.createTransaction(
        productId: productId,
        tradeId: tradeId,
        paymentChannel: paymentChannel,
        idempotencyKey: idempotencyKey,
      );

      await localDataSource.saveTransaction(remoteTx);
      return Right(remoteTx);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure('Gagal membuat transaksi: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, TransactionEntity>> simulatePayment(String reference) async {
    try {
      final updated = await remoteDataSource.simulatePay(reference);
      await localDataSource.saveTransaction(updated);
      return Right(updated);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure('Gagal melakukan simulasi pembayaran: ${e.toString()}'));
    }
  }
}
