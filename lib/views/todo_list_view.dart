import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../viewmodels/todo_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../models/todo_model.dart';

class TodoListView extends StatefulWidget {
  const TodoListView({super.key});

  @override
  State<TodoListView> createState() => _TodoListViewState();
}

class _TodoListViewState extends State<TodoListView>
    with TickerProviderStateMixin {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey();
  final TextEditingController _searchController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  String _searchQuery = '';
  String _sortBy = 'created'; // 'created', 'title', 'completed'
  bool _showCompleted = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();

    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    final todoViewModel = Provider.of<TodoViewModel>(context);
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

    // Filter and sort todos
    List<TodoModel> filteredTodos = todoViewModel.todos.where((todo) {
      final matchesSearch = todo.title.toLowerCase().contains(_searchQuery);
      final matchesCompletion = _showCompleted || !todo.isCompleted;
      return matchesSearch && matchesCompletion;
    }).toList();

    // Sort todos
    filteredTodos.sort((a, b) {
      switch (_sortBy) {
        case 'title':
          return a.title.compareTo(b.title);
        case 'completed':
          if (a.isCompleted == b.isCompleted) return 0;
          return a.isCompleted ? 1 : -1;
        case 'created':
        default:
          return b.createdAt.compareTo(a.createdAt); // Newest first
      }
    });

    // sync animated list length if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_listKey.currentState != null) {
        // nothing for now
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'CIPHERTASK',
          style: GoogleFonts.orbitron(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        actions: [
          // Clear completed tasks button
          if (todoViewModel.todos.any((t) => t.isCompleted))
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: IconButton(
                icon: const Icon(Icons.clear_all, color: Colors.orange),
                tooltip: 'Clear completed',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: const Color(0xFF1A1A2E),
                      title: const Text(
                        'Clear Completed Tasks',
                        style: TextStyle(color: Colors.white),
                      ),
                      content: const Text(
                        'Remove all completed tasks?',
                        style: TextStyle(color: Colors.white70),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            final completedTasks = todoViewModel.todos
                                .where((t) => t.isCompleted)
                                .toList();
                            for (var task in completedTasks) {
                              todoViewModel.deleteTodo(task.id!);
                            }
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'Clear',
                            style: TextStyle(color: Colors.orange),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.cyan.withValues(alpha: 0.3)),
            ),
            child: IconButton(
              icon: const Icon(Icons.logout, color: Colors.white70),
              tooltip: 'Logout',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: const Color(0xFF1A1A2E),
                    title: const Text(
                      'Logout',
                      style: TextStyle(color: Colors.white),
                    ),
                    content: const Text(
                      'Are you sure you want to logout?',
                      style: TextStyle(color: Colors.white70),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          authViewModel.logout();
                          
                          
                          if (context.mounted) {
                            Navigator.of(context).pushReplacementNamed('/login');
                          }
                        },
                        child: const Text(
                          'Logout',
                          style: TextStyle(color: Colors.cyan),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
            ),
          ),
          child: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),

                  // Professional Logo Container matching login theme
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.withValues(alpha: 0.15),
                          Colors.cyan.withValues(alpha: 0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: Colors.cyan.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.lock_outline,
                      size: 50,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Subtitle
                  Text(
                    'Your Secure Tasks',
                    style: TextStyle(
                      fontSize: 14,
                      letterSpacing: 2,
                      color: Colors.cyan.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Search Bar
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.cyan.withValues(alpha: 0.15),
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search tasks...',
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color: Colors.white.withValues(alpha: 0.5),
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Filter and Sort Controls
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Row(
                      children: [
                        // Sort Dropdown
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.cyan.withValues(alpha: 0.15),
                                width: 1,
                              ),
                            ),
                            child: DropdownButton<String>(
                              value: _sortBy,
                              dropdownColor: const Color(0xFF1A1A2E),
                              style: const TextStyle(color: Colors.white),
                              underline: const SizedBox(),
                              isExpanded: true,
                              items: const [
                                DropdownMenuItem(
                                  value: 'created',
                                  child: Text('Sort by Date'),
                                ),
                                DropdownMenuItem(
                                  value: 'title',
                                  child: Text('Sort by Title'),
                                ),
                                DropdownMenuItem(
                                  value: 'completed',
                                  child: Text('Sort by Status'),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _sortBy = value!;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Show Completed Toggle
                        Container(
                          decoration: BoxDecoration(
                            color: _showCompleted
                                ? Colors.cyan.withValues(alpha: 0.2)
                                : Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.cyan.withValues(alpha: 0.15),
                              width: 1,
                            ),
                          ),
                          child: IconButton(
                            icon: Icon(
                              _showCompleted
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: _showCompleted
                                  ? Colors.cyan
                                  : Colors.white.withValues(alpha: 0.5),
                            ),
                            tooltip: _showCompleted
                                ? 'Hide completed'
                                : 'Show completed',
                            onPressed: () {
                              setState(() {
                                _showCompleted = !_showCompleted;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Progress Indicator
                  if (todoViewModel.todos.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value:
                                  todoViewModel.todos
                                      .where((t) => t.isCompleted)
                                      .length /
                                  todoViewModel.todos.length,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.1,
                              ),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.cyan,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${((todoViewModel.todos.where((t) => t.isCompleted).length / todoViewModel.todos.length) * 100).round()}% Complete',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Task count and filter info
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Showing: ${filteredTodos.length} of ${todoViewModel.todos.length}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Completed: ${todoViewModel.todos.where((t) => t.isCompleted).length}',
                          style: TextStyle(
                            color: Colors.cyan.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Task list
                  Expanded(
                    child: filteredTodos.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _searchQuery.isNotEmpty
                                      ? Icons.search_off
                                      : Icons.security,
                                  size: 60,
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isNotEmpty
                                      ? 'No tasks match your search'
                                      : 'No secure tasks yet',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _searchQuery.isNotEmpty
                                      ? 'Try a different search term'
                                      : 'Tap + to add your first task',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : AnimatedList(
                            key: _listKey,
                            initialItemCount: filteredTodos.length,
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 16,
                            ),
                            itemBuilder: (context, index, animation) {
                              final todo = filteredTodos[index];
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.1),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: Dismissible(
                                    key: Key(todo.id.toString()),
                                    direction: DismissDirection.horizontal,
                                    background: Container(
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.greenAccent.withValues(
                                          alpha: 0.2,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      alignment: Alignment.centerLeft,
                                      padding: const EdgeInsets.only(left: 20),
                                      child: const Icon(
                                        Icons.check_circle,
                                        color: Colors.greenAccent,
                                        size: 28,
                                      ),
                                    ),
                                    secondaryBackground: Container(
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withValues(
                                          alpha: 0.2,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.only(right: 20),
                                      child: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                        size: 28,
                                      ),
                                    ),
                                    confirmDismiss: (direction) async {
                                      if (direction ==
                                          DismissDirection.startToEnd) {
                                        // Swipe right to complete/undo
                                        todoViewModel.toggleTodoStatus(todo);
                                        return false; // Don't dismiss, just toggle
                                      } else {
                                        // Swipe left to delete
                                        return await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text(
                                              'Delete Task?',
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                            backgroundColor: const Color(
                                              0xFF1A1A2E,
                                            ),
                                            content: const Text(
                                              'This action cannot be undone',
                                              style: TextStyle(
                                                color: Colors.white70,
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                  context,
                                                  false,
                                                ),
                                                child: const Text('Cancel'),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  todoViewModel.deleteTodo(
                                                    todo.id!,
                                                  );
                                                  Navigator.pop(context, true);
                                                },
                                                child: const Text(
                                                  'Delete',
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.08,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.cyan.withValues(
                                            alpha: 0.15,
                                          ),
                                          width: 1,
                                        ),
                                      ),
                                      child: ListTile(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 4,
                                            ),
                                        leading: Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: todo.isCompleted
                                                ? Colors.cyan.withValues(
                                                    alpha: 0.2,
                                                  )
                                                : Colors.greenAccent.withValues(
                                                    alpha: 0.2,
                                                  ),
                                          ),
                                          child: Icon(
                                            todo.isCompleted
                                                ? Icons.check_circle
                                                : Icons.security,
                                            color: todo.isCompleted
                                                ? Colors.cyan
                                                : Colors.greenAccent,
                                            size: 24,
                                          ),
                                        ),
                                        title: Text(
                                          todo.title,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                            decoration: todo.isCompleted
                                                ? TextDecoration.lineThrough
                                                : null,
                                          ),
                                        ),
                                        subtitle: Text(
                                          'Tap to view secret note • Swipe to complete/delete',
                                          style: TextStyle(
                                            color: Colors.white.withValues(
                                              alpha: 0.5,
                                            ),
                                            fontSize: 12,
                                          ),
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: Icon(
                                                Icons.edit,
                                                color: Colors.white.withValues(
                                                  alpha: 0.6,
                                                ),
                                                size: 20,
                                              ),
                                              tooltip: 'Edit task',
                                              onPressed: () =>
                                                  _showAddTaskDialog(
                                                    context,
                                                    todoViewModel,
                                                    todo: todo,
                                                  ),
                                            ),
                                            Checkbox(
                                              value: todo.isCompleted,
                                              activeColor: Colors.cyan,
                                              checkColor: const Color(
                                                0xFF1A1A2E,
                                              ),
                                              onChanged: (val) {
                                                todoViewModel.toggleTodoStatus(
                                                  todo,
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                        onTap: () => _showSecretNote(
                                          context,
                                          todo,
                                          todoViewModel,
                                        ),
                                        onLongPress: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text(
                                                'Delete Task?',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                              backgroundColor: const Color(
                                                0xFF1A1A2E,
                                              ),
                                              content: const Text(
                                                'This action cannot be undone',
                                                style: TextStyle(
                                                  color: Colors.white70,
                                                ),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  child: const Text('Cancel'),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    todoViewModel.deleteTodo(
                                                      todo.id!,
                                                    );
                                                    Navigator.pop(context);
                                                  },
                                                  child: const Text(
                                                    'Delete',
                                                    style: TextStyle(
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(colors: [Colors.blue, Colors.cyan]),
        ),
        child: FloatingActionButton(
          onPressed: () => _showAddTaskDialog(context, todoViewModel),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  void _showSecretNote(BuildContext context, TodoModel todo, TodoViewModel vm) {
    final decryptedNote = vm.decryptSecretNote(todo.encryptedSecretNotes);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text(
          'Secret Note: ${todo.title}',
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DECRYPTED DATA:',
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                decryptedNote.isEmpty ? 'No secret note' : decryptedNote,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: decryptedNote.isEmpty
                      ? Colors.white.withValues(alpha: 0.5)
                      : Colors.white,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.cyan)),
          ),
        ],
      ),
    );
  }

  void _showAddTaskDialog(
    BuildContext context,
    TodoViewModel vm, {
    TodoModel? todo,
  }) {
    final titleController = TextEditingController(text: todo?.title ?? '');
    final noteController = TextEditingController(
      text: todo != null ? vm.decryptSecretNote(todo.encryptedSecretNotes) : '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom:
              MediaQuery.of(context).viewInsets.bottom +
              MediaQuery.of(context).padding.bottom,
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: Colors.cyan.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  todo == null ? 'New Secure Task' : 'Edit Secure Task',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Title',
                    hintText: 'Enter task title',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    labelStyle: const TextStyle(color: Colors.white70),
                    prefixIcon: Icon(
                      Icons.title,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.cyan,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.black.withValues(alpha: 0.2),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: noteController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Secret Note (AES-256)',
                    hintText: 'Enter your encrypted note',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    labelStyle: const TextStyle(color: Colors.white70),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(bottom: 48),
                      child: Icon(
                        Icons.security,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.cyan,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.black.withValues(alpha: 0.2),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        colors: [Colors.blue, Colors.cyan],
                      ),
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        if (titleController.text.isNotEmpty) {
                          if (todo == null) {
                            vm.addTodo(
                              titleController.text,
                              noteController.text,
                            );
                            // insert animation
                            _listKey.currentState?.insertItem(
                              vm.todos.length - 1,
                            );
                          } else {
                            vm.updateTodo(
                              todo.id!,
                              titleController.text,
                              noteController.text,
                            );
                          }
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        todo == null ? 'Secure Save' : 'Update Securely',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
