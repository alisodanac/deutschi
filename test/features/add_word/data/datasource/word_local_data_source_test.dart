import 'package:dutschi/core/database/database_helper.dart';
import 'package:dutschi/features/words/data/datasource/word_local_data_source.dart';
import 'package:dutschi/features/words/data/models/word_model.dart';
import 'package:dutschi/features/words/domain/entities/word_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('WordLocalDataSource Test', () {
    late DatabaseHelper databaseHelper;
    late WordLocalDataSourceImpl dataSource;

    setUp(() async {
      // Reset database for each test if possible, or just use unique inputs
      // Since DatabaseHelper is a singleton, it is hard to reset.
      // We will just delete the DB file or tables.
      // For now, let's just assume it works for a single run
      databaseHelper = DatabaseHelper();
      dataSource = WordLocalDataSourceImpl(databaseHelper);

      // Clear tables
      final db = await databaseHelper.database;
      await db.delete('sentences');
      await db.delete('words');
    });

    test('should add and retrieve a word with sentences', () async {
      final wordFn = const WordModel(
        word: 'Tisch',
        article: 'Der',
        type: WordType.noun,
        category: 'Furniture',
        bwImagePath: '/path/to/bw',
        colorImagePath: '/path/to/color',
      );
      final sentences = ['Das ist ein Tisch.', 'Der Tisch ist braun.'];

      await dataSource.addWord(wordFn, sentences);

      final words = await dataSource.getWords();

      expect(words.length, 1);
      final retrievedWord = words.first;
      expect(retrievedWord.word, 'Tisch');
      expect(retrievedWord.article, 'Der');

      // Check sentences manually from DB since getWords only returns WordModels in current impl
      final db = await databaseHelper.database;
      final savedSentences = await db.query('sentences', where: 'word_id = ?', whereArgs: [retrievedWord.id]);
      expect(savedSentences.length, 2);
      expect(savedSentences[0]['content'], 'Das ist ein Tisch.');
    });
  });
}
