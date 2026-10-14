import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/transaction_model.dart';

abstract class TransactionRemoteDataSource {
  Future<List<TransactionModel>> fetchTransactions();
  Future<TransactionModel> fetchTransactionDetail(String id);
  Future<TransactionModel> createTransaction({
    String? productId,
    String? tradeId,
    required String paymentChannel,
    required String idempotencyKey,
  });
  Future<TransactionModel> simulatePay(String reference);
}

class TransactionRemoteDataSourceImpl implements TransactionRemoteDataSource {
  final DioClient dioClient;

  TransactionRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<List<TransactionModel>> fetchTransactions() async {
    final response = await dioClient.dio.get(ApiEndpoints.transactions);
    final data = response.data as Map<String, dynamic>;
    final list = (data['transactions'] as List).cast<Map<String, dynamic>>();
    return list.map((e) => TransactionModel.fromJson(e)).toList();
  }

  @override
  Future<TransactionModel> fetchTransactionDetail(String id) async {
    final response = await dioClient.dio.get('${ApiEndpoints.transactions}/$id');
    final data = response.data as Map<String, dynamic>;
    return TransactionModel.fromJson(data['transaction'] as Map<String, dynamic>);
  }

  @override
  Future<TransactionModel> createTransaction({
    String? productId,
    String? tradeId,
    required String paymentChannel,
    required String idempotencyKey,
  }) async {
    final response = await dioClient.dio.post(
      ApiEndpoints.transactions,
      data: {
        if (productId != null) 'product_id': productId,
        if (tradeId != null) 'trade_id': tradeId,
        'payment_channel': paymentChannel,
      },
      options: Options(
        headers: {'X-Idempotency-Key': idempotencyKey},
      ),
    );
    return TransactionModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<TransactionModel> simulatePay(String reference) async {
    final response = await dioClient.dio.post(
      '${ApiEndpoints.simulatorPay}/$reference/pay',
    );
    final data = response.data as Map<String, dynamic>;
    return TransactionModel.fromJson(data['result']['transaction'] as Map<String, dynamic>);
  }
}
