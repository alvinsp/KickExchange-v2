import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/trade_offer_entity.dart';
import '../../domain/repositories/trade_repository.dart';
import '../datasources/trade_local_data_source.dart';
import '../datasources/trade_remote_data_source.dart';
import '../models/trade_offer_model.dart';
import '../../../auth/data/datasources/auth_local_data_source.dart';
import '../../../products/data/datasources/product_local_data_source.dart';
import '../../../sync/data/datasources/sync_local_data_source.dart';

class TradeRepositoryImpl implements TradeRepository {
  final TradeRemoteDataSource remoteDataSource;
  final TradeLocalDataSource localDataSource;
  final SyncLocalDataSource syncLocalDataSource;
  final AuthLocalDataSource authLocalDataSource;
  final ProductLocalDataSource productLocalDataSource;
  final NetworkInfo networkInfo;
  final Uuid uuid;

  TradeRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.syncLocalDataSource,
    required this.authLocalDataSource,
    required this.productLocalDataSource,
    required this.networkInfo,
    this.uuid = const Uuid(),
  });

  @override
  Future<Either<Failure, List<TradeOfferEntity>>> getTrades({String type = 'all'}) async {
    final isConnected = await networkInfo.isConnected;
    final currentUser = await authLocalDataSource.getCachedUser();

    if (isConnected) {
      try {
        final remoteItems = await remoteDataSource.fetchTrades(type: type);
        await localDataSource.cacheTrades(remoteItems);
        return Right(remoteItems);
      } catch (_) {}
    }

    try {
      final localItems = await localDataSource.getLocalTrades(
        userId: currentUser?.id,
        type: type,
      );
      return Right(localItems);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, TradeOfferEntity>> getTradeById(String tradeId) async {
    final local = await localDataSource.getTradeById(tradeId);
    if (local != null) return Right(local);

    try {
      final remote = await remoteDataSource.fetchTradeDetail(tradeId);
      await localDataSource.saveTrade(remote);
      return Right(remote);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return const Left(CacheFailure('Trade tidak ditemukan.'));
    }
  }

  @override
  Future<Either<Failure, TradeOfferEntity>> createTradeOffer({
    required String offeredProductId,
    required String targetProductId,
    required double cashAdjustment,
    required String notes,
  }) async {
    final currentUser = await authLocalDataSource.getCachedUser();
    if (currentUser == null) {
      return const Left(AuthFailure('Silakan login terlebih dahulu untuk mengajukan barter.'));
    }

    final targetProd = await productLocalDataSource.getProductById(targetProductId);
    final receiverId = targetProd?.ownerId ?? '';

    final tradeId = uuid.v4();
    final now = DateTime.now().toUtc();
    final idempotencyKey = 'IDEM-TRADE-$tradeId';

    final tradeModel = TradeOfferModel(
      id: tradeId,
      senderId: currentUser.id,
      receiverId: receiverId,
      offeredProductId: offeredProductId,
      targetProductId: targetProductId,
      cashAdjustment: cashAdjustment,
      notes: notes,
      status: 'PENDING',
      clientCreatedAt: now,
      createdAt: now,
      updatedAt: now,
      isSynced: false,
    );

    await localDataSource.saveTrade(tradeModel);

    final isConnected = await networkInfo.isConnected;
    final payload = {
      'id': tradeId,
      'offered_product_id': offeredProductId,
      'target_product_id': targetProductId,
      'cash_adjustment': cashAdjustment.toInt(),
      'notes': notes,
      'client_created_at': now.toIso8601String(),
    };

    if (!isConnected) {
      await syncLocalDataSource.enqueue(
        idempotencyKey: idempotencyKey,
        type: 'TRADE_CREATE',
        payloadJson: jsonEncode(payload),
      );
      return Right(tradeModel);
    }

    try {
      final remoteResult = await remoteDataSource.createTrade(
        trade: tradeModel,
        idempotencyKey: idempotencyKey,
      );
      final synced = remoteResult.copyWith(isSynced: true);
      await localDataSource.saveTrade(synced);
      return Right(synced);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } catch (_) {
      await syncLocalDataSource.enqueue(
        idempotencyKey: idempotencyKey,
        type: 'TRADE_CREATE',
        payloadJson: jsonEncode(payload),
      );
      return Right(tradeModel);
    }
  }

  @override
  Future<Either<Failure, TradeOfferEntity>> applyTradeAction({
    required String tradeId,
    required String action,
  }) async {
    final now = DateTime.now().toUtc();
    final idempotencyKey = 'IDEM-TRADE-ACTION-$tradeId-$action-${now.millisecondsSinceEpoch}';
    final payload = {'id': tradeId, 'action': action};

    final isConnected = await networkInfo.isConnected;
    if (!isConnected) {
      await syncLocalDataSource.enqueue(
        idempotencyKey: idempotencyKey,
        type: 'TRADE_ACTION',
        payloadJson: jsonEncode(payload),
      );
      final existing = await localDataSource.getTradeById(tradeId);
      if (existing != null) {
        final updatedStatus = action == 'accept'
            ? 'ACCEPTED'
            : (action == 'reject' ? 'REJECTED' : 'CANCELLED');
        final updated = existing.copyWith(status: updatedStatus, isSynced: false);
        await localDataSource.saveTrade(updated);
        return Right(updated);
      }
      return const Left(NetworkFailure('Aksi disimpan di antrean offline.'));
    }

    try {
      final result = await remoteDataSource.applyAction(
        tradeId: tradeId,
        action: action,
        idempotencyKey: idempotencyKey,
      );
      await localDataSource.saveTrade(result);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } catch (_) {
      await syncLocalDataSource.enqueue(
        idempotencyKey: idempotencyKey,
        type: 'TRADE_ACTION',
        payloadJson: jsonEncode(payload),
      );
      return const Left(NetworkFailure('Jaringan gagal, aksi disimpan untuk sinkronisasi otomatis.'));
    }
  }
}
