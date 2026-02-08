import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'package:dutschi/core/constants.dart';
import 'package:dutschi/core/router/app_router.dart';
import 'package:dutschi/core/theme/app_theme.dart';
import 'package:dutschi/core/workers/backup_worker.dart';

import 'injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();

  // Initialize Workmanager for background tasks
  Workmanager().initialize(callbackDispatcher);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      theme: AppTheme.theme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
