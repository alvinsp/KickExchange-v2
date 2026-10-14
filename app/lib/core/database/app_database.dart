import 'package:flutter/foundation.dart';
import 'dart:io' as io;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._internal();
  static Database? _database;
  static Future<Database>? _initFuture;

  AppDatabase._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _initFuture ??= _initDatabase();
    _database = await _initFuture;
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String dbPath;
    DatabaseFactory factory;

    if (kIsWeb) {
      factory = databaseFactoryFfiWeb;
      dbPath = 'kickexchange_local.db';
    } else if (io.Platform.isWindows || io.Platform.isLinux) {
      sqfliteFfiInit();
      factory = databaseFactoryFfi;
      final appDocDir = await getApplicationDocumentsDirectory();
      dbPath = join(appDocDir.path, 'KickExchange', 'kickexchange_local.db');
      final file = io.File(dbPath);
      if (!file.parent.existsSync()) {
        file.parent.createSync(recursive: true);
      }
    } else {
      factory = databaseFactory;
      final defaultDatabasesPath = await getDatabasesPath();
      dbPath = join(defaultDatabasesPath, 'kickexchange_local.db');
    }

    return await factory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE products (
            id TEXT PRIMARY KEY,
            owner_id TEXT NOT NULL,
            name TEXT NOT NULL,
            brand TEXT NOT NULL,
            size_us REAL NOT NULL,
            price REAL NOT NULL,
            condition TEXT NOT NULL,
            description TEXT,
            image_urls TEXT,
            is_for_sale INTEGER NOT NULL DEFAULT 1,
            is_for_trade INTEGER NOT NULL DEFAULT 1,
            is_sold INTEGER NOT NULL DEFAULT 0,
            status TEXT NOT NULL DEFAULT 'AVAILABLE',
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            is_synced INTEGER NOT NULL DEFAULT 1
          )
        ''');

        await db.execute('''
          CREATE TABLE trades (
            id TEXT PRIMARY KEY,
            sender_id TEXT NOT NULL,
            receiver_id TEXT NOT NULL,
            offered_product_id TEXT NOT NULL,
            target_product_id TEXT NOT NULL,
            cash_adjustment REAL NOT NULL DEFAULT 0.0,
            notes TEXT,
            status TEXT NOT NULL,
            client_created_at TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            is_synced INTEGER NOT NULL DEFAULT 1
          )
        ''');

        await db.execute('''
          CREATE TABLE transactions (
            id TEXT PRIMARY KEY,
            reference TEXT NOT NULL,
            idempotency_key TEXT UNIQUE NOT NULL,
            type TEXT NOT NULL,
            payer_id TEXT NOT NULL,
            payee_id TEXT NOT NULL,
            product_id TEXT,
            trade_id TEXT,
            base_amount REAL NOT NULL,
            unique_code INTEGER NOT NULL,
            total_amount REAL NOT NULL,
            status TEXT NOT NULL,
            payment_channel TEXT NOT NULL,
            payment_provider TEXT,
            qr_string TEXT,
            va_number TEXT,
            transaction_date TEXT NOT NULL,
            expires_at TEXT NOT NULL,
            paid_at TEXT,
            is_synced INTEGER NOT NULL DEFAULT 1
          )
        ''');

        await db.execute('''
          CREATE TABLE sync_queue (
            queue_id TEXT PRIMARY KEY,
            idempotency_key TEXT UNIQUE NOT NULL,
            type TEXT NOT NULL,
            payload_json TEXT NOT NULL,
            created_at TEXT NOT NULL,
            retry_count INTEGER NOT NULL DEFAULT 0,
            last_error TEXT,
            status TEXT NOT NULL
          )
        ''');
      },
    ),);
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
      _initFuture = null;
    }
  }
}
