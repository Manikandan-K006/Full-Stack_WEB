import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../widgets/animated_card.dart';
import '../../../widgets/status_chip.dart';
import '../models/leave_request.dart';

class LeaveRequestCard extends StatelessWidget {
  final LeaveRequest request;
  final VoidCallback? onCancel;
  final bool showEmployee;

  const LeaveRequestCard({
    super.key,
    required this.request,
    this.onCancel,
    this.showEmployee = false,
  });

  @override
  Widget build(BuildContext context) {
    final remark = request.decisionRemark;
    return AnimatedCard(
      accentColor: ExperimentPalette.leave,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: ExperimentPalette.leave.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(_typeIcon(request.leaveType), color: ExperimentPalette.leave, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Formatters.enumLabel(request.leaveType),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${request.numberOfDays} day${request.numberOfDays == 1 ? '' : 's'} • ${Formatters.date(request.startDate)} to ${Formatters.date(request.endDate)}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusChip(status: request.status),
            ],
          ),
          if (showEmployee) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.person_outline_rounded, size: 15, color: Colors.grey.shade500),
                const SizedBox(width: 5),
                Text(
                  request.employeeName ?? 'Unknown',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Text(
            request.reason,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.4),
          ),
          if (remark != null && remark.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Remark: $remark',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                'Applied ${Formatters.dateTime(request.createdAt)}',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 11.5),
              ),
              const Spacer(),
              if (request.isPending && onCancel != null)
                TextButton.icon(
                  onPressed: onCancel,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  icon: const Icon(Icons.close_rounded, size: 17),
                  label: const Text('Cancel'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'MEDICAL':
        return Icons.medical_services_rounded;
      case 'EARNED':
        return Icons.beach_access_rounded;
      case 'OTHER':
        return Icons.more_horiz_rounded;
      default:
        return Icons.wb_sunny_rounded;
    }
  }
}