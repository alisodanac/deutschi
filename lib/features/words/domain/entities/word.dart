import 'package:equatable/equatable.dart';

class Word extends Equatable {
  final int? id;
  final String word;
  final String? article;
  final String? type;
  final String? category;
  final String? bwImagePath;
  final String? colorImagePath;
  final String? plural;
  final String? perfect;
  final String? preterit;

  const Word({
    this.id,
    required this.word,
    this.article,
    this.type,
    this.category,
    this.bwImagePath,
    this.colorImagePath,
    this.plural,
    this.perfect,
    this.preterit,
  });

  @override
  List<Object?> get props => [
    id,
    word,
    article,
    type,
    category,
    bwImagePath,
    colorImagePath,
    plural,
    perfect,
    preterit,
  ];
}
