import 'package:get_it/get_it.dart';

import 'core/database/database_helper.dart';
import 'core/services/backup_service.dart';
import 'core/services/drive_service.dart';
import 'features/words/data/datasource/word_local_data_source.dart';
import 'features/words/data/repository/word_repository_impl.dart';
import 'features/words/domain/repository/word_repository.dart';
import 'features/words/domain/use_cases/add_word_use_case.dart';
import 'features/words/domain/use_cases/get_words_use_case.dart';
import 'features/words/domain/use_cases/get_categories_use_case.dart';
import 'features/words/presentation/manager/add_word_cubit.dart';
import 'features/words/presentation/manager/words_list_cubit.dart';
import 'features/words/presentation/manager/category_words_cubit.dart';
import 'features/words/domain/use_cases/get_words_by_category_use_case.dart';
import 'features/words/domain/use_cases/get_sentences_use_case.dart';
import 'features/words/presentation/manager/word_details_cubit.dart';
import 'features/test/presentation/manager/test_cubit.dart';
import 'features/words/domain/use_cases/update_word_use_case.dart';
import 'features/settings/presentation/manager/backup_settings_cubit.dart';
import 'features/settings/presentation/manager/notification_settings_cubit.dart';
import 'core/theme/theme_cubit.dart';
import 'core/services/notification_service.dart';
import 'features/statistics/data/datasource/statistics_local_data_source.dart';
import 'features/statistics/data/repository/statistics_repository_impl.dart';
import 'features/statistics/domain/repository/statistics_repository.dart';
import 'features/statistics/presentation/manager/statistics_cubit.dart';
import 'core/services/tts_service.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //! Features - Add Word
  // Bloc
  sl.registerFactory(() => AddWordCubit(sl(), sl(), sl()));
  sl.registerFactory(() => WordsListCubit(sl()));
  sl.registerFactory(() => CategoryWordsCubit(sl()));

  sl.registerFactory(() => WordDetailsCubit(sl()));
  sl.registerFactory(() => TestCubit(sl(), sl(), sl(), sl(), sl()));
  sl.registerFactory(() => BackupSettingsCubit(sl(), sl()));
  sl.registerFactory(() => ThemeCubit());
  sl.registerFactory(() => NotificationSettingsCubit(sl()));
  sl.registerFactory(() => StatisticsCubit(sl()));

  // Use cases
  sl.registerLazySingleton(() => AddWordUseCase(sl()));
  sl.registerLazySingleton(() => GetWordsUseCase(sl()));
  sl.registerLazySingleton(() => GetCategoriesUseCase(sl()));
  sl.registerLazySingleton(() => GetWordsByCategoryUseCase(sl()));
  sl.registerLazySingleton(() => GetSentencesUseCase(sl()));
  sl.registerLazySingleton(() => UpdateWordUseCase(sl()));

  // Repository
  sl.registerLazySingleton<WordRepository>(() => WordRepositoryImpl(sl()));
  sl.registerLazySingleton<StatisticsRepository>(() => StatisticsRepositoryImpl(sl(), sl()));

  // Data sources
  sl.registerLazySingleton<WordLocalDataSource>(() => WordLocalDataSourceImpl(sl()));
  sl.registerLazySingleton(() => StatisticsLocalDataSource(sl(), sl()));

  //! Core
  sl.registerLazySingleton(() => DatabaseHelper());
  sl.registerLazySingleton(() => BackupService(sl()));
  sl.registerLazySingleton(() => DriveService());
  sl.registerLazySingleton(() => NotificationService());
  sl.registerLazySingleton(() => TTSService());
}
