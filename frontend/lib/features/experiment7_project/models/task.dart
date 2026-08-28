class Task {
  final String id;
  final String projectId;
  final String title;
  final String description;
  final String priority;
  final String status;
  final String? dueDate;
  final String? assignedTo;
  final String? createdAt;
  final String? updatedAt;

  const Task({
    required this.id,
    required this.projectId,
    required this.title,
    this.description = '',
    this.priority = 'MEDIUM',
    this.status = 'PENDING',
    this.dueDate,
    this.assignedTo,
    this.createdAt,
    this.updatedAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: (json['id'] ?? '').toString(),
        projectId: (json['project_id'] ?? '').toString(),
        title: (json['title'] ?? '').toString(),
        description: (json['description'] ?? '').toString(),
        priority: (json['priority'] ?? 'MEDIUM').toString().toUpperCase(),
        status: (json['status'] ?? 'PENDING').toString().toUpperCase(),
        dueDate: json['due_date']?.toString().isNotEmpty == true ? json['due_date'].toString() : null,
        assignedTo: json['assigned_to']?.toString().isNotEmpty == true
            ? json['assigned_to'].toString()
            : null,
        createdAt: json['created_at']?.toString(),
        updatedAt: json['updated_at']?.toString(),
      );

  Task copyWith({
    String? status,
    String? title,
    String? description,
    String? priority,
    String? dueDate,
    String? assignedTo,
  }) =>
      Task(
        id: id,
        projectId: projectId,
        title: title ?? this.title,
        description: description ?? this.description,
        priority: priority ?? this.priority,
        status: status ?? this.status,
        dueDate: dueDate ?? this.dueDate,
        assignedTo: assignedTo ?? this.assignedTo,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
