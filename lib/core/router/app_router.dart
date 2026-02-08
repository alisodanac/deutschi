import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../layout/main_layout.dart';
import '../../features/test/presentation/screens/test_screen.dart';
import '../../features/statistics/presentation/screens/statistics_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/words/presentation/screens/add_word_screen.dart';
import '../../features/words/presentation/screens/words_list_screen.dart';
import '../../features/words/presentation/screens/category_words_screen.dart';
import '../../features/words/presentation/screens/word_details_screen.dart';
import '../../features/words/domain/entities/word.dart';

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
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        if (extra != null) {
          final word = extra['word'] as Word?;
          final sentences = extra['sentences'] as List<String>?;
          return AddWordScreen(initialWord: word, initialSentences: sentences);
        }
        return const AddWordScreen();
      },
    ),
    GoRoute(
      path: '/category/:categoryName',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final categoryName = state.pathParameters['categoryName']!;
        return CategoryWordsScreen(categoryName: categoryName);
      },
    ),
    GoRoute(
      path: '/word_details',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final word = state.extra as Word;
        return WordDetailsScreen(word: word);
      },
    ),
  ],
);
