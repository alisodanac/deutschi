import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/use_cases/get_sentences_use_case.dart';

abstract class WordDetailsState extends Equatable {
  const WordDetailsState();

  @override
  List<Object> get props => [];
}

class WordDetailsInitial extends WordDetailsState {}

class WordDetailsLoading extends WordDetailsState {}

class WordDetailsSuccess extends WordDetailsState {
  final List<String> sentences;

  const WordDetailsSuccess(this.sentences);

  @override
  List<Object> get props => [sentences];
}

class WordDetailsFailure extends WordDetailsState {
  final String message;

  const WordDetailsFailure(this.message);

  @override
  List<Object> get props => [message];
}

class WordDetailsCubit extends Cubit<WordDetailsState> {
  final GetSentencesUseCase getSentencesUseCase;

  WordDetailsCubit(this.getSentencesUseCase) : super(WordDetailsInitial());

  Future<void> loadSentences(int wordId) async {
    emit(WordDetailsLoading());
    try {
      final sentences = await getSentencesUseCase(wordId);
      emit(WordDetailsSuccess(sentences));
    } catch (e) {
      emit(WordDetailsFailure(e.toString()));
    }
  }
}
