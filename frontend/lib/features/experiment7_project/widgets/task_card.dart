import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/formatters.dart';
import '../../../widgets/status_chip.dart';
import '../models/task.dart';

class TaskCard extends StatefulWidget {
  final Task task;
  final Color accentColor;
  final VoidCallback? onMoveLeft;
  final VoidCallback? onMoveRight;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TaskCard({
    super.key,
    required this.task,
    required this.accentColor,
    this.onMoveLeft,
    this.onMoveRight,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final overdue = task.dueDate != null && task.dueDate!.isNotEmpty
        ? DateUtilsExt.isOverdue(task.dueDate)
        : false;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: overdue
              ? AppColors.danger.withValues(alpha: 0.35)
              : const Color(0xFFE6E8F0),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 38,
                decoration: BoxDecoration(
                  color: widget.accentColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  task.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                    height: 1.3,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Task actions',
                iconSize: 19,
                onSelected: (value) {
                  if (value == 'edit') widget.onEdit?.call();
                  if (value == 'delete') widget.onDelete?.call();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded,
                            size: 18, color: AppColors.danger),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: AppColors.danger)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (task.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              task.description,
              maxLines: _expanded ? null : 2,
              overflow: _expanded ? null : TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                height: 1.45,
              ),
            ),
            if (task.description.length > 90)
              InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    _expanded ? 'Show less' : 'Show more',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: widget.accentColor,
                    ),
                  ),
                ),
              ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              StatusChip(status: task.priority),
              const Spacer(),
              if (task.assignedTo != null && task.assignedTo!.isNotEmpty) ...[
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person_outline_rounded,
                          size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          task.assignedTo!,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 11.5, color: AppColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          if (task.dueDate != null && task.dueDate!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  overdue
                      ? Icons.error_outline_rounded
                      : Icons.event_rounded,
                  size: 14,
                  color: overdue ? AppColors.danger : Colors.grey.shade500,
                ),
                const SizedBox(width: 5),
                Text(
                  'Due ${Formatters.date(task.dueDate)}',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: overdue ? AppColors.danger : Colors.grey.shade600,
                  ),
                ),
                if (overdue) ...[
                  const SizedBox(width: 6),
                  Text(
                    'Overdue',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.danger,
                    ),
                  ),
                ],
              ],
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                tooltip: 'Move to previous status',
                onPressed: widget.onMoveLeft,
                iconSize: 18,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              IconButton(
                tooltip: 'Move to next status',
                onPressed: widget.onMoveRight,
                iconSize: 18,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
              const Spacer(),
              Text(
                Formatters.enumLabel(task.status),
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: StatusChip.colorFor(task.status),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}