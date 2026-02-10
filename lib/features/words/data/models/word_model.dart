import '../../domain/entities/word.dart';
import '../../domain/entities/word_type.dart';

class WordModel extends Word {
  const WordModel({
    super.id,
    required super.word,
    super.article,
    super.type,
    super.category,
    super.bwImagePath,
    super.colorImagePath,
    super.plural,
    super.perfect,
    super.preterit,
    super.masteryLevel,
    super.nextReview,
    super.lastReview,
    super.srsInterval,
    super.easeFactor,
    super.streak,
    super.sentences,
  });

  factory WordModel.fromMap(Map<String, dynamic> map) {
    return WordModel(
      id: map['id'] as int?,
      word: map['word'] as String,
      article: map['article'] as String?,
      type: WordType.fromString(map['type'] as String?),
      category: map['category'] as String?,
      bwImagePath: map['bw_image_path'] as String?,
      colorImagePath: map['color_image_path'] as String?,
      plural: map['plural'] as String?,
      perfect: map['perfect'] as String?,
      preterit: map['preterit'] as String?,
      masteryLevel: map['mastery_level'] as int? ?? 0,
      nextReview: map['next_review'] as int? ?? 0,
      lastReview: map['last_review'] as int? ?? 0,
      srsInterval: (map['srs_interval'] as num?)?.toDouble() ?? 0.0,
      easeFactor: (map['ease_factor'] as num?)?.toDouble() ?? 2.5,
      streak: map['streak'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'word': word,
      'article': article,
      'type': type?.toString(),
      'category': category,
      'bw_image_path': bwImagePath,
      'color_image_path': colorImagePath,
      'plural': plural,
      'perfect': perfect,
      'preterit': preterit,
      'mastery_level': masteryLevel,
      'next_review': nextReview,
      'last_review': lastReview,
      'srs_interval': srsInterval,
      'ease_factor': easeFactor,
      'streak': streak,
    };
  }
}
