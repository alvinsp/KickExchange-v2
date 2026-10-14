import 'package:flutter/foundation.dart';
import 'dart:io' as io;

class ApiEndpoints {
  // Default URL depends on running platform:
  // - Android emulator: http://10.0.2.2:3000/api/v1
  // - Web / Windows desktop / iOS: http://localhost:3000/api/v1
  static String get defaultBaseUrl {
    if (!kIsWeb) {
      try {
        if (io.Platform.isAndroid) {
          return 'http://10.0.2.2:3000/api/v1';
        }
      } catch (_) {}
    }
    return 'http://localhost:3000/api/v1';
  }

  // Auth endpoints
  static const String login    = '/auth/login';
  static const String register = '/auth/register';
  static const String me       = '/auth/me';

  // Products endpoints
  static const String products = '/products';

  // Trades endpoints
  static const String trades   = '/trades';

  // Transactions endpoints
  static const String transactions = '/transactions';

  // Payments endpoints
  static const String simulatorPay = '/payments/simulator';

  // Offline Sync
  static const String syncBatch = '/sync/batch';
}
