import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dutschi/core/theme/theme_cubit.dart';
import 'package:dutschi/core/constants.dart';
import 'package:dutschi/core/router/app_router.dart';
import 'package:dutschi/core/theme/app_theme.dart';
import 'package:dutschi/core/workers/backup_worker.dart';

import 'package:dutschi/core/services/notification_service.dart';

import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'injection_container.dart' as di;

void main() async {
  try {
    WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

    await di.init();

    // Initialize Workmanager for background tasks
    Workmanager().initialize(callbackDispatcher);

    // Initialize Notification Service
    await di.sl<NotificationService>().initialize();

    runApp(const MyApp());
  } catch (e, stack) {
    debugPrint('Startup error: $e');
    debugPrint(stack.toString());
    // If initialization fails, we still want to show something and remove splash
    runApp(
      MaterialApp(
        home: Scaffold(body: Center(child: Text('Initialization Error: $e\nCheck your settings and restart.'))),
      ),
    );
    FlutterNativeSplash.remove();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => di.sl<ThemeCubit>(),
      child: BlocBuilder<ThemeCubit, AppThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp.router(
            title: AppConstants.appName,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: _getThemeMode(themeMode),
            routerConfig: router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }

  ThemeMode _getThemeMode(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }
}
