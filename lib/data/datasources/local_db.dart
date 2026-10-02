import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/question_package_model.dart';

class LocalDatabase {
  static final LocalDatabase instance = LocalDatabase._init();
  static Database? _database;

  LocalDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('guru_soal_ai.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    String path;
    if (kIsWeb) {
      path = filePath;
    } else {
      final dbPath = await getDatabasesPath();
      path = p.join(dbPath, filePath);
    }

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE question_packages (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        subject TEXT NOT NULL,
        educationLevel TEXT NOT NULL,
        grade TEXT NOT NULL,
        curriculum TEXT NOT NULL,
        topics TEXT NOT NULL,
        questionType TEXT NOT NULL,
        difficulty TEXT NOT NULL,
        totalQuestions INTEGER NOT NULL,
        durationMinutes INTEGER NOT NULL,
        academicYear TEXT,
        semester TEXT,
        schoolName TEXT,
        teacherName TEXT,
        createdAt TEXT NOT NULL,
        questions TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertPackage(QuestionPackageModel package) async {
    final db = await instance.database;
    return await db.insert(
      'question_packages',
      package.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updatePackage(QuestionPackageModel package) async {
    final db = await instance.database;
    return await db.update(
      'question_packages',
      package.toMap(),
      where: 'id = ?',
      whereArgs: [package.id],
    );
  }

  Future<int> deletePackage(String id) async {
    final db = await instance.database;
    return await db.delete(
      'question_packages',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<QuestionPackageModel?> getPackageById(String id) async {
    final db = await instance.database;
    final maps = await db.query(
      'question_packages',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return QuestionPackageModel.fromMap(maps.first);
    }
    return null;
  }

  Future<List<QuestionPackageModel>> getAllPackages() async {
    final db = await instance.database;
    final result = await db.query(
      'question_packages',
      orderBy: 'createdAt DESC',
    );

    return result.map((map) => QuestionPackageModel.fromMap(map)).toList();
  }

  Future<List<QuestionPackageModel>> searchPackages(String query) async {
    final db = await instance.database;
    final result = await db.query(
      'question_packages',
      where: 'title LIKE ? OR subject LIKE ? OR topics LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'createdAt DESC',
    );

    return result.map((map) => QuestionPackageModel.fromMap(map)).toList();
  }
}
