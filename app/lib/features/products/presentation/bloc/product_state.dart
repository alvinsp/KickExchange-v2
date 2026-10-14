import 'package:equatable/equatable.dart';
import '../../domain/entities/product_entity.dart';

abstract class ProductState extends Equatable {
  const ProductState();

  @override
  List<Object?> get props => [];
}

class ProductInitial extends ProductState {}

class ProductLoading extends ProductState {
  final String message;
  const ProductLoading({this.message = 'Memuat katalog sneaker...'});

  @override
  List<Object?> get props => [message];
}

class ProductLoaded extends ProductState {
  final List<ProductEntity> products;
  const ProductLoaded(this.products);

  @override
  List<Object?> get props => [products];
}

class ProductEmpty extends ProductState {
  final String message;
  const ProductEmpty({this.message = 'Belum ada produk sneaker.'});

  @override
  List<Object?> get props => [message];
}

class ProductActionSuccess extends ProductState {
  final String message;
  final ProductEntity? product;

  const ProductActionSuccess(this.message, {this.product});

  @override
  List<Object?> get props => [message, product];
}

class ProductFailureState extends ProductState {
  final String errorMessage;
  final String? errorCode;

  const ProductFailureState(this.errorMessage, {this.errorCode});

  @override
  List<Object?> get props => [errorMessage, errorCode];
}
