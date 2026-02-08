import '../repository/word_repository.dart';
import '../entities/word.dart';

class AddWordUseCase {
  final WordRepository repository;

  AddWordUseCase(this.repository);

  Future<void> call(Word word, List<String> sentences) async {
    return await repository.addWord(word, sentences);
  }
}
