import 'package:sqflite/sqflite.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/product_model.dart';

abstract class ProductLocalDataSource {
  Future<void> cacheProducts(List<ProductModel> products);
  Future<void> saveProduct(ProductModel product);
  Future<List<ProductModel>> getCachedProducts({String? query, String? brand, String? mode, String? ownerId});
  Future<ProductModel?> getProductById(String id);
  Future<void> deleteProduct(String id);
}

class ProductLocalDataSourceImpl implements ProductLocalDataSource {
  final AppDatabase appDatabase;

  ProductLocalDataSourceImpl({required this.appDatabase});

  @override
  Future<void> cacheProducts(List<ProductModel> products) async {
    try {
      final db = await appDatabase.database;
      final batch = db.batch();
      for (final p in products) {
        batch.insert(
          'products',
          p.toSqliteRow(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    } catch (e) {
      throw CacheException(message: 'Gagal menyimpan produk ke database lokal: ${e.toString()}');
    }
  }

  @override
  Future<void> saveProduct(ProductModel product) async {
    try {
      final db = await appDatabase.database;
      await db.insert(
        'products',
        product.toSqliteRow(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw CacheException(message: 'Gagal menyimpan produk ke SQLite: ${e.toString()}');
    }
  }

  @override
  Future<List<ProductModel>> getCachedProducts({
    String? query,
    String? brand,
    String? mode,
    String? ownerId,
  }) async {
    try {
      final db = await appDatabase.database;
      final whereClauses = <String>[];
      final whereArgs = <dynamic>[];

      if (ownerId != null) {
        whereClauses.add('owner_id = ?');
        whereArgs.add(ownerId);
      } else {
        whereClauses.add("status = 'AVAILABLE'");
      }

      if (brand != null && brand.isNotEmpty) {
        whereClauses.add('LOWER(brand) = LOWER(?)');
        whereArgs.add(brand);
      }

      if (mode == 'sale') {
        whereClauses.add('is_for_sale = 1');
      } else if (mode == 'trade') {
        whereClauses.add('is_for_trade = 1');
      }

      if (query != null && query.isNotEmpty) {
        whereClauses.add('(LOWER(name) LIKE ? OR LOWER(brand) LIKE ?)');
        final term = '%${query.toLowerCase()}%';
        whereArgs.addAll([term, term]);
      }

      final whereString = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;
      final maps = await db.query(
        'products',
        where: whereString,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
        orderBy: 'created_at DESC',
      );

      return maps.map((e) => ProductModel.fromJson(e)).toList();
    } catch (e) {
      throw CacheException(message: 'Gagal membaca produk dari SQLite lokal: ${e.toString()}');
    }
  }

  @override
  Future<ProductModel?> getProductById(String id) async {
    try {
      final db = await appDatabase.database;
      final maps = await db.query(
        'products',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (maps.isEmpty) return null;
      return ProductModel.fromJson(maps.first);
    } catch (e) {
      throw CacheException(message: 'Gagal mengambil detail produk dari lokal: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteProduct(String id) async {
    try {
      final db = await appDatabase.database;
      await db.delete(
        'products',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw CacheException(message: 'Gagal menghapus produk dari SQLite: ${e.toString()}');
    }
  }
}
