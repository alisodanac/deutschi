import 'package:equatable/equatable.dart';

class Sentence extends Equatable {
  final int? id;
  final int wordId;
  final String content;

  const Sentence({this.id, required this.wordId, required this.content});

  @override
  List<Object?> get props => [id, wordId, content];
}
