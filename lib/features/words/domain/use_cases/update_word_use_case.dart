import '../repository/word_repository.dart';
import '../entities/word.dart';

class UpdateWordUseCase {
  final WordRepository repository;

  UpdateWordUseCase(this.repository);

  Future<void> call(Word word, List<String> sentences) async {
    return await repository.updateWord(word, sentences);
  }
}
