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
    };
  }
}
