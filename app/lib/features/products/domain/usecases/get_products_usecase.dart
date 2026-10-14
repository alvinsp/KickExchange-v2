import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/product_entity.dart';
import '../repositories/product_repository.dart';

class GetProductsParams {
  final String? query;
  final String? brand;
  final String? mode;
  final bool onlyMine;

  GetProductsParams({
    this.query,
    this.brand,
    this.mode,
    this.onlyMine = false,
  });
}

class GetProductsUseCase implements UseCase<List<ProductEntity>, GetProductsParams> {
  final ProductRepository repository;
  GetProductsUseCase(this.repository);

  @override
  Future<Either<Failure, List<ProductEntity>>> call(GetProductsParams params) async {
    return await repository.getProducts(
      query: params.query,
      brand: params.brand,
      mode: params.mode,
      onlyMine: params.onlyMine,
    );
  }
}
