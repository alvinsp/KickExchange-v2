import 'dart:convert';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import 'sync_local_data_source.dart';

abstract class SyncRemoteDataSource {
  Future<Map<String, dynamic>> sendBatch(List<SyncQueueItem> items);
}

class SyncRemoteDataSourceImpl implements SyncRemoteDataSource {
  final DioClient dioClient;

  SyncRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<Map<String, dynamic>> sendBatch(List<SyncQueueItem> items) async {
    final operations = items.map((item) {
      return {
        'idempotency_key': item.idempotencyKey,
        'type': item.type,
        'payload': jsonDecode(item.payloadJson),
      };
    }).toList();

    final response = await dioClient.dio.post(
      ApiEndpoints.syncBatch,
      data: {'operations': operations},
    );

    return response.data as Map<String, dynamic>;
  }
}
