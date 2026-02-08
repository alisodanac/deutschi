import 'dart:convert';
import '../database/database_helper.dart';

/// Service responsible for exporting and importing word data as JSON.
class BackupService {
  final DatabaseHelper databaseHelper;

  BackupService(this.databaseHelper);

  /// Exports all words and their sentences to a JSON string.
  Future<String> exportToJson() async {
    final db = await databaseHelper.database;

    // Get all words
    final List<Map<String, dynamic>> wordMaps = await db.query('words');

    // Get all sentences
    final List<Map<String, dynamic>> sentenceMaps = await db.query('sentences');

    // Group sentences by word_id
    final Map<int, List<String>> sentencesByWordId = {};
    for (var sentence in sentenceMaps) {
      final wordId = sentence['word_id'] as int;
      final content = sentence['content'] as String;
      sentencesByWordId.putIfAbsent(wordId, () => []).add(content);
    }

    // Build export data
    final List<Map<String, dynamic>> wordsExport = wordMaps.map((wordMap) {
      final wordId = wordMap['id'] as int;
      return {...wordMap, 'sentences': sentencesByWordId[wordId] ?? []};
    }).toList();

    final exportData = {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'wordCount': wordsExport.length,
      'words': wordsExport,
    };

    return jsonEncode(exportData);
  }

  /// Imports words and sentences from a JSON string.
  /// Returns the number of words imported.
  Future<int> importFromJson(String jsonString) async {
    final db = await databaseHelper.database;

    final Map<String, dynamic> importData = jsonDecode(jsonString);

    // Validate version
    final version = importData['version'] as int?;
    if (version == null || version > 1) {
      throw Exception('Unsupported backup version: $version');
    }

    final List<dynamic> words = importData['words'] as List<dynamic>;
    int importedCount = 0;

    for (var wordData in words) {
      final wordMap = wordData as Map<String, dynamic>;
      final sentences = (wordMap['sentences'] as List<dynamic>?)?.cast<String>() ?? [];

      // Remove id and sentences from wordMap for insertion
      final wordMapForInsert = Map<String, dynamic>.from(wordMap)
        ..remove('id')
        ..remove('sentences');

      await db.transaction((txn) async {
        // Check if word already exists (by word text and type)
        final existing = await txn.query(
          'words',
          where: 'word = ? AND type = ?',
          whereArgs: [wordMapForInsert['word'], wordMapForInsert['type']],
        );

        int wordId;
        if (existing.isNotEmpty) {
          // Update existing word
          wordId = existing.first['id'] as int;
          await txn.update('words', wordMapForInsert, where: 'id = ?', whereArgs: [wordId]);
          // Delete old sentences
          await txn.delete('sentences', where: 'word_id = ?', whereArgs: [wordId]);
        } else {
          // Insert new word
          wordId = await txn.insert('words', wordMapForInsert);
          importedCount++;
        }

        // Insert sentences
        for (var sentence in sentences) {
          await txn.insert('sentences', {'word_id': wordId, 'content': sentence});
        }
      });
    }

    return importedCount;
  }

  /// Checks if there are changes since the last backup.
  Future<bool> hasChangesSince(DateTime? lastBackupTime) async {
    if (lastBackupTime == null) return true;

    final db = await databaseHelper.database;

    // Check if any words exist (simple check for now)
    // In a more robust implementation, we'd track lastModified timestamps
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM words');
    final count = result.first['count'] as int;

    return count > 0;
  }
}
