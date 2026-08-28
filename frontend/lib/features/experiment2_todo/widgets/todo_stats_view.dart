import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../widgets/stat_card.dart';
import '../models/todo.dart';

class TodoStatsView extends StatelessWidget {
  final TodoStats stats;
  final List<Todo> items;

  const TodoStatsView({super.key, required this.stats, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final columns = width > 1100 ? 4 : (width > 620 ? 2 : 1);
            final cardWidth = (width - (columns - 1) * 12) / columns;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: cardWidth,
                  child: StatCard(
                    label: 'Total',
                    value: stats.total.toDouble(),
                    icon: Icons.checklist_rounded,
                    color: ExperimentPalette.todo,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: StatCard(
                    label: 'Pending',
                    value: stats.pending.toDouble(),
                    icon: Icons.pending_actions_rounded,
                    color: AppColors.warning,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: StatCard(
                    label: 'Completed',
                    value: stats.completed.toDouble(),
                    icon: Icons.task_alt_rounded,
                    color: AppColors.accent,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: StatCard(
                    label: 'Completion Rate',
                    value: stats.completionRate,
                    suffix: '%',
                    icon: Icons.percent_rounded,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        _CategoryBreakdown(stats: stats, items: items),
      ],
    );
  }
}

class _CategoryBreakdown extends StatelessWidget {
  final TodoStats stats;
  final List<Todo> items;

  const _CategoryBreakdown({required this.stats, required this.items});

  @override
  Widget build(BuildContext context) {
    if (stats.categories.isEmpty) return const SizedBox.shrink();
    final counts = <String, int>{};
    for (final todo in items) {
      counts[todo.category] = (counts[todo.category] ?? 0) + 1;
    }
    final maxCount = counts.values.fold<int>(0, (a, b) => a > b ? a : b);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Category Breakdown',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark),
              ),
              const Spacer(),
              if (stats.overdue > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${stats.overdue} overdue',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.danger,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          for (final category in stats.categories) ...[
            _CategoryBar(
              name: category,
              count: counts[category] ?? 0,
              fraction: maxCount == 0 ? 0 : (counts[category] ?? 0) / maxCount,
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  final String name;
  final int count;
  final double fraction;

  const _CategoryBar({required this.name, required this.count, required this.fraction});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
            Text(
              '$count todo${count == 1 ? '' : 's'}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 7,
            color: ExperimentPalette.todo,
            backgroundColor: const Color(0xFFEDEFF7),
          ),
        ),
      ],
    );
  }
}