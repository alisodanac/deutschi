import '../models/word_model.dart';
import '../../../../core/database/database_helper.dart';

abstract class WordLocalDataSource {
  Future<void> addWord(WordModel word, List<String> sentences);
  Future<List<WordModel>> getWords();
  Future<WordModel?> getWordById(int id);
  Future<List<WordModel>> getWordsByCategory(String category);
  Future<List<String>> getCategories();
  Future<List<String>> getSentences(int wordId);
  Future<void> updateWord(WordModel word, List<String> sentences);
  Future<List<WordModel>> getDueWords();
  Future<void> updateWordStats(WordModel word);
  Future<List<WordModel>> getWeakWords(int limit);
}

class WordLocalDataSourceImpl implements WordLocalDataSource {
  final DatabaseHelper databaseHelper;

  WordLocalDataSourceImpl(this.databaseHelper);

  // ... (existing methods)

  @override
  Future<List<WordModel>> getWeakWords(int limit) async {
    final db = await databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'words',
      orderBy: 'mastery_level ASC, srs_interval ASC',
      limit: limit,
    );

    return List.generate(maps.length, (i) {
      return WordModel.fromMap(maps[i]);
    });
  }

  @override
  Future<void> addWord(WordModel word, List<String> sentences) async {
    final db = await databaseHelper.database;
    await db.transaction((txn) async {
      final wordId = await txn.insert('words', word.toMap());
      for (var sentenceContent in sentences) {
        await txn.insert('sentences', {'word_id': wordId, 'content': sentenceContent});
      }
    });
  }

  @override
  Future<List<WordModel>> getWords() async {
    final db = await databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('words');
    return List.generate(maps.length, (i) {
      return WordModel.fromMap(maps[i]);
    });
  }

  @override
  Future<WordModel?> getWordById(int id) async {
    final db = await databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('words', where: 'id = ?', whereArgs: [id], limit: 1);
    if (maps.isEmpty) return null;
    return WordModel.fromMap(maps.first);
  }

  @override
  Future<List<WordModel>> getWordsByCategory(String category) async {
    final db = await databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'words',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'word ASC',
    );
    return List.generate(maps.length, (i) {
      return WordModel.fromMap(maps[i]);
    });
  }

  @override
  Future<List<String>> getCategories() async {
    final db = await databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT DISTINCT category FROM words WHERE category IS NOT NULL AND category != ""',
    );
    return List.generate(maps.length, (i) {
      return maps[i]['category'] as String;
    });
  }

  @override
  Future<List<String>> getSentences(int wordId) async {
    final db = await databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('sentences', where: 'word_id = ?', whereArgs: [wordId]);
    return List.generate(maps.length, (i) {
      return maps[i]['content'] as String;
    });
  }

  @override
  Future<void> updateWord(WordModel word, List<String> sentences) async {
    final db = await databaseHelper.database;
    await db.transaction((txn) async {
      await txn.update('words', word.toMap(), where: 'id = ?', whereArgs: [word.id]);
      await txn.delete('sentences', where: 'word_id = ?', whereArgs: [word.id]);
      for (var sentenceContent in sentences) {
        await txn.insert('sentences', {'word_id': word.id, 'content': sentenceContent});
      }
    });
  }

  @override
  Future<List<WordModel>> getDueWords() async {
    final db = await databaseHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final List<Map<String, dynamic>> maps = await db.query(
      'words',
      where: 'next_review <= ?',
      whereArgs: [now],
      orderBy: 'next_review ASC', // Prioritize most overdue
    );

    return List.generate(maps.length, (i) {
      return WordModel.fromMap(maps[i]);
    });
  }

  @override
  Future<void> updateWordStats(WordModel word) async {
    final db = await databaseHelper.database;
    await db.update(
      'words',
      {
        'mastery_level': word.masteryLevel,
        'next_review': word.nextReview,
        'last_review': word.lastReview,
        'srs_interval': word.srsInterval,
        'ease_factor': word.easeFactor,
        'streak': word.streak,
      },
      where: 'id = ?',
      whereArgs: [word.id],
    );
  }
}
