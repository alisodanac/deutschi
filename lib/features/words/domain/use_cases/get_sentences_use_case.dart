import '../repository/word_repository.dart';

class GetSentencesUseCase {
  final WordRepository repository;

  GetSentencesUseCase(this.repository);

  Future<List<String>> call(int wordId) async {
    return await repository.getSentences(wordId);
  }
}
