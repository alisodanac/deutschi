import 'package:dutschi/features/words/domain/repository/word_repository.dart';

import 'package:dutschi/features/words/domain/entities/word.dart';
import 'package:dutschi/features/words/data/datasource/word_local_data_source.dart';
import 'package:dutschi/features/words/data/models/word_model.dart';

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

  @override
  Future<List<Word>> getWordsByCategory(String category) async {
    return await localDataSource.getWordsByCategory(category);
  }

  @override
  Future<List<String>> getCategories() async {
    return await localDataSource.getCategories();
  }

  @override
  Future<List<String>> getSentences(int wordId) async {
    return await localDataSource.getSentences(wordId);
  }

  @override
  Future<void> updateWord(Word word, List<String> sentences) async {
    final wordModel = WordModel(
      id: word.id,
      word: word.word,
      article: word.article,
      type: word.type,
      category: word.category,
      bwImagePath: word.bwImagePath,
      colorImagePath: word.colorImagePath,
      plural: word.plural,
      perfect: word.perfect,
      preterit: word.preterit,
    );
    await localDataSource.updateWord(wordModel, sentences);
  }
}
