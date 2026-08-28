import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../services/session.dart';
import '../../../widgets/app_dialogs.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_widget.dart';
import '../../../widgets/loading_widget.dart';
import '../models/todo.dart';
import '../services/todo_service.dart';
import '../widgets/todo_card.dart';
import '../widgets/todo_form_dialog.dart';
import '../widgets/todo_stats_view.dart';

class TodoHomeScreen extends StatefulWidget {
  const TodoHomeScreen({super.key});

  @override
  State<TodoHomeScreen> createState() => _TodoHomeScreenState();
}

class _TodoHomeScreenState extends State<TodoHomeScreen> {
  static const List<String> _statusOptions = ['ALL', 'PENDING', 'COMPLETED'];

  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  List<Todo> _items = [];
  TodoStats _stats = const TodoStats();
  bool _loading = true;
  String? _error;
  String _statusFilter = 'ALL';
  String _categoryFilter = 'All';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final result = await TodoService.fetchTodos(
        search: _searchController.text.trim(),
        status: _statusFilter,
        category: _categoryFilter == 'All' ? null : _categoryFilter,
      );
      if (!mounted) return;
      setState(() {
        _items = result.items;
        _stats = result.stats;
        _loading = false;
        _error = null;
      });
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _onSearchChanged(String _) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) _load(silent: true);
    });
  }

  void _setStatus(String status) {
    setState(() => _statusFilter = status);
    _load(silent: true);
  }

  void _setCategory(String category) {
    setState(() => _categoryFilter = category);
    _load(silent: true);
  }

  Future<void> _showAddDialog() async {
    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const TodoFormDialog(),
    );
    if (payload == null || !mounted) return;
    try {
      await TodoService.createTodo(
        title: payload['title'] as String,
        description: payload['description'] as String? ?? '',
        category: payload['category'] as String? ?? 'General',
        priority: payload['priority'] as String? ?? 'MEDIUM',
        dueDate: payload['dueDate'] as String?,
      );
      if (!mounted) return;
      AppDialogs.showSnack(context, 'Todo created successfully');
      await _load(silent: true);
    } on Exception catch (e) {
      if (!mounted) return;
      AppDialogs.showSnack(context, AppDialogs.friendlyError(e), error: true);
    }
  }

  Future<void> _showEditDialog(Todo todo) async {
    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => TodoFormDialog(todo: todo),
    );
    if (payload == null || !mounted) return;
    try {
      await TodoService.updateTodo(
        todo.id,
        title: payload['title'] as String,
        description: payload['description'] as String? ?? '',
        category: payload['category'] as String? ?? 'General',
        priority: payload['priority'] as String? ?? 'MEDIUM',
        dueDate: payload['dueDate'] as String?,
      );
      if (!mounted) return;
      AppDialogs.showSnack(context, 'Todo updated successfully');
      await _load(silent: true);
    } on Exception catch (e) {
      if (!mounted) return;
      AppDialogs.showSnack(context, AppDialogs.friendlyError(e), error: true);
    }
  }

  Future<void> _toggleTodo(Todo todo) async {
    try {
      await TodoService.toggleTodo(todo.id, !todo.completed);
      if (!mounted) return;
      AppDialogs.showSnack(
        context,
        todo.completed ? 'Todo marked as pending' : 'Todo marked as completed',
      );
      await _load(silent: true);
    } on Exception catch (e) {
      if (!mounted) return;
      AppDialogs.showSnack(context, AppDialogs.friendlyError(e), error: true);
    }
  }

  Future<void> _deleteTodo(Todo todo) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete Todo',
      message: 'Are you sure you want to delete "${todo.title}"? This cannot be undone.',
      confirmLabel: 'Delete',
      icon: Icons.delete_outline_rounded,
    );
    if (!confirmed || !mounted) return;
    try {
      await TodoService.deleteTodo(todo.id);
      if (!mounted) return;
      AppDialogs.showSnack(context, 'Todo deleted successfully');
      await _load(silent: true);
    } on Exception catch (e) {
      if (!mounted) return;
      AppDialogs.showSnack(context, AppDialogs.friendlyError(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const LoadingWidget(message: 'Loading your todos...');
    }
    if (_error != null) {
      return ErrorWidgetView(message: AppDialogs.friendlyError(_error!), onRetry: _load);
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcome(),
          const SizedBox(height: 16),
          TodoStatsView(stats: _stats, items: _items),
          const SizedBox(height: 20),
          _buildSearchField(),
          const SizedBox(height: 12),
          _buildStatusFilter(),
          if (_stats.categories.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildCategoryFilter(),
          ],
          const SizedBox(height: 20),
          if (_items.isEmpty)
            _buildEmptyState()
          else ...[
            Row(
              children: [
                const Text(
                  'Your Todos',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textDark),
                ),
                const Spacer(),
                Text(
                  '${_items.length} ${_items.length == 1 ? 'todo' : 'todos'}',
                  style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTodoList(),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildWelcome() {
    final user = context.watch<Session>().user;
    final firstName = user != null && user.name.isNotEmpty
        ? user.name.split(' ').first
        : 'there';
    final button = FilledButton.icon(
      onPressed: _showAddDialog,
      style: FilledButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF312E81),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      ),
      icon: const Icon(Icons.add_rounded, size: 20),
      label: const Text('Add Todo', style: TextStyle(fontWeight: FontWeight.w700)),
    );
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome, $firstName',
          style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          _stats.total == 0
              ? 'No todos yet. Add your first task to get started.'
              : '${_stats.completed} of ${_stats.total} completed '
                  '${_stats.overdue > 0 ? '• ${_stats.overdue} overdue' : ''}',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
        ),
      ],
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF17163B), Color(0xFF312E81), ExperimentPalette.todo],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth <= 620) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                text,
                const SizedBox(height: 14),
                button,
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: text),
              const SizedBox(width: 16),
              button,
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: _onSearchChanged,
      decoration: InputDecoration(
        hintText: 'Search todos by title, description or category...',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded),
                onPressed: () {
                  _searchController.clear();
                  _onSearchChanged('');
                },
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE6E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE6E8F0)),
        ),
      ),
    );
  }

  Widget _buildStatusFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final status in _statusOptions) ...[
            _filterChip(
              label: Formatters.enumLabel(status),
              selected: _statusFilter == status,
              onSelected: () => _setStatus(status),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final category in ['All', ..._stats.categories]) ...[
            _filterChip(
              label: category,
              selected: _categoryFilter == category,
              onSelected: () => _setCategory(category),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      showCheckmark: false,
      selectedColor: ExperimentPalette.todo.withValues(alpha: 0.16),
      side: BorderSide(
        color: selected ? ExperimentPalette.todo : const Color(0xFFE6E8F0),
      ),
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: selected ? const Color(0xFF312E81) : Colors.grey.shade700,
      ),
    );
  }

  Widget _buildTodoList() {
    return Column(
      children: [
        for (var i = 0; i < _items.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          TodoCard(
            todo: _items[i],
            onToggle: () => _toggleTodo(_items[i]),
            onEdit: () => _showEditDialog(_items[i]),
            onDelete: () => _deleteTodo(_items[i]),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyState() {
    final filtered = _searchController.text.trim().isNotEmpty ||
        _statusFilter != 'ALL' ||
        _categoryFilter != 'All';
    return EmptyState(
      icon: Icons.checklist_rounded,
      title: filtered ? 'No todos match your filters' : 'No todos yet',
      subtitle: filtered
          ? 'Try clearing the search or filters.'
          : 'Tap "Add Todo" to create your first task.',
      action: OutlinedButton.icon(
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Todo'),
      ),
    );
  }
}
