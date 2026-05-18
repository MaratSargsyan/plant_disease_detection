import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter_application_1/models.dart';

class DatabaseHelper {
  static DatabaseHelper? _instance;
  static Database? _database;

  DatabaseHelper._();
  static DatabaseHelper get instance => _instance ??= DatabaseHelper._();

  static const String _dbName = 'History.db';
  static const int _dbVersion = 3;
  static const String _tableName = 'History';
  static const String _colId = 'ID';
  static const String _colDisease = 'Disease';
  static const String _colPercentage = 'Percentage';
  static const String _colImage = 'Image';
  static const String _colLat = 'Lat';
  static const String _colLng = 'Lng';
  static const String _colCreatedAt = 'CreatedAt';

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        $_colId INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE,
        $_colDisease TEXT,
        $_colPercentage TEXT,
        $_colImage TEXT,
        $_colLat REAL,
        $_colLng REAL,
        $_colCreatedAt TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE $_tableName ADD COLUMN $_colLat REAL');
      await db.execute('ALTER TABLE $_tableName ADD COLUMN $_colLng REAL');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE $_tableName ADD COLUMN $_colCreatedAt TEXT');
    }
  }

  Future<List<History>> getHistory() async {
    final db = await database;
    final rows = await db.query(_tableName, orderBy: '$_colId DESC');
    return rows.map(History.fromMap).toList();
  }

  Future<int> addHistory(History history) async {
    final db = await database;
    return db.insert(_tableName, history.toMap()
      ..[_colCreatedAt] = DateTime.now().toIso8601String());
  }

  Future<int> deleteHistory(History history) async {
    final db = await database;
    return db.delete(
      _tableName,
      where: '$_colId = ?',
      whereArgs: [history.historyId],
    );
  }

  Future<int> clearHistory() async {
    final db = await database;
    return db.delete(_tableName);
  }
}