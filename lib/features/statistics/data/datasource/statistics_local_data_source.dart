import '../../../../core/database/database_helper.dart';
import '../../../words/data/datasource/word_local_data_source.dart';
import '../../domain/entities/test_result.dart';
import '../../domain/entities/word_attempt.dart';
import '../../domain/repository/statistics_repository.dart';

class StatisticsLocalDataSource {
  final DatabaseHelper databaseHelper;
  final WordLocalDataSource wordLocalDataSource;

  StatisticsLocalDataSource(this.databaseHelper, this.wordLocalDataSource);

  Future<int> insertTestResult(TestResult result) async {
    final db = await databaseHelper.database;
    final map = result.toMap();
    map.remove('id'); // Let SQLite auto-generate
    return await db.insert('test_results', map);
  }

  Future<void> insertWordAttempt(WordAttempt attempt) async {
    final db = await databaseHelper.database;
    final map = attempt.toMap();
    map.remove('id');
    await db.insert('word_attempts', map);
  }

  Future<List<TestResult>> getTestHistory() async {
    final db = await databaseHelper.database;
    final results = await db.query('test_results', orderBy: 'timestamp DESC');
    return results.map((e) => TestResult.fromMap(e)).toList();
  }

  Future<Map<String, dynamic>?> getWordAttemptStats(int wordId) async {
    final db = await databaseHelper.database;
    final result = await db.rawQuery(
      '''
      SELECT 
        COUNT(*) as total,
        SUM(CASE WHEN is_correct = 1 THEN 1 ELSE 0 END) as correct
      FROM word_attempts
      WHERE word_id = ?
    ''',
      [wordId],
    );

    if (result.isEmpty || result.first['total'] == 0) {
      return null;
    }
    return result.first;
  }

  Future<List<Map<String, dynamic>>> getAllWordAttemptStats() async {
    final db = await databaseHelper.database;
    return await db.rawQuery('''
      SELECT 
        word_id,
        COUNT(*) as total,
        SUM(CASE WHEN is_correct = 1 THEN 1 ELSE 0 END) as correct
      FROM word_attempts
      GROUP BY word_id
    ''');
  }

  Future<OverallStats> getOverallStats() async {
    final db = await databaseHelper.database;

    // Total tests
    final testCountResult = await db.rawQuery('SELECT COUNT(*) as count FROM test_results');
    final totalTests = testCountResult.first['count'] as int;

    // Total attempts and correct
    final attemptResult = await db.rawQuery('''
      SELECT 
        COUNT(*) as total,
        SUM(CASE WHEN is_correct = 1 THEN 1 ELSE 0 END) as correct
      FROM word_attempts
    ''');
    final totalAttempts = attemptResult.first['total'] as int? ?? 0;
    final totalCorrect = attemptResult.first['correct'] as int? ?? 0;

    // Words learned (>= 3 attempts AND >= 80% success)
    final learnedResult = await db.rawQuery('''
      SELECT COUNT(*) as count FROM (
        SELECT word_id,
          COUNT(*) as total,
          SUM(CASE WHEN is_correct = 1 THEN 1 ELSE 0 END) as correct
        FROM word_attempts
        GROUP BY word_id
        HAVING total >= 3 AND (CAST(correct AS REAL) / total) >= 0.8
      )
    ''');
    final wordsLearned = learnedResult.first['count'] as int? ?? 0;

    // Words in progress (has attempts but not learned)
    final inProgressResult = await db.rawQuery('''
      SELECT COUNT(*) as count FROM (
        SELECT word_id,
          COUNT(*) as total,
          SUM(CASE WHEN is_correct = 1 THEN 1 ELSE 0 END) as correct
        FROM word_attempts
        GROUP BY word_id
        HAVING total < 3 OR (CAST(correct AS REAL) / total) < 0.8
      )
    ''');
    final wordsInProgress = inProgressResult.first['count'] as int? ?? 0;

    return OverallStats(
      totalTests: totalTests,
      totalAttempts: totalAttempts,
      totalCorrect: totalCorrect,
      wordsLearned: wordsLearned,
      wordsInProgress: wordsInProgress,
    );
  }
}
