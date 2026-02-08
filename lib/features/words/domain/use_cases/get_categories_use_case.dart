import '../repository/word_repository.dart';

class GetCategoriesUseCase {
  final WordRepository repository;

  GetCategoriesUseCase(this.repository);

  Future<List<String>> call() async {
    return await repository.getCategories();
  }
}
