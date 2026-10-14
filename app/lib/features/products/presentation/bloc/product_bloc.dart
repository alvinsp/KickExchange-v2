import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/usecases/create_product_usecase.dart';
import '../../domain/usecases/get_products_usecase.dart';
import '../../domain/usecases/update_product_usecase.dart';
import 'product_event.dart';
import 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final GetProductsUseCase getProductsUseCase;
  final CreateProductUseCase createProductUseCase;
  final UpdateProductUseCase updateProductUseCase;
  final ProductRepository productRepository;

  ProductBloc({
    required this.getProductsUseCase,
    required this.createProductUseCase,
    required this.updateProductUseCase,
    required this.productRepository,
  }) : super(ProductInitial()) {
    on<LoadProductsEvent>(_onLoadProducts);
    on<CreateProductSubmittedEvent>(_onCreateProduct);
    on<UpdateProductSubmittedEvent>(_onUpdateProduct);
    on<DeleteProductEvent>(_onDeleteProduct);
  }

  Future<void> _onLoadProducts(
    LoadProductsEvent event,
    Emitter<ProductState> emit,
  ) async {
    emit(const ProductLoading());
    final result = await getProductsUseCase(
      GetProductsParams(
        query: event.query,
        brand: event.brand,
        mode: event.mode,
        onlyMine: event.onlyMine,
      ),
    );

    result.fold(
      (failure) => emit(ProductFailureState(failure.message, errorCode: failure.code)),
      (products) {
        if (products.isEmpty) {
          emit(const ProductEmpty());
        } else {
          emit(ProductLoaded(products));
        }
      },
    );
  }

  Future<void> _onCreateProduct(
    CreateProductSubmittedEvent event,
    Emitter<ProductState> emit,
  ) async {
    emit(const ProductLoading(message: 'Menyimpan listing sepatu...'));
    final result = await createProductUseCase(
      CreateProductParams(
        name: event.name,
        brand: event.brand,
        sizeUs: event.sizeUs,
        price: event.price,
        condition: event.condition,
        description: event.description,
        imageUrls: event.imageUrls,
        isForSale: event.isForSale,
        isForTrade: event.isForTrade,
      ),
    );

    result.fold(
      (failure) => emit(ProductFailureState(failure.message, errorCode: failure.code)),
      (product) {
        final offlineNote = product.isSynced ? '' : ' (Disimpan offline, akan sinkron saat online)';
        emit(ProductActionSuccess('Produk berhasil ditambahkan!$offlineNote', product: product));
        add(const LoadProductsEvent());
      },
    );
  }

  Future<void> _onUpdateProduct(
    UpdateProductSubmittedEvent event,
    Emitter<ProductState> emit,
  ) async {
    emit(const ProductLoading(message: 'Memperbarui data produk...'));
    final result = await updateProductUseCase(
      UpdateProductParams(
        product: event.product,
        baseUpdatedAt: event.baseUpdatedAt,
      ),
    );

    result.fold(
      (failure) => emit(ProductFailureState(failure.message, errorCode: failure.code)),
      (product) {
        final offlineNote = product.isSynced ? '' : ' (Perubahan disimpan offline)';
        emit(ProductActionSuccess('Produk berhasil diperbarui!$offlineNote', product: product));
        add(const LoadProductsEvent());
      },
    );
  }

  Future<void> _onDeleteProduct(
    DeleteProductEvent event,
    Emitter<ProductState> emit,
  ) async {
    emit(const ProductLoading(message: 'Menghapus listing produk...'));
    final result = await productRepository.deleteProduct(event.id);
    result.fold(
      (failure) => emit(ProductFailureState(failure.message)),
      (_) {
        emit(const ProductActionSuccess('Produk berhasil dihapus.'));
        add(const LoadProductsEvent());
      },
    );
  }
}
