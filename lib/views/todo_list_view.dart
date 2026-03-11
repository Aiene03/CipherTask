import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
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
  final TextEditingController _searchController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  String _searchQuery = '';
  String _sortBy = 'created';
  bool _showCompleted = true;
  String? _userName;
  String? _userEmail;
  String? _profileImageUrl;

  // Multi-selection state
  bool _isSelectionMode = false;
  final Set<int> _selectedTodoIds = {};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    _searchController.addListener(_onSearchChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  Future<void> _loadUserData() async {
    try {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      final email = await authViewModel.getLoggedInUserEmail();
      final profile = await authViewModel.getUserProfile();

      final firstName = (profile['firstName'] ?? '').trim();
      final lastName = (profile['lastName'] ?? '').trim();

      String displayName;
      if (firstName.isNotEmpty || lastName.isNotEmpty) {
        displayName = [
          firstName,
          lastName,
        ].where((v) => v.isNotEmpty).join(' ');
      } else if (email != null && email.contains('@')) {
        displayName = email.split('@').first;
      } else {
        displayName = 'User';
      }

      displayName = displayName.isNotEmpty
          ? '${displayName[0].toUpperCase()}${displayName.substring(1)}'
          : 'User';

      if (mounted) {
        setState(() {
          _userName = displayName;
          _userEmail = email;
          _profileImageUrl = profile['profileImageUrl'];
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
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

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedTodoIds.contains(id)) {
        _selectedTodoIds.remove(id);
        if (_selectedTodoIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedTodoIds.add(id);
        _isSelectionMode = true;
      }
    });
  }

  void _selectAll(List<TodoModel> todos) {
    setState(() {
      if (_selectedTodoIds.length == todos.length) {
        _selectedTodoIds.clear();
        _isSelectionMode = false;
      } else {
        _selectedTodoIds.addAll(todos.map((t) => t.id!));
        _isSelectionMode = true;
      }
    });
  }

  Future<void> _deleteSelected(TodoViewModel vm) async {
    final confirmed = await _showDeleteConfirmation(
      context,
      'Delete ${_selectedTodoIds.length} tasks?',
    );

    if (confirmed == true) {
      final idsToDelete = List<int>.from(_selectedTodoIds);
      for (var id in idsToDelete) {
        await vm.deleteTodo(id);
      }
      setState(() {
        _selectedTodoIds.clear();
        _isSelectionMode = false;
      });
    }
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context, String message) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.redAccent, width: 0.5),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            const SizedBox(width: 10),
            Text(
              'Confirm Delete',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        content: Text(
          '$message\nThis action cannot be undone.',
          style: GoogleFonts.inter(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'CANCEL',
              style: GoogleFonts.inter(color: Colors.white38),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final todoViewModel = Provider.of<TodoViewModel>(context);

    List<TodoModel> filteredTodos = todoViewModel.todos.where((todo) {
      final matchesSearch = todo.title.toLowerCase().contains(_searchQuery);
      final matchesCompletion = _showCompleted || !todo.isCompleted;
      return matchesSearch && matchesCompletion;
    }).toList();

    if (_sortBy == 'title') {
      filteredTodos.sort((a, b) => a.title.compareTo(b.title));
    } else {
      filteredTodos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    final completedCount = filteredTodos.where((t) => t.isCompleted).length;
    final progress = filteredTodos.isEmpty
        ? 0.0
        : completedCount / filteredTodos.length;

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode
          ? const Color(0xFF0D1117)
          : const Color(0xFFF8FAFC),
      appBar: _isSelectionMode
          ? _buildSelectionAppBar(filteredTodos, todoViewModel)
          : null,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [const Color(0xFF0D1117), const Color(0xFF161B22)]
                : [const Color(0xFFF5F7FA), const Color(0xFFE7EBF1)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!_isSelectionMode) _buildHeader(),
                _buildProgressCard(
                  completedCount,
                  filteredTodos.length,
                  progress,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(child: _buildSearchBar()),
                      const SizedBox(width: 12),
                      _buildFilterButton(),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.only(top: 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.02),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(35),
                        topRight: Radius.circular(35),
                      ),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: filteredTodos.isEmpty
                        ? _buildEmptyState()
                        : _buildTaskList(filteredTodos, todoViewModel),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: FloatingActionButton(
          onPressed: () => _showAddTaskDialog(context, todoViewModel),
          backgroundColor: Colors.cyanAccent,
          elevation: 8,
          child: const Icon(Icons.add, color: Color(0xFF0D1117), size: 30),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildSelectionAppBar(
    List<TodoModel> todos,
    TodoViewModel vm,
  ) {
    bool isAllSelected = _selectedTodoIds.length == todos.length;
    return AppBar(
      backgroundColor: const Color(0xFF1C2128),
      elevation: 4,
      leading: IconButton(
        icon: const Icon(Icons.close, color: Colors.white),
        onPressed: () => setState(() {
          _isSelectionMode = false;
          _selectedTodoIds.clear();
        }),
      ),
      title: Text(
        '${_selectedTodoIds.length} Selected',
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            isAllSelected ? Icons.deselect : Icons.select_all,
            color: Colors.cyanAccent,
          ),
          onPressed: () => _selectAll(todos),
          tooltip: 'Select All',
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          onPressed: () => _deleteSelected(vm),
          tooltip: 'Delete Selected',
        ),
      ],
    );
  }

  String _warmGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Widget _buildHeader() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final greeting = _warmGreeting();
    final nameText = _userName ?? 'User';
    final emailText = _userEmail ?? '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.white.withOpacity(0.06)
                  : const Color(0xFFF2F6FF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDarkMode
                    ? Colors.white.withOpacity(0.15)
                    : Colors.blue.withOpacity(0.1),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greeting,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: isDarkMode
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        nameText,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode
                              ? Colors.grey[200]
                              : Colors.blueGrey[700],
                        ),
                      ),
                      if (emailText.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          emailText,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDarkMode
                                ? Colors.white70
                                : Colors.blueGrey[600],
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        'Welcome back — here are your tasks',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDarkMode
                              ? Colors.white.withOpacity(0.72)
                              : Colors.blueGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/profile'),
                  child: Hero(
                    tag: 'profile_pic',
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Colors.cyanAccent.withOpacity(0.9),
                            Colors.blueAccent.withOpacity(0.6),
                          ],
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 26,
                        backgroundColor: isDarkMode
                            ? const Color(0xFF1C2128)
                            : Colors.white,
                        backgroundImage: _profileImageUrl != null
                            ? NetworkImage(_profileImageUrl!)
                            : null,
                        child: _profileImageUrl == null
                            ? Icon(
                                Icons.person,
                                color: Colors.cyanAccent,
                                size: 28,
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: -8,
            right: -8,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.cyanAccent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(int completed, int total, double progress) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.cyanAccent.withOpacity(0.15),
            Colors.blueAccent.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Progress',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$completed of $total tasks completed',
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white10,
                    color: Colors.cyanAccent,
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.cyanAccent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Text(
              '${(progress * 100).toInt()}%',
              style: GoogleFonts.orbitron(
                color: Colors.cyanAccent,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFF1C2128),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          hintText: 'Search encrypted tasks...',
          hintStyle: TextStyle(color: Colors.white30, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: Colors.cyanAccent, size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget _buildFilterButton() {
    return Container(
      height: 50,
      width: 50,
      decoration: BoxDecoration(
        color: const Color(0xFF1C2128),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: IconButton(
        icon: const Icon(Icons.tune, color: Colors.cyanAccent, size: 20),
        onPressed: () => _showSortSheet(),
      ),
    );
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sort & Settings',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              _buildSortTile('Date Created', 'created', Icons.calendar_today),
              _buildSortTile('Alphabetical', 'title', Icons.sort_by_alpha),
              const Divider(color: Colors.white10),
              SwitchListTile(
                title: const Text(
                  'Show Completed Tasks',
                  style: TextStyle(color: Colors.white),
                ),
                value: _showCompleted,
                activeColor: Colors.cyanAccent,
                onChanged: (val) {
                  setState(() => _showCompleted = val);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSortTile(String title, String val, IconData icon) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Icon(icon, color: isDarkMode ? Colors.white70 : Colors.black54),
      title: Text(
        title,
        style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
      ),
      trailing: _sortBy == val
          ? Icon(
              Icons.check_circle,
              color: isDarkMode ? Colors.cyanAccent : Colors.blueAccent,
            )
          : null,
      onTap: () {
        setState(() => _sortBy = val);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildTaskList(List<TodoModel> todos, TodoViewModel vm) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 100),
      itemCount: todos.length,
      itemBuilder: (context, index) {
        final todo = todos[index];
        final isSelected = _selectedTodoIds.contains(todo.id);
        final isDone = todo.isCompleted;

        return GestureDetector(
          onLongPress: () => _toggleSelection(todo.id!),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.cyanAccent.withOpacity(0.1)
                  : isDone
                  ? (isDarkMode
                        ? Colors.white.withOpacity(0.02)
                        : Colors.black.withOpacity(0.05))
                  : (isDarkMode
                        ? const Color(0xFF1C2128).withOpacity(0.8)
                        : Colors.white.withOpacity(0.96)),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isSelected
                    ? Colors.cyanAccent
                    : isDone
                    ? (isDarkMode ? Colors.white10 : Colors.black12)
                    : (isDarkMode
                          ? Colors.white.withOpacity(0.08)
                          : Colors.black.withOpacity(0.12)),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.cyanAccent.withOpacity(0.2),
                        blurRadius: 10,
                        spreadRadius: -2,
                      ),
                    ]
                  : null,
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 10,
              ),
              leading: _isSelectionMode
                  ? Checkbox(
                      value: isSelected,
                      activeColor: Colors.cyanAccent,
                      checkColor: isDarkMode
                          ? const Color(0xFF0D1117)
                          : const Color(0xFFFFFFFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      onChanged: (_) => _toggleSelection(todo.id!),
                    )
                  : InkWell(
                      onTap: () => vm.toggleTodoStatus(todo),
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDone ? Colors.cyanAccent : Colors.white24,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          isDone ? Icons.check_circle : Icons.circle_outlined,
                          color: isDone ? Colors.cyanAccent : Colors.white24,
                          size: 24,
                        ),
                      ),
                    ),
              title: Text(
                todo.title,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  decoration: isDone ? TextDecoration.lineThrough : null,
                  color: isDone ? Colors.white30 : Colors.white,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 12,
                      color: isDone
                          ? Colors.white12
                          : Colors.cyanAccent.withOpacity(0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MMM d, h:mm a').format(todo.createdAt),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isDone ? Colors.white12 : Colors.white38,
                      ),
                    ),
                    if (todo.encryptedSecretNotes.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Icon(
                        Icons.lock,
                        size: 12,
                        color: isDone
                            ? Colors.white12
                            : Colors.orangeAccent.withOpacity(0.5),
                      ),
                    ],
                  ],
                ),
              ),
              trailing: _isSelectionMode
                  ? null
                  : PopupMenuButton(
                      icon: const Icon(Icons.more_vert, color: Colors.white54),
                      color: const Color(0xFF1C2128),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 18, color: Colors.white70),
                              SizedBox(width: 8),
                              Text(
                                'Edit',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: Colors.redAccent,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Delete',
                                style: TextStyle(color: Colors.redAccent),
                              ),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (val) async {
                        if (val == 'edit') {
                          _showAddTaskDialog(context, vm, todo: todo);
                        }
                        if (val == 'delete') {
                          final confirmed = await _showDeleteConfirmation(
                            context,
                            'Delete this task?',
                          );
                          if (confirmed == true) {
                            vm.deleteTodo(todo.id!);
                          }
                        }
                      },
                    ),
              onTap: () {
                if (_isSelectionMode) {
                  _toggleSelection(todo.id!);
                } else {
                  _showSecretNote(context, todo, vm);
                }
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shield_outlined,
            size: 80,
            color: Colors.white.withOpacity(0.05),
          ),
          const SizedBox(height: 16),
          Text(
            'No tasks found',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white38,
            ),
          ),
          Text(
            'Your encrypted vault is currently empty.',
            style: GoogleFonts.inter(color: Colors.white24, fontSize: 13),
          ),
        ],
      ),
    );
  }

  void _showSecretNote(BuildContext context, TodoModel todo, TodoViewModel vm) {
    final decryptedNote = vm.decryptSecretNote(todo.encryptedSecretNotes);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.cyanAccent, width: 0.5),
        ),
        title: Row(
          children: [
            const Icon(Icons.lock_open, color: Colors.cyanAccent, size: 20),
            const SizedBox(width: 10),
            Text(
              'Decrypted Note',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            decryptedNote.isEmpty
                ? 'No additional notes attached.'
                : decryptedNote,
            style: GoogleFonts.inter(color: Colors.white70, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'DISMISS',
              style: GoogleFonts.inter(
                color: Colors.cyanAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
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
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0D1117),
            borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
            boxShadow: [
              BoxShadow(
                color: Colors.cyanAccent,
                blurRadius: 20,
                spreadRadius: -10,
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.cyanAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          todo == null ? Icons.add_task : Icons.edit,
                          color: Colors.cyanAccent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        todo == null ? 'NEW SECURE TASK' : 'UPDATE TASK',
                        style: GoogleFonts.orbitron(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.cyanAccent,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildTextField(titleController, 'Task Title', Icons.title),
                  const SizedBox(height: 16),
                  _buildTextField(
                    noteController,
                    'Secret Note (AES-256 Encrypted)',
                    Icons.enhanced_encryption,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () {
                        if (titleController.text.isNotEmpty) {
                          if (todo == null) {
                            vm.addTodo(
                              titleController.text,
                              noteController.text,
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
                        backgroundColor: Colors.cyanAccent,
                        foregroundColor: const Color(0xFF0D1117),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 5,
                        shadowColor: Colors.cyanAccent.withOpacity(0.5),
                      ),
                      child: Text(
                        todo == null ? 'INITIALIZE TASK' : 'SAVE CHANGES',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    int maxLines = 1,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF0D1117);
    final fillColor = isDarkMode
        ? const Color(0xFF1C2128)
        : const Color(0xFFF2F6FF);
    final hintColor = isDarkMode ? Colors.white38 : Colors.black45;
    final borderColor = isDarkMode ? Colors.white12 : Colors.black12;

    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: textColor, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: hintColor, fontSize: 13),
        prefixIcon: Icon(
          icon,
          color: isDarkMode
              ? Colors.cyanAccent.withOpacity(0.7)
              : Colors.blueAccent,
          size: 20,
        ),
        filled: true,
        fillColor: fillColor,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: isDarkMode ? Colors.cyanAccent : Colors.blueAccent,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.all(20),
      ),
    );
  }
}
