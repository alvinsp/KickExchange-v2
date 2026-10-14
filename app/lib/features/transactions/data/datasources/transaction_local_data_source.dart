import 'package:sqflite/sqflite.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/transaction_model.dart';

abstract class TransactionLocalDataSource {
  Future<void> cacheTransactions(List<TransactionModel> transactions);
  Future<void> saveTransaction(TransactionModel transaction);
  Future<List<TransactionModel>> getLocalTransactions();
  Future<TransactionModel?> getTransactionById(String id);
}

class TransactionLocalDataSourceImpl implements TransactionLocalDataSource {
  final AppDatabase appDatabase;

  TransactionLocalDataSourceImpl({required this.appDatabase});

  @override
  Future<void> cacheTransactions(List<TransactionModel> transactions) async {
    try {
      final db = await appDatabase.database;
      final batch = db.batch();
      for (final tx in transactions) {
        batch.insert(
          'transactions',
          tx.toSqliteRow(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    } catch (e) {
      throw CacheException(message: 'Gagal menyimpan transaksi ke SQLite: ${e.toString()}');
    }
  }

  @override
  Future<void> saveTransaction(TransactionModel transaction) async {
    try {
      final db = await appDatabase.database;
      await db.insert(
        'transactions',
        transaction.toSqliteRow(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw CacheException(message: 'Gagal menyimpan transaksi: ${e.toString()}');
    }
  }

  @override
  Future<List<TransactionModel>> getLocalTransactions() async {
    try {
      final db = await appDatabase.database;
      final maps = await db.query('transactions', orderBy: 'transaction_date DESC');
      return maps.map((e) => TransactionModel.fromJson(e)).toList();
    } catch (e) {
      throw CacheException(message: 'Gagal memuat transaksi dari lokal: ${e.toString()}');
    }
  }

  @override
  Future<TransactionModel?> getTransactionById(String id) async {
    try {
      final db = await appDatabase.database;
      final maps = await db.query(
        'transactions',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (maps.isEmpty) return null;
      return TransactionModel.fromJson(maps.first);
    } catch (e) {
      throw CacheException(message: 'Gagal mengambil transaksi dari lokal: ${e.toString()}');
    }
  }
}
