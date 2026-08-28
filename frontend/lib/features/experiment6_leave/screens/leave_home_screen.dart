import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../services/session.dart';
import '../../../widgets/app_dialogs.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_widget.dart';
import '../../../widgets/feature_navigator.dart';
import '../../../widgets/loading_widget.dart';
import '../../../widgets/stat_card.dart';
import '../models/leave_balance.dart';
import '../models/leave_request.dart';
import '../services/leave_service.dart';
import '../widgets/apply_leave_dialog.dart';
import '../widgets/leave_request_card.dart';
import 'admin_leave_view.dart';

class LeaveHomeScreen extends StatefulWidget {
  const LeaveHomeScreen({super.key});

  @override
  State<LeaveHomeScreen> createState() => _LeaveHomeScreenState();
}

class _LeaveHomeScreenState extends State<LeaveHomeScreen> {
  @override
  Widget build(BuildContext context) {
    return FeatureNavigator(
      home: const _LeaveHomeContent(),
      backColor: ExperimentPalette.leave,
      backLabel: 'Leave',
    );
  }
}

class _LeaveHomeContent extends StatefulWidget {
  const _LeaveHomeContent();

  @override
  State<_LeaveHomeContent> createState() => _LeaveHomeContentState();
}

class _LeaveHomeContentState extends State<_LeaveHomeContent> {
  static const _filters = ['All', 'PENDING', 'APPROVED', 'REJECTED', 'CANCELLED'];

  LeaveBalance? _balance;
  List<LeaveRequest> _requests = [];
  bool _loading = true;
  Object? _error;
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final balance = await LeaveService.getBalance();
      final requests = await LeaveService.myRequests();
      if (!mounted) return;
      setState(() {
        _balance = balance;
        _requests = requests;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e;
      });
    }
  }

  Future<void> _openApply() async {
    final applied = await showDialog<bool>(
      context: context,
      builder: (_) => ApplyLeaveDialog(balance: _balance),
    );
    if (applied == true && mounted) {
      AppDialogs.showSnack(context, 'Leave request submitted successfully');
      _load();
    }
  }

  Future<void> _cancel(LeaveRequest request) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Cancel leave request?',
      message: '${Formatters.enumLabel(request.leaveType)} leave for '
          '${request.numberOfDays} day${request.numberOfDays == 1 ? '' : 's'} '
          'will be cancelled and the days restored to your balance.',
      confirmLabel: 'Cancel request',
    );
    if (!confirmed || !mounted) return;
    try {
      await LeaveService.cancel(request.id);
      if (!mounted) return;
      AppDialogs.showSnack(context, 'Leave request cancelled');
      _load();
    } catch (e) {
      if (!mounted) return;
      AppDialogs.showSnack(context, AppDialogs.friendlyError(e), error: true);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingWidget(message: 'Loading leave data...');
    if (_error != null) {
      return ErrorWidgetView(message: AppDialogs.friendlyError(_error), onRetry: _load);
    }
    final balance = _balance;
    if (balance == null) return const LoadingWidget(message: 'Loading leave data...');
    return _buildContent(context, balance);
  }

  Widget _buildContent(BuildContext context, LeaveBalance balance) {
    final isAdmin = context.watch<Session>().user?.isAdmin ?? false;
    final filtered = _filter == 'All'
        ? _requests
        : _requests.where((r) => r.status == _filter).toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Leave Balance',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: AppColors.textDark),
              ),
              const Spacer(),
              if (isAdmin)
                OutlinedButton.icon(
                  onPressed: () => FeatureNavigator.of(context).push(const AdminLeaveView()),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ExperimentPalette.leave,
                    side: BorderSide(color: ExperimentPalette.leave.withValues(alpha: 0.6)),
                  ),
                  icon: const Icon(Icons.shield_outlined, size: 17),
                  label: const Text('Admin'),
                ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final w = (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: w,
                    child: StatCard(
                      label: 'Casual Leave',
                      value: balance.casualLeave,
                      icon: Icons.wb_sunny_rounded,
                      color: ExperimentPalette.leave,
                    ),
                  ),
                  SizedBox(
                    width: w,
                    child: StatCard(
                      label: 'Medical Leave',
                      value: balance.medicalLeave,
                      icon: Icons.medical_services_rounded,
                      color: ExperimentPalette.leave,
                    ),
                  ),
                  SizedBox(
                    width: w,
                    child: StatCard(
                      label: 'Earned Leave',
                      value: balance.earnedLeave,
                      icon: Icons.beach_access_rounded,
                      color: ExperimentPalette.leave,
                    ),
                  ),
                  SizedBox(
                    width: w,
                    child: StatCard(
                      label: 'Other Leave',
                      value: balance.otherLeave,
                      icon: Icons.more_horiz_rounded,
                      color: ExperimentPalette.leave,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _openApply,
              style: FilledButton.styleFrom(
                backgroundColor: ExperimentPalette.leave,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              icon: const Icon(Icons.add_circle_outline_rounded),
              label: const Text('Apply Leave'),
            ),
          ),
          const SizedBox(height: 26),
          const Text(
            'My Requests',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: AppColors.textDark),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final f in _filters)
                ChoiceChip(
                  label: Text(Formatters.enumLabel(f)),
                  selected: _filter == f,
                  selectedColor: ExperimentPalette.leave.withValues(alpha: 0.15),
                  labelStyle: TextStyle(
                    color: _filter == f ? ExperimentPalette.leave : Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (_) => setState(() => _filter = f),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (filtered.isEmpty)
            const EmptyState(
              icon: Icons.event_busy_rounded,
              title: 'No leave requests',
              subtitle: 'Apply for leave to see it here.',
            )
          else
            for (final r in filtered)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: LeaveRequestCard(
                  request: r,
                  onCancel: r.isPending ? () => _cancel(r) : null,
                ),
              ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}