import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/todo_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../models/todo_model.dart';

class TodoListView extends StatelessWidget {
  const TodoListView({super.key});

  @override
  Widget build(BuildContext context) {
    final todoViewModel = Provider.of<TodoViewModel>(context);
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              authViewModel.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          )
        ],
      ),
      body: todoViewModel.todos.isEmpty 
          ? const Center(child: Text('No secure tasks found.'))
          : ListView.builder(
              itemCount: todoViewModel.todos.length,
              itemBuilder: (context, index) {
                final todo = todoViewModel.todos[index];
                return ListTile(
                  leading: const Icon(Icons.security, color: Colors.green),
                  title: Text(todo.title, style: TextStyle(
                    decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                  )),
                  subtitle: const Text('Tap to view encrypted secret note'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blueGrey),
                        onPressed: () => _showAddTaskDialog(context, todoViewModel, todo: todo),
                      ),
                      Checkbox(
                        value: todo.isCompleted,
                        onChanged: (val) => todoViewModel.toggleTodoStatus(todo),
                      ),
                    ],
                  ),
                  onTap: () => _showSecretNote(context, todo, todoViewModel),
                  onLongPress: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Task?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('No')),
                          TextButton(onPressed: () {
                            todoViewModel.deleteTodo(todo.id!);
                            Navigator.pop(context);
                          }, child: const Text('Yes')),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context, todoViewModel),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showSecretNote(BuildContext context, TodoModel todo, TodoViewModel vm) {
    final decryptedNote = vm.decryptSecretNote(todo.encryptedSecretNotes);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Secret Note: ${todo.title}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('DECRYPTED DATA:', style: TextStyle(fontSize: 10, color: Colors.grey)),
            const SizedBox(height: 8),
            Text(decryptedNote, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context, TodoViewModel vm, {TodoModel? todo}) {
    final titleController = TextEditingController(text: todo?.title ?? '');
    final noteController = TextEditingController(
      text: todo != null ? vm.decryptSecretNote(todo.encryptedSecretNotes) : '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(todo == null ? 'New Secure Task' : 'Edit Secure Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
            TextField(controller: noteController, decoration: const InputDecoration(labelText: 'Secret Note (AES-256)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                if (todo == null) {
                  vm.addTodo(titleController.text, noteController.text);
                } else {
                  vm.updateTodo(todo.id!, titleController.text, noteController.text);
                }
                Navigator.pop(context);
              }
            },
            child: Text(todo == null ? 'Secure Save' : 'Update Securely'),
          ),
        ],
      ),
    );
  }
}
