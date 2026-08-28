import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../widgets/app_dialogs.dart';
import '../models/project.dart';

class ProjectFormDialog extends StatefulWidget {
  final Project? project;

  const ProjectFormDialog({super.key, this.project});

  static Future<Map<String, dynamic>?> show(BuildContext context,
      {Project? project}) {
    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProjectFormDialog(project: project),
    );
  }

  @override
  State<ProjectFormDialog> createState() => _ProjectFormDialogState();
}

class _ProjectFormDialogState extends State<ProjectFormDialog> {
  static const List<String> _swatches = [
    '#EC4899',
    '#4F46E5',
    '#0EA5E9',
    '#10B981',
    '#F59E0B',
    '#EF4444',
    '#8B5CF6',
    '#14B8A6',
    '#6366F1',
    '#F97316',
  ];

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late String _selectedColor;
  String? _nameError;
  bool _submitting = false;

  bool get _isEdit => widget.project != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.project?.description ?? '');
    _selectedColor = widget.project?.color ?? '#EC4899';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.length < 2) {
      setState(() => _nameError = 'Name must be at least 2 characters');
      return;
    }
    final result = {
      'name': name,
      'description': _descriptionController.text.trim(),
      'color': _selectedColor,
    };
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(_isEdit ? Icons.edit_rounded : Icons.add_rounded,
              color: ExperimentPalette.project),
          const SizedBox(width: 10),
          Text(_isEdit ? 'Edit Project' : 'New Project',
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
                controller: _nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Name',
                  hintText: 'e.g. Portfolio Website',
                  errorText: FormFieldError.of(_nameError),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) {
                  if (_nameError != null) setState(() => _nameError = null);
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
                  hintText: 'What is this project about?',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              const Text('Color',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final hex in _swatches)
                    GestureDetector(
                      onTap: () => setState(() => _selectedColor = hex),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Project.colorFromHex(hex),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _selectedColor == hex
                                ? const Color(0xFF0F172A)
                                : Colors.transparent,
                            width: 2.5,
                          ),
                          boxShadow: _selectedColor == hex
                              ? [
                                  BoxShadow(
                                      color: Project.colorFromHex(hex)
                                          .withValues(alpha: 0.45),
                                      blurRadius: 8)
                                ]
                              : null,
                        ),
                        child: _selectedColor == hex
                            ? const Icon(Icons.check_rounded,
                                color: Colors.white, size: 20)
                            : null,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting
              ? null
              : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _submitting ? null : _submit,
          icon: const Icon(Icons.check_rounded, size: 18),
          label: Text(_isEdit ? 'Save Changes' : 'Create Project'),
        ),
      ],
    );
  }
}