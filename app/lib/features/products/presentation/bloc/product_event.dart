import 'package:equatable/equatable.dart';
import '../../domain/entities/product_entity.dart';

abstract class ProductEvent extends Equatable {
  const ProductEvent();

  @override
  List<Object?> get props => [];
}

class LoadProductsEvent extends ProductEvent {
  final String? query;
  final String? brand;
  final String? mode;
  final bool onlyMine;

  const LoadProductsEvent({
    this.query,
    this.brand,
    this.mode,
    this.onlyMine = false,
  });

  @override
  List<Object?> get props => [query, brand, mode, onlyMine];
}

class CreateProductSubmittedEvent extends ProductEvent {
  final String name;
  final String brand;
  final double sizeUs;
  final double price;
  final String condition;
  final String description;
  final List<String> imageUrls;
  final bool isForSale;
  final bool isForTrade;

  const CreateProductSubmittedEvent({
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

  @override
  List<Object?> get props => [
        name,
        brand,
        sizeUs,
        price,
        condition,
        description,
        imageUrls,
        isForSale,
        isForTrade,
      ];
}

class UpdateProductSubmittedEvent extends ProductEvent {
  final ProductEntity product;
  final DateTime baseUpdatedAt;

  const UpdateProductSubmittedEvent({
    required this.product,
    required this.baseUpdatedAt,
  });

  @override
  List<Object?> get props => [product, baseUpdatedAt];
}

class DeleteProductEvent extends ProductEvent {
  final String id;
  const DeleteProductEvent(this.id);

  @override
  List<Object?> get props => [id];
}
