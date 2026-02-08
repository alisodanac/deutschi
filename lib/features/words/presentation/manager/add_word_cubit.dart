import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/word.dart';
import '../../domain/use_cases/add_word_use_case.dart';
import '../../domain/use_cases/get_categories_use_case.dart';
import '../../domain/use_cases/update_word_use_case.dart';
import 'add_word_state.dart';

class AddWordCubit extends Cubit<AddWordState> {
  final AddWordUseCase addWordUseCase;
  final GetCategoriesUseCase getCategoriesUseCase;
  final UpdateWordUseCase updateWordUseCase;

  AddWordCubit(this.addWordUseCase, this.getCategoriesUseCase, this.updateWordUseCase) : super(AddWordInitial());

  Future<void> loadCategories() async {
    // Only go to loading if initial, otherwise we might lose form state if we re-fetch?
    // Actually, for now let's just emit Loaded with categories.
    try {
      final categories = await getCategoriesUseCase();
      emit(AddWordLoaded(categories));
    } catch (e) {
      // If fails to load categories, we can still show form but without autocomplete?
      // Or emit failure. Let's emit loaded with empty list to fallback.
      emit(const AddWordLoaded([]));
    }
  }

  Future<void> addWord(Word word, List<String> sentences) async {
    emit(AddWordLoading());
    try {
      await addWordUseCase(word, sentences);
      emit(AddWordSuccess());
    } catch (e) {
      emit(AddWordFailure(e.toString()));
    }
  }

  Future<void> updateWord(Word word, List<String> sentences) async {
    emit(AddWordLoading());
    try {
      await updateWordUseCase(word, sentences);
      emit(AddWordSuccess());
    } catch (e) {
      emit(AddWordFailure(e.toString()));
    }
  }
}
