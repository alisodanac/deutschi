import 'package:equatable/equatable.dart';

class Word extends Equatable {
  final int? id;
  final String word;
  final String? article;
  final String? type;
  final String? category;
  final String? bwImagePath;
  final String? colorImagePath;

  const Word({
    this.id,
    required this.word,
    this.article,
    this.type,
    this.category,
    this.bwImagePath,
    this.colorImagePath,
  });

  @override
  List<Object?> get props => [id, word, article, type, category, bwImagePath, colorImagePath];
}
