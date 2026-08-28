import '../../../core/network/api_client.dart';
import '../models/todo.dart';

class TodoService {
  static const String _todosPath = '/api/todos';

  static Future<({List<Todo> items, TodoStats stats})> fetchTodos({
    String? search,
    String? status,
    String? category,
  }) async {
    final data = await ApiClient.instance.get(_todosPath, query: {
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (status != null && status != 'ALL') 'status': status,
      if (category != null && category.isNotEmpty) 'category': category,
    }) as Map<String, dynamic>;
    final items = ((data['items'] as List?) ?? const [])
        .map((e) => Todo.fromJson(e as Map<String, dynamic>))
        .toList();
    final stats =
        TodoStats.fromJson((data['stats'] as Map<String, dynamic>?) ?? const {});
    return (items: items, stats: stats);
  }

  static Future<TodoStats> fetchTodoStats() async {
    final data = await ApiClient.instance
        .get('$_todosPath/stats') as Map<String, dynamic>;
    return TodoStats.fromJson(data);
  }

  static Future<Todo> createTodo({
    required String title,
    String description = '',
    String category = 'General',
    String priority = 'MEDIUM',
    String? dueDate,
  }) async {
    final data = await ApiClient.instance.post(_todosPath, body: {
      'title': title,
      'description': description,
      'category': category,
      'priority': priority,
      if (dueDate != null && dueDate.isNotEmpty) 'due_date': dueDate,
    }) as Map<String, dynamic>;
    return Todo.fromJson(data);
  }

  static Future<Todo> updateTodo(
    String id, {
    String? title,
    String? description,
    String? category,
    String? priority,
    String? dueDate,
    bool? completed,
  }) async {
    final data = await ApiClient.instance.put('$_todosPath/$id', body: {
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (category != null) 'category': category,
      if (priority != null) 'priority': priority,
      if (dueDate != null) 'due_date': dueDate,
      if (completed != null) 'completed': completed,
    }) as Map<String, dynamic>;
    return Todo.fromJson(data);
  }

  static Future<Todo> toggleTodo(String id, bool completed) async {
    final data = await ApiClient.instance.put('$_todosPath/$id', body: {
      'completed': completed,
    }) as Map<String, dynamic>;
    return Todo.fromJson(data);
  }

  static Future<void> deleteTodo(String id) async {
    await ApiClient.instance.delete('$_todosPath/$id');
  }
}
