import '../repository/word_repository.dart';
import '../entities/word.dart';

class GetWordsUseCase {
  final WordRepository repository;

  GetWordsUseCase(this.repository);

  Future<List<Word>> call() async {
    return await repository.getWords();
  }
}
