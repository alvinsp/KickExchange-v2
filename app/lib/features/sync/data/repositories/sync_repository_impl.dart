import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/repositories/sync_repository.dart';
import '../datasources/sync_local_data_source.dart';
import '../datasources/sync_remote_data_source.dart';

class SyncRepositoryImpl implements SyncRepository {
  final SyncRemoteDataSource remoteDataSource;
  final SyncLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  SyncRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, int>> synchronizePendingQueue() async {
    final isConnected = await networkInfo.isConnected;
    if (!isConnected) {
      return const Left(NetworkFailure('Tidak ada koneksi internet untuk melakukan sinkronisasi.'));
    }

    final pending = await localDataSource.getPendingQueue();
    if (pending.isEmpty) {
      return const Right(0);
    }

    try {
      final response = await remoteDataSource.sendBatch(pending);
      final results = (response['results'] as List?)?.cast<Map<String, dynamic>>() ?? [];

      int successCount = 0;
      for (final res in results) {
        final key = res['idempotency_key'] as String?;
        final status = res['status'] as int? ?? 500;

        if (key != null) {
          if (status >= 200 && status < 300) {
            await localDataSource.removeQueueItem(key);
            successCount += 1;
          } else {
            final error = res['error'];
            final msg = error is Map ? error['message']?.toString() : 'Error sinkronisasi';
            await localDataSource.markFailed(key, msg ?? 'Failed');
          }
        }
      }

      return Right(successCount);
    } catch (e) {
      return Left(ServerFailure('Gagal menyinkronkan data: ${e.toString()}'));
    }
  }

  @override
  Future<int> getPendingQueueCount() async {
    return await localDataSource.getPendingCount();
  }
}
