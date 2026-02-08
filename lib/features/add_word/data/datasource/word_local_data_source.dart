import '../../data/models/word_model.dart';
import '../../../../core/database/database_helper.dart';

abstract class WordLocalDataSource {
  Future<void> addWord(WordModel word, List<String> sentences);
  Future<List<WordModel>> getWords();
}

class WordLocalDataSourceImpl implements WordLocalDataSource {
  final DatabaseHelper databaseHelper;

  WordLocalDataSourceImpl(this.databaseHelper);

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
}
