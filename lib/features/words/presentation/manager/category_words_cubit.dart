import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/use_cases/get_words_by_category_use_case.dart';
import 'category_words_state.dart';

class CategoryWordsCubit extends Cubit<CategoryWordsState> {
  final GetWordsByCategoryUseCase getWordsByCategory;

  CategoryWordsCubit(this.getWordsByCategory) : super(CategoryWordsInitial());

  Future<void> loadWords(String category) async {
    emit(CategoryWordsLoading());
    try {
      final words = await getWordsByCategory(category);
      emit(CategoryWordsSuccess(words, category: category));
    } catch (e) {
      emit(CategoryWordsFailure(e.toString()));
    }
  }
}
