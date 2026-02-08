import '../entities/test_result.dart';
import '../entities/word_attempt.dart';
import '../entities/word_stats.dart';

abstract class StatisticsRepository {
  /// Save a test result and return the inserted ID
  Future<int> saveTestResult(TestResult result);

  /// Save a word attempt
  Future<void> saveWordAttempt(WordAttempt attempt);

  /// Get all test results, ordered by timestamp descending
  Future<List<TestResult>> getTestHistory();

  /// Get statistics for a specific word
  Future<WordStats?> getWordStats(int wordId);

  /// Get statistics for all words that have been tested
  Future<List<WordStats>> getAllWordStats();

  /// Get overall statistics
  Future<OverallStats> getOverallStats();
}

class OverallStats {
  final int totalTests;
  final int totalAttempts;
  final int totalCorrect;
  final int wordsLearned;
  final int wordsInProgress;

  OverallStats({
    required this.totalTests,
    required this.totalAttempts,
    required this.totalCorrect,
    required this.wordsLearned,
    required this.wordsInProgress,
  });

  double get overallAccuracy => totalAttempts > 0 ? totalCorrect / totalAttempts : 0;
}
