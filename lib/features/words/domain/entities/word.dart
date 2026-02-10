import 'package:equatable/equatable.dart';
import 'word_type.dart';

class Word extends Equatable {
  final int? id;
  final String word;
  final String? article;
  final WordType? type;
  final String? category;
  final String? bwImagePath;
  final String? colorImagePath;
  final String? plural;
  final String? perfect;
  final String? preterit;
  final int masteryLevel;
  final int nextReview; // Timestamp
  final int lastReview; // Timestamp
  final double srsInterval;
  final double easeFactor;
  final int streak;
  final List<String>? sentences;

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
    this.masteryLevel = 0,
    this.nextReview = 0,
    this.lastReview = 0,
    this.srsInterval = 0.0,
    this.easeFactor = 2.5,
    this.streak = 0,
    this.sentences,
  });

  Word copyWith({
    int? id,
    String? word,
    String? article,
    WordType? type,
    String? category,
    String? bwImagePath,
    String? colorImagePath,
    String? plural,
    String? perfect,
    String? preterit,
    int? masteryLevel,
    int? nextReview,
    int? lastReview,
    double? srsInterval,
    double? easeFactor,
    int? streak,
    List<String>? sentences,
  }) {
    return Word(
      id: id ?? this.id,
      word: word ?? this.word,
      article: article ?? this.article,
      type: type ?? this.type,
      category: category ?? this.category,
      bwImagePath: bwImagePath ?? this.bwImagePath,
      colorImagePath: colorImagePath ?? this.colorImagePath,
      plural: plural ?? this.plural,
      perfect: perfect ?? this.perfect,
      preterit: preterit ?? this.preterit,
      masteryLevel: masteryLevel ?? this.masteryLevel,
      nextReview: nextReview ?? this.nextReview,
      lastReview: lastReview ?? this.lastReview,
      srsInterval: srsInterval ?? this.srsInterval,
      easeFactor: easeFactor ?? this.easeFactor,
      streak: streak ?? this.streak,
      sentences: sentences ?? this.sentences,
    );
  }

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
    masteryLevel,
    nextReview,
    lastReview,
    srsInterval,
    easeFactor,
    streak,
    sentences,
  ];
}
