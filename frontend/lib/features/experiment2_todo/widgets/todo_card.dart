import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/formatters.dart';
import '../../../widgets/animated_card.dart';
import '../../../widgets/status_chip.dart';
import '../models/todo.dart';

class TodoCard extends StatelessWidget {
  final Todo todo;
  final VoidCallback? onToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TodoCard({
    super.key,
    required this.todo,
    this.onToggle,
    this.onEdit,
    this.onDelete,
  });

  static const List<Color> _palette = [
    Color(0xFF4F46E5),
    Color(0xFF0EA5E9),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFF14B8A6),
  ];

  Color get _categoryColor {
    final hash = todo.category.codeUnits.fold<int>(0, (sum, c) => sum + c);
    return _palette[hash % _palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final overdue = !todo.completed && DateUtilsExt.isOverdue(todo.dueDate);
    return AnimatedCard(
      accentColor: ExperimentPalette.todo,
      padding: const EdgeInsets.fromLTRB(8, 10, 4, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Checkbox(
              value: todo.completed,
              onChanged: (_) => onToggle?.call(),
              activeColor: ExperimentPalette.todo,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  todo.title,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    color: todo.completed ? Colors.grey.shade500 : AppColors.textDark,
                    decoration: todo.completed ? TextDecoration.lineThrough : null,
                    decorationColor: Colors.grey.shade500,
                  ),
                ),
                if (todo.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    todo.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.4),
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    StatusChip(status: todo.category, color: _categoryColor),
                    StatusChip(status: todo.priority),
                    if (todo.dueDate != null && todo.dueDate!.isNotEmpty)
                      _DueDateChip(dueDate: todo.dueDate!, overdue: overdue),
                  ],
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Edit',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 20),
                color: Colors.grey.shade600,
              ),
              IconButton(
                tooltip: 'Delete',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                color: AppColors.danger,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DueDateChip extends StatelessWidget {
  final String dueDate;
  final bool overdue;

  const _DueDateChip({required this.dueDate, required this.overdue});

  @override
  Widget build(BuildContext context) {
    final color = overdue ? AppColors.danger : Colors.grey.shade600;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: overdue ? AppColors.danger.withValues(alpha: 0.1) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_rounded, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            Formatters.date(dueDate),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
          ),
          if (overdue) ...[
            const SizedBox(width: 5),
            Text('Overdue', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
          ],
        ],
      ),
    );
  }
}
