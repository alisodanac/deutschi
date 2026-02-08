import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/word.dart';
import '../../domain/use_cases/add_word_use_case.dart';
import 'add_word_state.dart';

class AddWordCubit extends Cubit<AddWordState> {
  final AddWordUseCase addWordUseCase;

  AddWordCubit(this.addWordUseCase) : super(AddWordInitial());

  Future<void> addWord(Word word, List<String> sentences) async {
    emit(AddWordLoading());
    try {
      await addWordUseCase(word, sentences);
      emit(AddWordSuccess());
    } catch (e) {
      emit(AddWordFailure(e.toString()));
    }
  }
}
