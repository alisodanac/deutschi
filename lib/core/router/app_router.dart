import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../layout/main_layout.dart';
import '../../features/test/presentation/screens/test_screen.dart';
import '../../features/statistics/presentation/screens/statistics_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/words/presentation/screens/add_word_screen.dart';
import '../../features/words/presentation/screens/words_list_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/test',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainLayout(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [GoRoute(path: '/test', builder: (context, state) => const TestScreen())],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: '/words', builder: (context, state) => const WordsListScreen())],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: '/statistics', builder: (context, state) => const StatisticsScreen())],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen())],
        ),
      ],
    ),
    GoRoute(
      path: '/add_word',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AddWordScreen(),
    ),
  ],
);
