import '../../../core/network/api_client.dart';
import '../models/project.dart';
import '../models/task.dart';

class ProjectService {
  static const String _projectsPath = '/api/projects';
  static const String _tasksPath = '/api/tasks';

 static Future<List<Project>> fetchProjects() async {
    final data = await ApiClient.instance.get(_projectsPath) as List<dynamic>;
    return data
        .map((e) => Project.fromJson(e as Map<String, dynamic>))
        .toList();
  }

 static Future<Project> createProject({
    required String name,
    String description = '',
    String color = '#4f46e5',
  }) async {
    final data = await ApiClient.instance.post(_projectsPath, body: {
      'name': name,
      'description': description,
      'color': color,
    });
    return Project.fromJson(data as Map<String, dynamic>);
  }

 static Future<Project> updateProject(
    String id, {
    String? name,
    String? description,
    String? color,
  }) async {
    final data = await ApiClient.instance.put('$_projectsPath/$id', body: {
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (color != null) 'color': color,
    });
    return Project.fromJson(data as Map<String, dynamic>);
  }

 static Future<void> deleteProject(String id) =>
      ApiClient.instance.delete('$_projectsPath/$id');

 static Future<List<Task>> fetchTasks({
    String? projectId,
    String? status,
    String? priority,
    String? search,
  }) async {
    final data = await ApiClient.instance.get(_tasksPath, query: {
      if (projectId != null && projectId.isNotEmpty) 'project_id': projectId,
      if (status != null && status.isNotEmpty) 'status': status,
      if (priority != null && priority.isNotEmpty) 'priority': priority,
      if (search != null && search.isNotEmpty) 'search': search,
    }) as List<dynamic>;
    return data.map((e) => Task.fromJson(e as Map<String, dynamic>)).toList();
  }

 static Future<ProjectStats> fetchTaskStats({String? projectId}) async {
    final data = await ApiClient.instance.get(
      '$_tasksPath/stats',
      query: projectId == null || projectId.isEmpty
          ? null
          : {'project_id': projectId},
    );
    return ProjectStats.fromJson(data as Map<String, dynamic>);
  }

 static Future<Task> createTask({
    required String projectId,
    required String title,
    String description = '',
    String priority = 'MEDIUM',
    String status = 'PENDING',
    String? dueDate,
    String? assignedTo,
  }) async {
    final data = await ApiClient.instance.post(_tasksPath, body: {
      'project_id': projectId,
      'title': title,
      'description': description,
      'priority': priority,
      'status': status,
      if (dueDate != null && dueDate.isNotEmpty) 'due_date': dueDate,
      if (assignedTo != null && assignedTo.isNotEmpty) 'assigned_to': assignedTo,
    });
    return Task.fromJson(data as Map<String, dynamic>);
  }

 static Future<Task> updateTask(
    String id, {
    String? title,
    String? description,
    String? priority,
    String? status,
    String? dueDate,
    String? assignedTo,
  }) async {
    final data = await ApiClient.instance.put('$_tasksPath/$id', body: {
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (priority != null) 'priority': priority,
      if (status != null) 'status': status,
      if (dueDate != null) 'due_date': dueDate,
      if (assignedTo != null) 'assigned_to': assignedTo,
    });
    return Task.fromJson(data as Map<String, dynamic>);
  }

 static Future<void> updateTaskStatus(String id, String status) async {
    await ApiClient.instance.put('$_tasksPath/$id', body: {'status': status});
  }

 static Future<void> deleteTask(String id) =>
      ApiClient.instance.delete('$_tasksPath/$id');
}
