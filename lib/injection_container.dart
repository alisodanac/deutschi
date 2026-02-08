import 'package:get_it/get_it.dart';

import 'core/database/database_helper.dart';
import 'features/add_word/data/datasource/word_local_data_source.dart';
import 'features/add_word/data/repository/word_repository_impl.dart';
import 'features/add_word/domain/repository/word_repository.dart';
import 'features/add_word/domain/use_cases/add_word_use_case.dart';
import 'features/add_word/domain/use_cases/get_words_use_case.dart';
import 'features/add_word/presentation/manager/add_word_cubit.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //! Features - Add Word
  // Bloc
  sl.registerFactory(() => AddWordCubit(sl()));

  // Use cases
  sl.registerLazySingleton(() => AddWordUseCase(sl()));
  sl.registerLazySingleton(() => GetWordsUseCase(sl()));

  // Repository
  sl.registerLazySingleton<WordRepository>(() => WordRepositoryImpl(sl()));

  // Data sources
  sl.registerLazySingleton<WordLocalDataSource>(() => WordLocalDataSourceImpl(sl()));

  //! Core
  sl.registerLazySingleton(() => DatabaseHelper());
}
