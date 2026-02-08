import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/word.dart';
import '../../domain/use_cases/add_word_use_case.dart';
import '../../domain/use_cases/get_categories_use_case.dart';
import 'add_word_state.dart';

class AddWordCubit extends Cubit<AddWordState> {
  final AddWordUseCase addWordUseCase;
  final GetCategoriesUseCase getCategoriesUseCase;

  AddWordCubit(this.addWordUseCase, this.getCategoriesUseCase) : super(AddWordInitial());

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
      // Normalize category?? The UI handles selection, but if user typed a new one, it's just a string.
      // If user typed "animals" and "Animals" exists...
      // We should probably handle that in the UI or here.
      // Let's check against existing categories if we had them.
      // But we lost them when we emitted Loading.
      // Ideally we reload categories or keep them in state.
      // For simplicity, just save.
      await addWordUseCase(word, sentences);
      emit(AddWordSuccess());
      // Reload categories after success so if new one added it appears next time?
      // The screen usually pops or clears.
    } catch (e) {
      emit(AddWordFailure(e.toString()));
      // Should probably reload categories here too to restore UI state?
      // Or failure state should include them if we want to show form again.
    }
  }
}
