import 'package:equatable/equatable.dart';
import '../../domain/entities/word.dart';

abstract class CategoryWordsState extends Equatable {
  const CategoryWordsState();

  @override
  List<Object?> get props => [];
}

class CategoryWordsInitial extends CategoryWordsState {}

class CategoryWordsLoading extends CategoryWordsState {}

class CategoryWordsSuccess extends CategoryWordsState {
  final List<Word> words;
  final String category;

  const CategoryWordsSuccess(this.words, {required this.category});

  @override
  List<Object?> get props => [words, category];
}

class CategoryWordsFailure extends CategoryWordsState {
  final String message;

  const CategoryWordsFailure(this.message);

  @override
  List<Object?> get props => [message];
}
