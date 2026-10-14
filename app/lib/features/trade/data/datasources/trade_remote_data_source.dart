import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/trade_offer_model.dart';

abstract class TradeRemoteDataSource {
  Future<List<TradeOfferModel>> fetchTrades({String type = 'all'});
  Future<TradeOfferModel> fetchTradeDetail(String id);
  Future<TradeOfferModel> createTrade({
    required TradeOfferModel trade,
    required String idempotencyKey,
  });
  Future<TradeOfferModel> applyAction({
    required String tradeId,
    required String action,
    required String idempotencyKey,
  });
}

class TradeRemoteDataSourceImpl implements TradeRemoteDataSource {
  final DioClient dioClient;

  TradeRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<List<TradeOfferModel>> fetchTrades({String type = 'all'}) async {
    final response = await dioClient.dio.get(
      ApiEndpoints.trades,
      queryParameters: {'type': type},
    );
    final data = response.data as Map<String, dynamic>;
    final list = (data['trades'] as List).cast<Map<String, dynamic>>();
    return list.map((e) => TradeOfferModel.fromJson(e)).toList();
  }

  @override
  Future<TradeOfferModel> fetchTradeDetail(String id) async {
    final response = await dioClient.dio.get('${ApiEndpoints.trades}/$id');
    final data = response.data as Map<String, dynamic>;
    return TradeOfferModel.fromJson(data['trade'] as Map<String, dynamic>);
  }

  @override
  Future<TradeOfferModel> createTrade({
    required TradeOfferModel trade,
    required String idempotencyKey,
  }) async {
    final response = await dioClient.dio.post(
      ApiEndpoints.trades,
      data: trade.toJson(),
      options: Options(
        headers: {'X-Idempotency-Key': idempotencyKey},
      ),
    );
    return TradeOfferModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<TradeOfferModel> applyAction({
    required String tradeId,
    required String action,
    required String idempotencyKey,
  }) async {
    final response = await dioClient.dio.post(
      '${ApiEndpoints.trades}/$tradeId/action',
      data: {'action': action},
      options: Options(
        headers: {'X-Idempotency-Key': idempotencyKey},
      ),
    );
    return TradeOfferModel.fromJson(response.data as Map<String, dynamic>);
  }
}
