import '../../domain/entities/word.dart';

class WordModel extends Word {
  const WordModel({
    super.id,
    required super.word,
    super.article,
    super.type,
    super.category,
    super.bwImagePath,
    super.colorImagePath,
  });

  factory WordModel.fromMap(Map<String, dynamic> map) {
    return WordModel(
      id: map['id'] as int?,
      word: map['word'] as String,
      article: map['article'] as String?,
      type: map['type'] as String?,
      category: map['category'] as String?,
      bwImagePath: map['bw_image_path'] as String?,
      colorImagePath: map['color_image_path'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'word': word,
      'article': article,
      'type': type,
      'category': category,
      'bw_image_path': bwImagePath,
      'color_image_path': colorImagePath,
    };
  }
}
