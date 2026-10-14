import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/product_entity.dart';
import '../repositories/product_repository.dart';

class UpdateProductParams {
  final ProductEntity product;
  final DateTime baseUpdatedAt;

  UpdateProductParams({
    required this.product,
    required this.baseUpdatedAt,
  });
}

class UpdateProductUseCase implements UseCase<ProductEntity, UpdateProductParams> {
  final ProductRepository repository;
  UpdateProductUseCase(this.repository);

  @override
  Future<Either<Failure, ProductEntity>> call(UpdateProductParams params) async {
    return await repository.updateProduct(
      product: params.product,
      baseUpdatedAt: params.baseUpdatedAt,
    );
  }
}
