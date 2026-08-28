import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../widgets/app_dialogs.dart';
import '../../../widgets/error_widget.dart';
import '../../../widgets/feature_navigator.dart';
import '../../../widgets/loading_widget.dart';
import '../../../widgets/status_chip.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../services/project_service.dart';
import '../widgets/task_card.dart';
import '../widgets/task_form_dialog.dart';

class ProjectDetailScreen extends StatefulWidget {
  final Project project;

  const ProjectDetailScreen({super.key, required this.project});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  static const List<String> _statuses = ['PENDING', 'IN_PROGRESS', 'COMPLETED'];

  List<Task> _tasks = [];
  ProjectStats _stats = const ProjectStats();
  bool _loading = true;
  String? _error;

  Project get _project => widget.project;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final results = await Future.wait([
        ProjectService.fetchTasks(projectId: _project.id),
        ProjectService.fetchTaskStats(projectId: _project.id),
      ]);
      if (!mounted) return;
      setState(() {
        _tasks = results[0] as List<Task>;
        _stats = results[1] as ProjectStats;
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

  List<Task> _tasksFor(String status) =>
      _tasks.where((t) => t.status == status).toList();

  Future<void> _showAddDialog() async {
    final payload =
        await TaskFormDialog.show(context, projectId: _project.id);
    if (payload == null || !mounted) return;
    try {
      await ProjectService.createTask(
        projectId: _project.id,
        title: payload['title'] as String,
        description: payload['description'] as String? ?? '',
        priority: payload['priority'] as String? ?? 'MEDIUM',
        status: payload['status'] as String? ?? 'PENDING',
        dueDate: payload['due_date'] as String?,
        assignedTo: payload['assigned_to'] as String?,
      );
      if (!mounted) return;
      AppDialogs.showSnack(context, 'Task created successfully');
      await _load(silent: true);
    } on Exception catch (e) {
      if (!mounted) return;
      AppDialogs.showSnack(context, AppDialogs.friendlyError(e), error: true);
    }
  }

  Future<void> _showEditDialog(Task task) async {
    final payload = await TaskFormDialog.show(context,
        projectId: _project.id, task: task);
    if (payload == null || !mounted) return;
    try {
      await ProjectService.updateTask(
        task.id,
        title: payload['title'] as String,
        description: payload['description'] as String? ?? '',
        priority: payload['priority'] as String? ?? task.priority,
        status: payload['status'] as String? ?? task.status,
        dueDate: payload['due_date'] as String?,
        assignedTo: payload['assigned_to'] as String?,
      );
      if (!mounted) return;
      AppDialogs.showSnack(context, 'Task updated successfully');
      await _load(silent: true);
    } on Exception catch (e) {
      if (!mounted) return;
      AppDialogs.showSnack(context, AppDialogs.friendlyError(e), error: true);
    }
  }

  Future<void> _moveTask(Task task, String newStatus) async {
    try {
      await ProjectService.updateTaskStatus(task.id, newStatus);
      if (!mounted) return;
      AppDialogs.showSnack(
          context, 'Task moved to ${Formatters.enumLabel(newStatus)}');
      await _load(silent: true);
    } on Exception catch (e) {
      if (!mounted) return;
      AppDialogs.showSnack(context, AppDialogs.friendlyError(e), error: true);
    }
  }

  Future<void> _deleteTask(Task task) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete Task',
      message:
          'Are you sure you want to delete "${task.title}"? This cannot be undone.',
      confirmLabel: 'Delete',
      icon: Icons.delete_outline_rounded,
    );
    if (!confirmed || !mounted) return;
    try {
      await ProjectService.deleteTask(task.id);
      if (!mounted) return;
      AppDialogs.showSnack(context, 'Task deleted successfully');
      await _load(silent: true);
    } on Exception catch (e) {
      if (!mounted) return;
      AppDialogs.showSnack(context, AppDialogs.friendlyError(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBackHeader(),
          const SizedBox(height: 16),
          _buildProjectHeader(),
          const SizedBox(height: 20),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: LoadingWidget(message: 'Loading tasks...'),
            )
          else if (_error != null)
            ErrorWidgetView(
                message: AppDialogs.friendlyError(_error), onRetry: _load)
          else
            _buildBoard(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildBackHeader() {
    return Row(
      children: [
        IconButton(
          tooltip: 'Back',
          onPressed: () => FeatureNavigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFFE6E8F0)),
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'Project Board',
            style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark),
          ),
        ),
        FilledButton.icon(
          onPressed: _showAddDialog,
          style: FilledButton.styleFrom(
            backgroundColor: ExperimentPalette.project,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          ),
          icon: const Icon(Icons.add_task_rounded, size: 18),
          label: const Text('Add Task',
              style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _buildProjectHeader() {
    final color = _project.colorValue;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.dashboard_customize_rounded,
                    color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _project.name,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Created ${Formatters.date(_project.createdAt)}',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _headerStat('Total', _stats.total,
                  Icons.task_alt_rounded, ExperimentPalette.project),
              _headerStat('Pending', _stats.pending,
                  Icons.pending_actions_rounded, const Color(0xFFF59E0B)),
              _headerStat('Active', _stats.inProgress,
                  Icons.play_circle_outline_rounded, const Color(0xFF0EA5E9)),
              _headerStat('Done', _stats.completed,
                  Icons.check_circle_outline_rounded, const Color(0xFF10B981)),
            ],
          ),
          if (_project.description.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              _project.description,
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  height: 1.45),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: LinearProgressIndicator(
                    value: (_stats.progress / 100).clamp(0.0, 1.0),
                    minHeight: 9,
                    backgroundColor: color.withValues(alpha: 0.14),
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                Formatters.percent(_stats.progress),
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerStat(String label, int value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text('$value',
              style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark)),
          const SizedBox(width: 3),
          Text(label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildBoard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final columns = [
          for (final status in _statuses)
            _KanbanColumn(
              status: status,
              tasks: _tasksFor(status),
              accentColor: _project.colorValue,
              onMoveLeft: (task) => _moveTask(task, _previous(status)),
              onMoveRight: (task) => _moveTask(task, _next(status)),
              onEdit: _showEditDialog,
              onDelete: _deleteTask,
            ),
        ];
        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < columns.length; i++) ...[
                if (i > 0) const SizedBox(width: 14),
                Expanded(child: columns[i]),
              ],
            ],
          );
        }
        return Column(
          children: [
            for (var i = 0; i < columns.length; i++) ...[
              if (i > 0) const SizedBox(height: 14),
              columns[i],
            ],
          ],
        );
      },
    );
  }

  String _previous(String status) {
    final index = _statuses.indexOf(status);
    return index > 0 ? _statuses[index - 1] : status;
  }

  String _next(String status) {
    final index = _statuses.indexOf(status);
    return index < _statuses.length - 1 ? _statuses[index + 1] : status;
  }
}

class _KanbanColumn extends StatelessWidget {
  final String status;
  final List<Task> tasks;
  final Color accentColor;
  final void Function(Task) onMoveLeft;
  final void Function(Task) onMoveRight;
  final void Function(Task) onEdit;
  final void Function(Task) onDelete;

  const _KanbanColumn({
    required this.status,
    required this.tasks,
    required this.accentColor,
    required this.onMoveLeft,
    required this.onMoveRight,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final canMoveLeft = status != 'PENDING';
    final canMoveRight = status != 'COMPLETED';
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6E8F0)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: StatusChip.colorFor(status),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  Formatters.enumLabel(status),
                  style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: StatusChip.colorFor(status)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${tasks.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: StatusChip.colorFor(status),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Divider(color: Colors.grey.shade300, height: 16),
          if (tasks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 26),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.inbox_outlined,
                        size: 28, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    Text(
                      'No ${Formatters.enumLabel(status).toLowerCase()} tasks',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: [
                for (var i = 0; i < tasks.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  TaskCard(
                    task: tasks[i],
                    accentColor: accentColor,
                    onMoveLeft: canMoveLeft ? () => onMoveLeft(tasks[i]) : null,
                    onMoveRight:
                        canMoveRight ? () => onMoveRight(tasks[i]) : null,
                    onEdit: () => onEdit(tasks[i]),
                    onDelete: () => onDelete(tasks[i]),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}