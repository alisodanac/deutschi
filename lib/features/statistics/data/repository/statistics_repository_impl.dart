import '../../domain/entities/test_result.dart';
import '../../domain/entities/word_attempt.dart';
import '../../domain/entities/word_stats.dart';
import '../../domain/repository/statistics_repository.dart';
import '../datasource/statistics_local_data_source.dart';
import '../../../words/data/datasource/word_local_data_source.dart';

class StatisticsRepositoryImpl implements StatisticsRepository {
  final StatisticsLocalDataSource localDataSource;
  final WordLocalDataSource wordLocalDataSource;

  StatisticsRepositoryImpl(this.localDataSource, this.wordLocalDataSource);

  @override
  Future<int> saveTestResult(TestResult result) async {
    return await localDataSource.insertTestResult(result);
  }

  @override
  Future<void> saveWordAttempt(WordAttempt attempt) async {
    await localDataSource.insertWordAttempt(attempt);
  }

  @override
  Future<List<TestResult>> getTestHistory() async {
    return await localDataSource.getTestHistory();
  }

  @override
  Future<WordStats?> getWordStats(int wordId) async {
    final stats = await localDataSource.getWordAttemptStats(wordId);
    if (stats == null) return null;

    final word = await wordLocalDataSource.getWordById(wordId);
    if (word == null) return null;

    return WordStats(word: word, totalAttempts: stats['total'] as int, correctAttempts: stats['correct'] as int);
  }

  @override
  Future<List<WordStats>> getAllWordStats() async {
    final statsList = await localDataSource.getAllWordAttemptStats();
    final result = <WordStats>[];

    for (final stats in statsList) {
      final wordId = stats['word_id'] as int;
      final word = await wordLocalDataSource.getWordById(wordId);
      if (word != null) {
        result.add(
          WordStats(word: word, totalAttempts: stats['total'] as int, correctAttempts: stats['correct'] as int),
        );
      }
    }

    return result;
  }

  @override
  Future<OverallStats> getOverallStats() async {
    return await localDataSource.getOverallStats();
  }
}
