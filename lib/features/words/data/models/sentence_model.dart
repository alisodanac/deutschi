import '../../domain/entities/sentence.dart';

class SentenceModel extends Sentence {
  const SentenceModel({super.id, required super.wordId, required super.content});

  factory SentenceModel.fromMap(Map<String, dynamic> map) {
    return SentenceModel(id: map['id'] as int?, wordId: map['word_id'] as int, content: map['content'] as String);
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'word_id': wordId, 'content': content};
  }
}
