import 'package:dutschi/features/add_word/domain/repository/word_repository.dart';

import 'package:dutschi/features/add_word/domain/entities/word.dart';
import 'package:dutschi/features/add_word/data/datasource/word_local_data_source.dart';
import 'package:dutschi/features/add_word/data/models/word_model.dart';

class WordRepositoryImpl implements WordRepository {
  final WordLocalDataSource localDataSource;

  WordRepositoryImpl(this.localDataSource);

  @override
  Future<void> addWord(Word word, List<String> sentences) async {
    final wordModel = WordModel(
      word: word.word,
      article: word.article,
      type: word.type,
      category: word.category,
      bwImagePath: word.bwImagePath,
      colorImagePath: word.colorImagePath,
    );
    await localDataSource.addWord(wordModel, sentences);
  }

  @override
  Future<List<Word>> getWords() async {
    final wordModels = await localDataSource.getWords();
    return wordModels; // WordModel extends Word, so this is valid
  }
}
