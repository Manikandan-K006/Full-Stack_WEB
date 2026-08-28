import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/formatters.dart';
import '../../../widgets/app_dialogs.dart';
import '../models/task.dart';

class TaskFormDialog extends StatefulWidget {
  final String projectId;
  final Task? task;

  const TaskFormDialog({super.key, required this.projectId, this.task});

  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    required String projectId,
    Task? task,
  }) {
    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => TaskFormDialog(projectId: projectId, task: task),
    );
  }

  @override
  State<TaskFormDialog> createState() => _TaskFormDialogState();
}

class _TaskFormDialogState extends State<TaskFormDialog> {
  static const List<String> _priorities = ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'];
  static const List<String> _statuses = ['PENDING', 'IN_PROGRESS', 'COMPLETED'];

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _assignedController;
  late String _priority;
  late String _status;
  String? _dueDate;
  String? _titleError;
  bool _submitting = false;

  bool get _isEdit => widget.task != null;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _titleController = TextEditingController(text: task?.title ?? '');
    _descriptionController =
        TextEditingController(text: task?.description ?? '');
    _assignedController = TextEditingController(text: task?.assignedTo ?? '');
    _priority = task?.priority ?? 'MEDIUM';
    _status = task?.status ?? 'PENDING';
    _dueDate = task?.dueDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _assignedController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final initial = DateTime.tryParse(_dueDate ?? '') ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: _isEdit ? 'Select due date' : 'Select due date (optional)',
    );
    if (picked == null) return;
    setState(() => _dueDate = DateUtilsExt.normalize(picked));
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.length < 2) {
      setState(() => _titleError = 'Title must be at least 2 characters');
      return;
    }
    final result = {
      'title': title,
      'description': _descriptionController.text.trim(),
      'priority': _priority,
      'status': _status,
      if (_dueDate != null && _dueDate!.isNotEmpty) 'due_date': _dueDate,
      if (_assignedController.text.trim().isNotEmpty)
        'assigned_to': _assignedController.text.trim(),
    };
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final overdue = _dueDate != null && _dueDate!.isNotEmpty
        ? DateUtilsExt.isOverdue(_dueDate)
        : false;
    return AlertDialog(
      title: Row(
        children: [
          Icon(_isEdit ? Icons.edit_rounded : Icons.add_task_rounded,
              color: ExperimentPalette.project),
          const SizedBox(width: 10),
          Text(_isEdit ? 'Edit Task' : 'New Task',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        ],
      ),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _titleController,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Title',
                  hintText: 'e.g. Write REST API tests',
                  errorText: FormFieldError.of(_titleError),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) {
                  if (_titleError != null) setState(() => _titleError = null);
                },
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                maxLength: 2000,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _priority,
                      decoration: const InputDecoration(
                        labelText: 'Priority',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        for (final p in _priorities)
                          DropdownMenuItem(value: p, child: Text(p)),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _priority = v);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _status,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        for (final s in _statuses)
                          DropdownMenuItem(value: s, child: Text(s)),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _status = v);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDueDate,
                      icon: const Icon(Icons.event_rounded, size: 18),
                      label: Text(
                        _dueDate == null || _dueDate!.isEmpty
                            ? 'No due date'
                            : Formatters.date(_dueDate),
                      ),
                    ),
                  ),
                  if (_dueDate != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Clear due date',
                      onPressed: () => setState(() => _dueDate = null),
                      icon: const Icon(Icons.clear_rounded),
                    ),
                  ],
                ],
              ),
              if (overdue) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        size: 16, color: AppColors.danger),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'This due date is in the past and will be shown as overdue.',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.danger),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 14),
              TextField(
                controller: _assignedController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Assigned to',
                  hintText: 'e.g. Aarav Sharma',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _submitting ? null : _submit,
          icon: const Icon(Icons.check_rounded, size: 18),
          label: Text(_isEdit ? 'Save Changes' : 'Create Task'),
        ),
      ],
    );
  }
}