import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/product_model.dart';

abstract class ProductRemoteDataSource {
  Future<List<ProductModel>> fetchProducts({
    String? query,
    String? brand,
    String? mode,
    bool onlyMine = false,
  });

  Future<ProductModel> fetchProductDetail(String id);

  Future<ProductModel> createProduct({
    required ProductModel product,
    required String idempotencyKey,
  });

  Future<ProductModel> updateProduct({
    required String id,
    required Map<String, dynamic> data,
    required String idempotencyKey,
  });

  Future<void> deleteProduct(String id);
}

class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  final DioClient dioClient;

  ProductRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<List<ProductModel>> fetchProducts({
    String? query,
    String? brand,
    String? mode,
    bool onlyMine = false,
  }) async {
    final queryParams = <String, dynamic>{};
    if (query != null && query.isNotEmpty) queryParams['q'] = query;
    if (brand != null && brand.isNotEmpty) queryParams['brand'] = brand;
    if (mode != null && mode.isNotEmpty) queryParams['mode'] = mode;
    if (onlyMine) queryParams['owner'] = 'me';

    final response = await dioClient.dio.get(
      ApiEndpoints.products,
      queryParameters: queryParams,
    );

    final data = response.data as Map<String, dynamic>;
    final items = (data['items'] as List).cast<Map<String, dynamic>>();
    return items.map((e) => ProductModel.fromJson(e)).toList();
  }

  @override
  Future<ProductModel> fetchProductDetail(String id) async {
    final response = await dioClient.dio.get('${ApiEndpoints.products}/$id');
    final data = response.data as Map<String, dynamic>;
    return ProductModel.fromJson(data['product'] as Map<String, dynamic>);
  }

  @override
  Future<ProductModel> createProduct({
    required ProductModel product,
    required String idempotencyKey,
  }) async {
    final response = await dioClient.dio.post(
      ApiEndpoints.products,
      data: product.toJson(),
      options: Options(
        headers: {'X-Idempotency-Key': idempotencyKey},
      ),
    );
    return ProductModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<ProductModel> updateProduct({
    required String id,
    required Map<String, dynamic> data,
    required String idempotencyKey,
  }) async {
    final response = await dioClient.dio.put(
      '${ApiEndpoints.products}/$id',
      data: data,
      options: Options(
        headers: {'X-Idempotency-Key': idempotencyKey},
      ),
    );
    return ProductModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteProduct(String id) async {
    await dioClient.dio.delete('${ApiEndpoints.products}/$id');
  }
}
