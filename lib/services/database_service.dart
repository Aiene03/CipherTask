import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import '../models/todo_model.dart';
import '../utils/constants.dart';

class DatabaseService {
  Database? _database;
  final String _dbKey;

  DatabaseService(this._dbKey);

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.dbName);
    
    debugPrint('--- DATABASE ENCRYPTION PROOF ---');
    debugPrint('DATABASE PATH: $path');
    debugPrint('STATUS: Initializing SQLCipher with hardware-backed key.');
    
    return await openDatabase(
      path,
      password: _dbKey,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE todos(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            encryptedSecretNotes TEXT,
            createdAt TEXT,
            isCompleted INTEGER
          )
        ''');
      },
    );
  }

  Future<int> insertTodo(TodoModel todo) async {
    final db = await database;
    return await db.insert('todos', todo.toMap());
  }

  Future<List<TodoModel>> getTodos() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('todos', orderBy: 'createdAt DESC');
    return List.generate(maps.length, (i) => TodoModel.fromMap(maps[i]));
  }

  Future<int> updateTodo(TodoModel todo) async {
    final db = await database;
    return await db.update(
      'todos',
      todo.toMap(),
      where: 'id = ?',
      whereArgs: [todo.id],
    );
  }

  Future<int> deleteTodo(int id) async {
    final db = await database;
    return await db.delete(
      'todos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
