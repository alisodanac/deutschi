import '../entities/word.dart';

abstract class WordRepository {
  Future<void> addWord(Word word, List<String> sentences);
  Future<List<Word>> getWords();
  Future<List<Word>> getWordsByCategory(String category);
  Future<List<String>> getCategories();
  Future<List<String>> getSentences(int wordId);
  Future<void> updateWord(Word word, List<String> sentences);
}
