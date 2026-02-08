import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/use_cases/get_categories_use_case.dart';
import 'words_list_state.dart';

class WordsListCubit extends Cubit<WordsListState> {
  final GetCategoriesUseCase getCategoriesUseCase;

  WordsListCubit(this.getCategoriesUseCase) : super(WordsListInitial());

  Future<void> loadCategories() async {
    emit(WordsListLoading());
    try {
      final categories = await getCategoriesUseCase();
      emit(WordsListSuccess(categories));
    } catch (e) {
      emit(WordsListFailure(e.toString()));
    }
  }
}
