import '../repository/word_repository.dart';
import '../entities/word.dart';

class GetWordsByCategoryUseCase {
  final WordRepository repository;

  GetWordsByCategoryUseCase(this.repository);

  Future<List<Word>> call(String category) async {
    return await repository.getWordsByCategory(category);
  }
}
