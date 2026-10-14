class ServerException implements Exception {
  final String message;
  final String? code;
  final int? statusCode;

  ServerException({
    required this.message,
    this.code,
    this.statusCode,
  });

  @override
  String toString() => 'ServerException: $message (code: $code, status: $statusCode)';
}

class CacheException implements Exception {
  final String message;
  CacheException({required this.message});

  @override
  String toString() => 'CacheException: $message';
}

class NetworkException implements Exception {
  final String message;
  NetworkException({required this.message});

  @override
  String toString() => 'NetworkException: $message';
}
