import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'dutschi.db');
    return await openDatabase(path, version: 4, onCreate: _onCreate, onUpgrade: _onUpgrade);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE words(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        word TEXT NOT NULL,
        article TEXT,
        type TEXT,
        category TEXT,
        bw_image_path TEXT,
        color_image_path TEXT,
        plural TEXT,
        perfect TEXT,
        preterit TEXT,
        mastery_level INTEGER DEFAULT 0,
        next_review INTEGER DEFAULT 0,
        last_review INTEGER DEFAULT 0,
        srs_interval REAL DEFAULT 0.0,
        ease_factor REAL DEFAULT 2.5,
        streak INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE sentences(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        word_id INTEGER NOT NULL,
        content TEXT NOT NULL,
        FOREIGN KEY (word_id) REFERENCES words (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE test_results(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp INTEGER NOT NULL,
        mode TEXT,
        category TEXT,
        total_words INTEGER,
        correct_count INTEGER,
        wrong_count INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE word_attempts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        word_id INTEGER NOT NULL,
        test_result_id INTEGER NOT NULL,
        is_correct INTEGER NOT NULL,
        timestamp INTEGER NOT NULL,
        FOREIGN KEY (word_id) REFERENCES words(id) ON DELETE CASCADE,
        FOREIGN KEY (test_result_id) REFERENCES test_results(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE words ADD COLUMN plural TEXT');
      await db.execute('ALTER TABLE words ADD COLUMN perfect TEXT');
      await db.execute('ALTER TABLE words ADD COLUMN preterit TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE test_results(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          timestamp INTEGER NOT NULL,
          mode TEXT,
          category TEXT,
          total_words INTEGER,
          correct_count INTEGER,
          wrong_count INTEGER
        )
      ''');
      await db.execute('''
        CREATE TABLE word_attempts(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          word_id INTEGER NOT NULL,
          test_result_id INTEGER NOT NULL,
          is_correct INTEGER NOT NULL,
          timestamp INTEGER NOT NULL,
          FOREIGN KEY (word_id) REFERENCES words(id) ON DELETE CASCADE,
          FOREIGN KEY (test_result_id) REFERENCES test_results(id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 4) {
      // Add SRS and mastery tracking fields
      await db.execute('ALTER TABLE words ADD COLUMN mastery_level INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE words ADD COLUMN next_review INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE words ADD COLUMN last_review INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE words ADD COLUMN srs_interval REAL DEFAULT 0.0');
      await db.execute('ALTER TABLE words ADD COLUMN ease_factor REAL DEFAULT 2.5');
      await db.execute('ALTER TABLE words ADD COLUMN streak INTEGER DEFAULT 0');
    }
  }
}
