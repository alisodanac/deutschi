import 'package:equatable/equatable.dart';

abstract class WordsListState extends Equatable {
  const WordsListState();

  @override
  List<Object> get props => [];
}

class WordsListInitial extends WordsListState {}

class WordsListLoading extends WordsListState {}

class WordsListSuccess extends WordsListState {
  final List<String> categories;

  const WordsListSuccess(this.categories);

  @override
  List<Object> get props => [categories];
}

class WordsListFailure extends WordsListState {
  final String message;

  const WordsListFailure(this.message);

  @override
  List<Object> get props => [message];
}
