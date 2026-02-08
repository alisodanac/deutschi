import '../entities/word.dart';

abstract class WordRepository {
  Future<void> addWord(Word word, List<String> sentences);
  Future<List<Word>> getWords();
  Future<List<String>> getCategories();
}
