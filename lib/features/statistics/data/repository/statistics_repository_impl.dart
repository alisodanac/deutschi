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

  @override
  Future<int> getDailyStreak() async {
    final dates = await localDataSource.getUniqueTestDates();
    if (dates.isEmpty) return 0;

    int streak = 0;
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    // Check if today is present
    bool streakActive = false;
    if (dates.contains(todayStr)) {
      streakActive = true;
    } else {
      // Check yesterday
      final yesterday = now.subtract(const Duration(days: 1));
      final yesterdayStr =
          "${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}";
      if (dates.contains(yesterdayStr)) {
        streakActive = true;
      }
    }

    if (!streakActive) return 0;

    // Calculate streak
    // Example dates: [2023-10-27, 2023-10-26, 2023-10-24]
    // If today is 27, starts with 27.

    // We need to parse dates to handle gaps correctly?
    // Or just look for previous day string?
    // Parsing is safer for date math.

    DateTime currentDate = DateTime.now();
    // Normalize to midnight
    currentDate = DateTime(currentDate.year, currentDate.month, currentDate.day);

    // If today is not in list, check if yesterday is (streak continuity allowed for 1 day gap effectively? No, streak means consecutive days).
    // Usually streak means you did it today OR you did it yesterday (so streak is valid but not incremented for today yet).
    // If I haven't done it today, my streak is X (from yesterday). If I don't do it today, tomorrow it becomes 0.
    // So if today is NOT in list, start checking from yesterday.

    if (!dates.contains(todayStr)) {
      currentDate = currentDate.subtract(const Duration(days: 1));
      final yesterdayStr =
          "${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}";
      if (!dates.contains(yesterdayStr)) return 0;
    }

    // Iterate
    for (int i = 0; i < dates.length; i++) {
      // We need to match currentDate with dates[i]
      // Since dates is sorted DESC
      // We check if dates contains currentDate formatting
      final checkStr =
          "${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}";
      if (dates.contains(checkStr)) {
        streak++;
        currentDate = currentDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  @override
  Future<List<WordStats>> getWeakWords(int limit) async {
    final weakWords = await wordLocalDataSource.getWeakWords(limit);
    final result = <WordStats>[];

    for (final word in weakWords) {
      if (word.id == null) continue;
      final stats = await localDataSource.getWordAttemptStats(word.id!);

      result.add(
        WordStats(
          word: word,
          totalAttempts: stats?['total'] as int? ?? 0,
          correctAttempts: stats?['correct'] as int? ?? 0,
        ),
      );
    }
    return result;
  }
}
