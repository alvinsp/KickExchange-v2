import 'package:flutter/material.dart';
import 'app.dart';
import 'injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Clean Architecture Inversion of Control & Dependencies
  await di.initDependencies();

  runApp(const KickExchangeApp());
}
