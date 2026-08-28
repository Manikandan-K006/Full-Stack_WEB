class Todo {
  final String id;
  final String title;
  final String description;
  final String category;
  final String priority;
  final String? dueDate;
  final bool completed;
  final String? createdAt;
  final String? updatedAt;

  const Todo({
    required this.id,
    required this.title,
    this.description = '',
    this.category = 'General',
    this.priority = 'MEDIUM',
    this.dueDate,
    this.completed = false,
    this.createdAt,
    this.updatedAt,
  });

  factory Todo.fromJson(Map<String, dynamic> json) => Todo(
        id: (json['id'] ?? '').toString(),
        title: (json['title'] ?? '').toString(),
        description: (json['description'] ?? '').toString(),
        category: (json['category'] ?? 'General').toString(),
        priority: (json['priority'] ?? 'MEDIUM').toString().toUpperCase(),
        dueDate: json['due_date']?.toString(),
        completed: json['completed'] == true,
        createdAt: json['created_at']?.toString(),
        updatedAt: json['updated_at']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'category': category,
        'priority': priority,
        if (dueDate != null) 'due_date': dueDate,
        'completed': completed,
        if (createdAt != null) 'created_at': createdAt,
        if (updatedAt != null) 'updated_at': updatedAt,
      };

  Todo copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? priority,
    String? Function()? dueDate,
    bool? completed,
    String? createdAt,
    String? updatedAt,
  }) =>
      Todo(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        category: category ?? this.category,
        priority: priority ?? this.priority,
        dueDate: dueDate != null ? dueDate() : this.dueDate,
        completed: completed ?? this.completed,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

class TodoStats {
  final int total;
  final int completed;
  final int pending;
  final List<String> categories;
  final int overdue;
  final double completionRate;

  const TodoStats({
    this.total = 0,
    this.completed = 0,
    this.pending = 0,
    this.categories = const [],
    this.overdue = 0,
    this.completionRate = 0,
  });

  factory TodoStats.fromJson(Map<String, dynamic> json) => TodoStats(
        total: (json['total'] as num?)?.toInt() ?? 0,
        completed: (json['completed'] as num?)?.toInt() ?? 0,
        pending: (json['pending'] as num?)?.toInt() ?? 0,
        categories: ((json['categories'] as List?) ?? const [])
            .map((c) => c.toString())
            .toList(),
        overdue: (json['overdue'] as num?)?.toInt() ?? 0,
        completionRate: (json['completion_rate'] as num?)?.toDouble() ?? 0,
      );
}
