import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/errors/exceptions.dart';

class SyncQueueItem {
  final String queueId;
  final String idempotencyKey;
  final String type;
  final String payloadJson;
  final DateTime createdAt;
  final int retryCount;
  final String? lastError;
  final String status;

  SyncQueueItem({
    required this.queueId,
    required this.idempotencyKey,
    required this.type,
    required this.payloadJson,
    required this.createdAt,
    this.retryCount = 0,
    this.lastError,
    this.status = 'PENDING',
  });

  factory SyncQueueItem.fromRow(Map<String, dynamic> row) {
    return SyncQueueItem(
      queueId: row['queue_id'] as String,
      idempotencyKey: row['idempotency_key'] as String,
      type: row['type'] as String,
      payloadJson: row['payload_json'] as String,
      createdAt: DateTime.parse(row['created_at'].toString()),
      retryCount: row['retry_count'] as int? ?? 0,
      lastError: row['last_error'] as String?,
      status: row['status'] as String? ?? 'PENDING',
    );
  }
}

abstract class SyncLocalDataSource {
  Future<void> enqueue({
    required String idempotencyKey,
    required String type,
    required String payloadJson,
  });

  Future<List<SyncQueueItem>> getPendingQueue();
  Future<void> removeQueueItem(String idempotencyKey);
  Future<void> markFailed(String idempotencyKey, String errorMessage);
  Future<int> getPendingCount();
}

class SyncLocalDataSourceImpl implements SyncLocalDataSource {
  final AppDatabase appDatabase;
  final Uuid uuid;

  SyncLocalDataSourceImpl({
    required this.appDatabase,
    this.uuid = const Uuid(),
  });

  @override
  Future<void> enqueue({
    required String idempotencyKey,
    required String type,
    required String payloadJson,
  }) async {
    try {
      final db = await appDatabase.database;
      final now = DateTime.now().toUtc().toIso8601String();
      await db.insert(
        'sync_queue',
        {
          'queue_id': uuid.v4(),
          'idempotency_key': idempotencyKey,
          'type': type,
          'payload_json': payloadJson,
          'created_at': now,
          'retry_count': 0,
          'status': 'PENDING',
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw CacheException(message: 'Gagal menambahkan antrean sinkronisasi: ${e.toString()}');
    }
  }

  @override
  Future<List<SyncQueueItem>> getPendingQueue() async {
    try {
      final db = await appDatabase.database;
      final maps = await db.query(
        'sync_queue',
        where: "status = 'PENDING'",
        orderBy: 'created_at ASC',
      );
      return maps.map((e) => SyncQueueItem.fromRow(e)).toList();
    } catch (e) {
      throw CacheException(message: 'Gagal memuat antrean sinkronisasi: ${e.toString()}');
    }
  }

  @override
  Future<void> removeQueueItem(String idempotencyKey) async {
    try {
      final db = await appDatabase.database;
      await db.delete(
        'sync_queue',
        where: 'idempotency_key = ?',
        whereArgs: [idempotencyKey],
      );
    } catch (e) {
      throw CacheException(message: 'Gagal menghapus antrean sinkronisasi: ${e.toString()}');
    }
  }

  @override
  Future<void> markFailed(String idempotencyKey, String errorMessage) async {
    try {
      final db = await appDatabase.database;
      await db.rawUpdate(
        '''
        UPDATE sync_queue 
        SET retry_count = retry_count + 1, last_error = ?, status = CASE WHEN retry_count >= 5 THEN 'FAILED' ELSE 'PENDING' END
        WHERE idempotency_key = ?
        ''',
        [errorMessage, idempotencyKey],
      );
    } catch (e) {
      throw CacheException(message: 'Gagal memperbarui status antrean: ${e.toString()}');
    }
  }

  @override
  Future<int> getPendingCount() async {
    try {
      final db = await appDatabase.database;
      final result = await db.rawQuery("SELECT COUNT(*) as count FROM sync_queue WHERE status = 'PENDING'");
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (_) {
      return 0;
    }
  }
}
