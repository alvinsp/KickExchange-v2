import 'package:sqflite/sqflite.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/trade_offer_model.dart';

abstract class TradeLocalDataSource {
  Future<void> cacheTrades(List<TradeOfferModel> trades);
  Future<void> saveTrade(TradeOfferModel trade);
  Future<List<TradeOfferModel>> getLocalTrades({String? userId, String type = 'all'});
  Future<TradeOfferModel?> getTradeById(String id);
}

class TradeLocalDataSourceImpl implements TradeLocalDataSource {
  final AppDatabase appDatabase;

  TradeLocalDataSourceImpl({required this.appDatabase});

  @override
  Future<void> cacheTrades(List<TradeOfferModel> trades) async {
    try {
      final db = await appDatabase.database;
      final batch = db.batch();
      for (final t in trades) {
        batch.insert(
          'trades',
          t.toSqliteRow(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    } catch (e) {
      throw CacheException(message: 'Gagal menyimpan trade ke SQLite: ${e.toString()}');
    }
  }

  @override
  Future<void> saveTrade(TradeOfferModel trade) async {
    try {
      final db = await appDatabase.database;
      await db.insert(
        'trades',
        trade.toSqliteRow(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw CacheException(message: 'Gagal menyimpan trade ke lokal: ${e.toString()}');
    }
  }

  @override
  Future<List<TradeOfferModel>> getLocalTrades({String? userId, String type = 'all'}) async {
    try {
      final db = await appDatabase.database;
      String? whereClause;
      List<dynamic>? whereArgs;

      if (userId != null) {
        if (type == 'incoming') {
          whereClause = 'receiver_id = ?';
          whereArgs = [userId];
        } else if (type == 'outgoing') {
          whereClause = 'sender_id = ?';
          whereArgs = [userId];
        } else {
          whereClause = '(sender_id = ? OR receiver_id = ?)';
          whereArgs = [userId, userId];
        }
      }

      final maps = await db.query(
        'trades',
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'created_at DESC',
      );

      return maps.map((e) => TradeOfferModel.fromJson(e)).toList();
    } catch (e) {
      throw CacheException(message: 'Gagal memuat trade dari lokal: ${e.toString()}');
    }
  }

  @override
  Future<TradeOfferModel?> getTradeById(String id) async {
    try {
      final db = await appDatabase.database;
      final maps = await db.query(
        'trades',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (maps.isEmpty) return null;
      return TradeOfferModel.fromJson(maps.first);
    } catch (e) {
      throw CacheException(message: 'Gagal mengambil trade dari lokal: ${e.toString()}');
    }
  }
}
