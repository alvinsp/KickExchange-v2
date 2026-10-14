import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/product_entity.dart';
import '../repositories/product_repository.dart';

class CreateProductParams {
  final String name;
  final String brand;
  final double sizeUs;
  final double price;
  final String condition;
  final String description;
  final List<String> imageUrls;
  final bool isForSale;
  final bool isForTrade;

  CreateProductParams({
    required this.name,
    required this.brand,
    required this.sizeUs,
    required this.price,
    required this.condition,
    required this.description,
    required this.imageUrls,
    required this.isForSale,
    required this.isForTrade,
  });
}

class CreateProductUseCase implements UseCase<ProductEntity, CreateProductParams> {
  final ProductRepository repository;
  CreateProductUseCase(this.repository);

  @override
  Future<Either<Failure, ProductEntity>> call(CreateProductParams params) async {
    if (params.name.trim().length < 3) {
      return const Left(ValidationFailure('Nama produk minimal 3 karakter.'));
    }
    if (params.price <= 0) {
      return const Left(ValidationFailure('Harga produk harus lebih besar dari 0.'));
    }
    if (!params.isForSale && !params.isForTrade) {
      return const Left(ValidationFailure('Aktifkan opsi jual atau opsi tukar (barter).'));
    }

    return await repository.createProduct(
      name: params.name.trim(),
      brand: params.brand.trim(),
      sizeUs: params.sizeUs,
      price: params.price,
      condition: params.condition,
      description: params.description.trim(),
      imageUrls: params.imageUrls,
      isForSale: params.isForSale,
      isForTrade: params.isForTrade,
    );
  }
}
