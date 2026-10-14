import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/product_entity.dart';

abstract class ProductRepository {
  Future<Either<Failure, List<ProductEntity>>> getProducts({
    String? query,
    String? brand,
    String? mode, // sale, trade
    bool onlyMine = false,
  });

  Future<Either<Failure, ProductEntity>> getProductById(String id);

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
  });

  Future<Either<Failure, ProductEntity>> updateProduct({
    required ProductEntity product,
    required DateTime baseUpdatedAt,
  });

  Future<Either<Failure, void>> deleteProduct(String id);
}
