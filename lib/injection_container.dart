import 'package:get_it/get_it.dart';

import 'core/database/database_helper.dart';
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
import 'features/words/domain/use_cases/update_word_use_case.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //! Features - Add Word
  // Bloc
  sl.registerFactory(() => AddWordCubit(sl(), sl(), sl()));
  sl.registerFactory(() => WordsListCubit(sl()));
  sl.registerFactory(() => CategoryWordsCubit(sl()));
  sl.registerFactory(() => WordDetailsCubit(sl()));

  // Use cases
  sl.registerLazySingleton(() => AddWordUseCase(sl()));
  sl.registerLazySingleton(() => GetWordsUseCase(sl()));
  sl.registerLazySingleton(() => GetCategoriesUseCase(sl()));
  sl.registerLazySingleton(() => GetWordsByCategoryUseCase(sl()));
  sl.registerLazySingleton(() => GetSentencesUseCase(sl()));
  sl.registerLazySingleton(() => UpdateWordUseCase(sl()));

  // Repository
  sl.registerLazySingleton<WordRepository>(() => WordRepositoryImpl(sl()));

  // Data sources
  sl.registerLazySingleton<WordLocalDataSource>(() => WordLocalDataSourceImpl(sl()));

  //! Core
  sl.registerLazySingleton(() => DatabaseHelper());
}
