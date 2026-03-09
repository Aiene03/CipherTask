import 'package:flutter/material.dart';
import '../models/todo_model.dart';
import '../services/database_service.dart';
import '../services/encryption_service.dart';

class TodoViewModel extends ChangeNotifier {
  final DatabaseService _databaseService;
  final EncryptionService _encryptionService;
  List<TodoModel> _todos = [];

  List<TodoModel> get todos => _todos;

  TodoViewModel(this._databaseService, this._encryptionService) {
    _loadTodos();
  }

  Future<void> _loadTodos() async {
    _todos = await _databaseService.getTodos();
    notifyListeners();
  }

  Future<void> addTodo(String title, String secretNotes) async {
    final encryptedNotes = _encryptionService.encryptText(secretNotes);
    final todo = TodoModel(
      title: title,
      encryptedSecretNotes: encryptedNotes,
      createdAt: DateTime.now(),
    );
    await _databaseService.insertTodo(todo);
    await _loadTodos();
  }

  Future<void> updateTodo(int id, String title, String secretNotes) async {
    final encryptedNotes = _encryptionService.encryptText(secretNotes);
    final todo = TodoModel(
      id: id,
      title: title,
      encryptedSecretNotes: encryptedNotes,
      createdAt: DateTime.now(),
    );
    await _databaseService.updateTodo(todo);
    await _loadTodos();
  }

  Future<void> toggleTodoStatus(TodoModel todo) async {
    todo.isCompleted = !todo.isCompleted;
    await _databaseService.updateTodo(todo);
    await _loadTodos();
  }

  Future<void> deleteTodo(int id) async {
    await _databaseService.deleteTodo(id);
    await _loadTodos();
  }

  void clearData() {
    _todos = [];
    notifyListeners();
  }

  String decryptSecretNote(String encryptedNotes) {
    return _encryptionService.decryptText(encryptedNotes);
  }
}
