import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_local_data_source.dart';
import '../datasources/product_remote_data_source.dart';
import '../models/product_model.dart';
import '../../../auth/data/datasources/auth_local_data_source.dart';
import '../../../sync/data/datasources/sync_local_data_source.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource remoteDataSource;
  final ProductLocalDataSource localDataSource;
  final SyncLocalDataSource syncLocalDataSource;
  final AuthLocalDataSource authLocalDataSource;
  final NetworkInfo networkInfo;
  final Uuid uuid;

  ProductRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.syncLocalDataSource,
    required this.authLocalDataSource,
    required this.networkInfo,
    this.uuid = const Uuid(),
  });

  @override
  Future<Either<Failure, List<ProductEntity>>> getProducts({
    String? query,
    String? brand,
    String? mode,
    bool onlyMine = false,
  }) async {
    final isConnected = await networkInfo.isConnected;

    if (isConnected) {
      try {
        final remoteItems = await remoteDataSource.fetchProducts(
          query: query,
          brand: brand,
          mode: mode,
          onlyMine: onlyMine,
        );
        // Cache to local SQLite
        await localDataSource.cacheProducts(remoteItems);
        return Right(remoteItems);
      } catch (_) {
        // Fallback to cache on error
      }
    }

    try {
      String? ownerId;
      if (onlyMine) {
        final user = await authLocalDataSource.getCachedUser();
        ownerId = user?.id;
      }
      final localItems = await localDataSource.getCachedProducts(
        query: query,
        brand: brand,
        mode: mode,
        ownerId: ownerId,
      );
      return Right(localItems);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, ProductEntity>> getProductById(String id) async {
    final localItem = await localDataSource.getProductById(id);
    if (localItem != null) {
      return Right(localItem);
    }

    try {
      final remoteItem = await remoteDataSource.fetchProductDetail(id);
      await localDataSource.saveProduct(remoteItem);
      return Right(remoteItem);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return const Left(CacheFailure('Produk tidak ditemukan di database lokal.'));
    }
  }

  @override
  Future<Either<Failure, ProductEntity>> createProduct({
    required String name,
    required String brand,
    required double sizeUs,
    required double price,
    required String condition,
    required String description,
    required List<String> imageUrls,
    required bool isForSale,
    required bool isForTrade,
  }) async {
    final currentUser = await authLocalDataSource.getCachedUser();
    if (currentUser == null) {
      return const Left(AuthFailure('Silakan login terlebih dahulu untuk menjual sepatu.'));
    }

    final now = DateTime.now().toUtc();
    final productId = uuid.v4();
    final idempotencyKey = 'IDEM-PROD-$productId';

    final productModel = ProductModel(
      id: productId,
      ownerId: currentUser.id,
      name: name,
      brand: brand,
      sizeUs: sizeUs,
      price: price,
      condition: condition,
      description: description,
      imageUrls: imageUrls,
      isForSale: isForSale,
      isForTrade: isForTrade,
      isSold: false,
      status: 'AVAILABLE',
      createdAt: now,
      updatedAt: now,
      isSynced: false,
      ownerName: currentUser.name,
      ownerEmail: currentUser.email,
      ownerPhone: currentUser.phone,
    );

    // Save immediately to local SQLite
    await localDataSource.saveProduct(productModel);

    final isConnected = await networkInfo.isConnected;
    if (!isConnected) {
      // Offline mode: enqueue into sync_queue
      await syncLocalDataSource.enqueue(
        idempotencyKey: idempotencyKey,
        type: 'PRODUCT_CREATE',
        payloadJson: jsonEncode(productModel.toJson()),
      );
      return Right(productModel);
    }

    try {
      final remoteCreated = await remoteDataSource.createProduct(
        product: productModel,
        idempotencyKey: idempotencyKey,
      );
      final synced = remoteCreated.copyWith(isSynced: true) as ProductModel;
      await localDataSource.saveProduct(synced);
      return Right(synced);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } catch (e) {
      // If network fails midway, enqueue offline
      await syncLocalDataSource.enqueue(
        idempotencyKey: idempotencyKey,
        type: 'PRODUCT_CREATE',
        payloadJson: jsonEncode(productModel.toJson()),
      );
      return Right(productModel);
    }
  }

  @override
  Future<Either<Failure, ProductEntity>> updateProduct({
    required ProductEntity product,
    required DateTime baseUpdatedAt,
  }) async {
    final now = DateTime.now().toUtc();
    final updatedModel = (product.copyWith(updatedAt: now, isSynced: false)) as ProductModel;
    await localDataSource.saveProduct(updatedModel);

    final idempotencyKey = 'IDEM-PROD-UPDATE-${product.id}-${now.millisecondsSinceEpoch}';
    final payload = {
      'id': product.id,
      'base_updated_at': baseUpdatedAt.toIso8601String(),
      'name': product.name,
      'brand': product.brand,
      'size_us': product.sizeUs,
      'price': product.price.toInt(),
      'condition': product.condition,
      'description': product.description,
      'image_urls': product.imageUrls,
      'is_for_sale': product.isForSale,
      'is_for_trade': product.isForTrade,
    };

    final isConnected = await networkInfo.isConnected;
    if (!isConnected) {
      await syncLocalDataSource.enqueue(
        idempotencyKey: idempotencyKey,
        type: 'PRODUCT_UPDATE',
        payloadJson: jsonEncode(payload),
      );
      return Right(updatedModel);
    }

    try {
      final remoteResult = await remoteDataSource.updateProduct(
        id: product.id,
        data: payload,
        idempotencyKey: idempotencyKey,
      );
      final synced = remoteResult.copyWith(isSynced: true) as ProductModel;
      await localDataSource.saveProduct(synced);
      return Right(synced);
    } on ServerException catch (e) {
      if (e.code == 'VERSION_CONFLICT') {
        return Left(ConflictFailure(e.message, code: e.code));
      }
      return Left(ServerFailure(e.message, code: e.code));
    } catch (_) {
      await syncLocalDataSource.enqueue(
        idempotencyKey: idempotencyKey,
        type: 'PRODUCT_UPDATE',
        payloadJson: jsonEncode(payload),
      );
      return Right(updatedModel);
    }
  }

  @override
  Future<Either<Failure, void>> deleteProduct(String id) async {
    await localDataSource.deleteProduct(id);
    final isConnected = await networkInfo.isConnected;
    final idempotencyKey = 'IDEM-PROD-DEL-$id';

    if (!isConnected) {
      await syncLocalDataSource.enqueue(
        idempotencyKey: idempotencyKey,
        type: 'PRODUCT_DELETE',
        payloadJson: jsonEncode({'id': id}),
      );
      return const Right(null);
    }

    try {
      await remoteDataSource.deleteProduct(id);
      return const Right(null);
    } catch (_) {
      await syncLocalDataSource.enqueue(
        idempotencyKey: idempotencyKey,
        type: 'PRODUCT_DELETE',
        payloadJson: jsonEncode({'id': id}),
      );
      return const Right(null);
    }
  }
}
