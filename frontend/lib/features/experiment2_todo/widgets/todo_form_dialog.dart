import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../models/todo.dart';

class TodoFormDialog extends StatefulWidget {
  final Todo? todo;

  const TodoFormDialog({super.key, this.todo});

  @override
  State<TodoFormDialog> createState() => _TodoFormDialogState();
}

class _TodoFormDialogState extends State<TodoFormDialog> {
  static const List<String> _defaultCategories = ['General', 'Work', 'Personal', 'Academics', 'Lab'];
  static const List<String> _priorities = ['LOW', 'MEDIUM', 'HIGH', 'URGENT'];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _customCategoryController;
  late String _category;
  late String _priority;
  DateTime? _dueDate;
  bool _customCategory = false;

  bool get _isEdit => widget.todo != null;

  @override
  void initState() {
    super.initState();
    final todo = widget.todo;
    _titleController = TextEditingController(text: todo?.title ?? '');
    _descriptionController = TextEditingController(text: todo?.description ?? '');
    _customCategory = todo != null && !_defaultCategories.contains(todo.category);
    _category = _customCategory ? 'Custom' : (todo?.category ?? 'General');
    _customCategoryController =
        TextEditingController(text: _customCategory ? todo!.category : '');
    _priority = todo != null && _priorities.contains(todo.priority) ? todo.priority : 'MEDIUM';
    final due = todo?.dueDate;
    _dueDate = (due == null || due.isEmpty) ? null : DateTime.tryParse(due);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final category = _customCategory ? _customCategoryController.text.trim() : _category;
    Navigator.of(context).pop({
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'category': category.isEmpty ? 'General' : category,
      'priority': _priority,
      'dueDate': _dueDate != null ? DateUtilsExt.normalize(_dueDate!) : '',
    });
  }

  @override
  Widget build(BuildContext context) {
    final accent = ExperimentPalette.todo;
    return AlertDialog(
      icon: Icon(_isEdit ? Icons.edit_rounded : Icons.add_task_rounded, color: accent, size: 34),
      title: Text(
        _isEdit ? 'Edit Todo' : 'Add Todo',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _titleController,
                  autofocus: true,
                  maxLength: 200,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Title *',
                    hintText: 'What needs to be done?',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => Validators.required(v, 'Title'),
                ),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  maxLength: 2000,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Optional details about this todo',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final c in _defaultCategories)
                      DropdownMenuItem(value: c, child: Text(c)),
                    const DropdownMenuItem(value: 'Custom', child: Text('Custom...')),
                  ],
                  onChanged: (value) => setState(() {
                    _category = value ?? _category;
                    _customCategory = _category == 'Custom';
                    if (_customCategory) _customCategoryController.clear();
                  }),
                ),
                if (_customCategory) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _customCategoryController,
                    maxLength: 50,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'New category name',
                      hintText: 'e.g. Health, Shopping',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _priority,
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final p in _priorities)
                      DropdownMenuItem(value: p, child: Text(Formatters.enumLabel(p))),
                  ],
                  onChanged: (value) => setState(() => _priority = value ?? _priority),
                ),
                const SizedBox(height: 16),
                Text(
                  'Due Date',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickDueDate,
                        style: OutlinedButton.styleFrom(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(Icons.event_rounded, size: 18),
                        label: Text(
                          _dueDate == null
                              ? 'No due date'
                              : Formatters.date(DateUtilsExt.normalize(_dueDate!)),
                          style: TextStyle(
                            color: _dueDate == null ? Colors.grey.shade600 : AppColors.textDark,
                          ),
                        ),
                      ),
                    ),
                    if (_dueDate != null)
                      IconButton(
                        tooltip: 'Clear due date',
                        onPressed: () => setState(() => _dueDate = null),
                        icon: const Icon(Icons.close_rounded, size: 20),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.check_rounded, size: 18),
          label: Text(_isEdit ? 'Save Changes' : 'Add Todo'),
        ),
      ],
    );
  }
}
