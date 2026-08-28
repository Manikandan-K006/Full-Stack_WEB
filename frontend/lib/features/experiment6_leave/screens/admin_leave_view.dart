import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../services/session.dart';
import '../../../widgets/animated_card.dart';
import '../../../widgets/app_dialogs.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_widget.dart';
import '../../../widgets/feature_navigator.dart';
import '../../../widgets/loading_widget.dart';
import '../../../widgets/stat_card.dart';
import '../../../widgets/status_chip.dart';
import '../models/employee_balance.dart';
import '../models/leave_balance.dart';
import '../models/leave_request.dart';
import '../models/leave_stats.dart';
import '../services/leave_service.dart';
import '../widgets/leave_request_card.dart';

class AdminLeaveView extends StatefulWidget {
  const AdminLeaveView({super.key});

  @override
  State<AdminLeaveView> createState() => _AdminLeaveViewState();
}

class _AdminLeaveViewState extends State<AdminLeaveView> {
  static const _statuses = ['All', 'PENDING', 'APPROVED', 'REJECTED', 'CANCELLED'];

  final _searchController = TextEditingController();
  Timer? _debounce;

  String _tab = 'Pending';
  String _statusFilter = 'All';

  bool _loading = true;
  Object? _error;

  LeaveStats? _stats;
  List<LeaveRequest> _pending = [];
  List<LeaveRequest> _requests = [];
  List<EmployeeBalance> _employees = [];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final stats = await LeaveService.getStats();
      final pending = await LeaveService.allRequests(status: 'PENDING');
      final requests = await LeaveService.allRequests(
        status: _statusFilter == 'All' ? null : _statusFilter,
        employee: _searchController.text,
      );
      final employees = await LeaveService.listUsers();
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _pending = pending;
        _requests = requests;
        _employees = employees;
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

  Future<void> _reloadPending() async {
    try {
      final pending = await LeaveService.allRequests(status: 'PENDING');
      final stats = await LeaveService.getStats();
      if (!mounted) return;
      setState(() {
        _pending = pending;
        _stats = stats;
      });
    } catch (e) {
      if (!mounted) return;
      AppDialogs.showSnack(context, AppDialogs.friendlyError(e), error: true);
    }
  }

  Future<void> _reloadRequests() async {
    try {
      final requests = await LeaveService.allRequests(
        status: _statusFilter == 'All' ? null : _statusFilter,
        employee: _searchController.text,
      );
      final stats = await LeaveService.getStats();
      if (!mounted) return;
      setState(() {
        _requests = requests;
        _stats = stats;
      });
    } catch (e) {
      if (!mounted) return;
      AppDialogs.showSnack(context, AppDialogs.friendlyError(e), error: true);
    }
  }

  Future<void> _reloadEmployees() async {
    try {
      final employees = await LeaveService.listUsers();
      if (!mounted) return;
      setState(() => _employees = employees);
    } catch (e) {
      if (!mounted) return;
      AppDialogs.showSnack(context, AppDialogs.friendlyError(e), error: true);
    }
  }

  Future<void> _onTabChanged(String tab) async {
    setState(() => _tab = tab);
    if (tab == 'Pending') await _reloadPending();
    if (tab == 'Requests') await _reloadRequests();
    if (tab == 'Balances') await _reloadEmployees();
  }

  Future<void> _decide(LeaveRequest request, {required bool approve}) async {
    final remark = await _decisionRemarkDialog(
      title: approve ? 'Approve Leave Request' : 'Reject Leave Request',
      actionLabel: approve ? 'Approve' : 'Reject',
    );
    if (remark == null || !mounted) return;
    try {
      if (approve) {
        await LeaveService.approve(request.id, remark: remark);
      } else {
        await LeaveService.reject(request.id, remark: remark);
      }
      if (!mounted) return;
      AppDialogs.showSnack(
        context,
        approve ? 'Leave request approved' : 'Leave request rejected',
      );
      _reloadPending();
      _reloadRequests();
    } catch (e) {
      if (!mounted) return;
      AppDialogs.showSnack(context, AppDialogs.friendlyError(e), error: true);
    }
  }

  Future<String?> _decisionRemarkDialog({
    required String title,
    required String actionLabel,
  }) async {
    final controller = TextEditingController();
    final remark = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          maxLines: 2,
          maxLength: 300,
          decoration: const InputDecoration(
            labelText: 'Remark (optional)',
            hintText: 'Add a note to the employee',
            alignLabelWithHint: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
    controller.dispose();
    return remark;
  }

  Future<void> _adjustBalance(EmployeeBalance employee) async {
    final result = await _AdjustBalanceDialog.show(context, employee);
    if (result == null || !mounted) return;
    setState(() {
      _employees = [
        for (final e in _employees)
          if (e.id == employee.id) e.copyWith(balance: result) else e,
      ];
    });
    AppDialogs.showSnack(context, 'Leave balance updated for ${employee.name}');
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<Session>().user?.isAdmin ?? false;
    return Container(
      color: AppColors.surface,
      child: Column(
        children: [
          _BackHeader(onBack: () => FeatureNavigator.of(context).pop()),
          Expanded(
            child: isAdmin
                ? _buildBody()
                : const EmptyState(
                    icon: Icons.lock_outline_rounded,
                    title: 'Admin access required',
                    subtitle: 'Only administrators can view this page.',
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const LoadingWidget(message: 'Loading admin data...');
    if (_error != null) {
      return ErrorWidgetView(message: AppDialogs.friendlyError(_error), onRetry: _loadAll);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStats(),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 4),
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'Pending',
                label: Text('Pending'),
                icon: Icon(Icons.pending_actions_rounded, size: 18),
              ),
              ButtonSegment(
                value: 'Requests',
                label: Text('All Requests'),
                icon: Icon(Icons.list_alt_rounded, size: 18),
              ),
              ButtonSegment(
                value: 'Balances',
                label: Text('Employee Balances'),
                icon: Icon(Icons.account_balance_wallet_rounded, size: 18),
              ),
            ],
            selected: {_tab},
            onSelectionChanged: (s) => _onTabChanged(s.first),
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: ExperimentPalette.leave.withValues(alpha: 0.15),
              selectedForegroundColor: ExperimentPalette.leave,
              backgroundColor: Colors.white,
              foregroundColor: Colors.grey.shade700,
            ),
          ),
        ),
        Expanded(child: _buildTab()),
      ],
    );
  }

  Widget _buildStats() {
    final stats = _stats;
    if (stats == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = (constraints.maxWidth - 12) / 2;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: w,
                child: StatCard(
                  label: 'Total Requests',
                  value: stats.total.toDouble(),
                  icon: Icons.event_note_rounded,
                  color: ExperimentPalette.leave,
                ),
              ),
              SizedBox(
                width: w,
                child: StatCard(
                  label: 'Pending',
                  value: stats.pending.toDouble(),
                  icon: Icons.pending_actions_rounded,
                  color: const Color(0xFFF59E0B),
                ),
              ),
              SizedBox(
                width: w,
                child: StatCard(
                  label: 'Approved',
                  value: stats.approved.toDouble(),
                  icon: Icons.check_circle_rounded,
                  color: const Color(0xFF10B981),
                ),
              ),
              SizedBox(
                width: w,
                child: StatCard(
                  label: 'Rejected',
                  value: stats.rejected.toDouble(),
                  icon: Icons.cancel_rounded,
                  color: const Color(0xFFEF4444),
                ),
              ),
              SizedBox(
                width: w,
                child: StatCard(
                  label: 'Cancelled',
                  value: stats.cancelled.toDouble(),
                  icon: Icons.block_rounded,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTab() {
    switch (_tab) {
      case 'Requests':
        return _buildRequestsTab();
      case 'Balances':
        return _buildBalancesTab();
      default:
        return _buildPendingTab();
    }
  }

  Widget _buildPendingTab() {
    if (_pending.isEmpty) {
      return const EmptyState(
        icon: Icons.task_alt_rounded,
        title: 'Nothing pending',
        subtitle: 'All leave requests have been reviewed.',
      );
    }
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        for (final r in _pending)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _PendingCard(
              request: r,
              onApprove: () => _decide(r, approve: true),
              onReject: () => _decide(r, approve: false),
            ),
          ),
      ],
    );
  }

  Widget _buildRequestsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: TextField(
            controller: _searchController,
            onChanged: (_) {
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 400), _reloadRequests);
            },
            decoration: InputDecoration(
              hintText: 'Search by employee name',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear_rounded, size: 18),
                onPressed: () {
                  _searchController.clear();
                  _reloadRequests();
                },
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in _statuses)
                ChoiceChip(
                  label: Text(Formatters.enumLabel(s)),
                  selected: _statusFilter == s,
                  selectedColor: ExperimentPalette.leave.withValues(alpha: 0.15),
                  labelStyle: TextStyle(
                    color: _statusFilter == s ? ExperimentPalette.leave : Colors.grey.shade700,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (_) {
                    setState(() => _statusFilter = s);
                    _reloadRequests();
                  },
                ),
            ],
          ),
        ),
        Expanded(
          child: _requests.isEmpty
              ? const EmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'No requests found',
                  subtitle: 'Try a different status or employee name.',
                )
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    for (final r in _requests)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: LeaveRequestCard(request: r, showEmployee: true),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildBalancesTab() {
    if (_employees.isEmpty) {
      return const EmptyState(
        icon: Icons.people_outline_rounded,
        title: 'No employees found',
      );
    }
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        for (final e in _employees)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AnimatedCard(
              accentColor: ExperimentPalette.leave,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: ExperimentPalette.leave.withValues(alpha: 0.15),
                    child: Text(
                      e.name.isNotEmpty ? e.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: ExperimentPalette.leave,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.name,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(e.email, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                        const SizedBox(height: 6),
                        _balanceSummary(e.balance),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _adjustBalance(e),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ExperimentPalette.leave,
                      side: BorderSide(color: ExperimentPalette.leave.withValues(alpha: 0.6)),
                    ),
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: const Text('Adjust'),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _balanceSummary(LeaveBalance? balance) {
    if (balance == null) {
      return Text(
        'Balance not loaded — use Adjust to fetch and update',
        style: TextStyle(
          color: Colors.grey.shade500,
          fontSize: 11.5,
          fontStyle: FontStyle.italic,
        ),
      );
    }
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        _balanceChip('Casual', balance.casualLeave),
        _balanceChip('Medical', balance.medicalLeave),
        _balanceChip('Earned', balance.earnedLeave),
        _balanceChip('Other', balance.otherLeave),
      ],
    );
  }

  Widget _balanceChip(String label, double value) {
    final text = value == value.roundToDouble()
        ? value.round().toString()
        : value.toStringAsFixed(1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: ExperimentPalette.leave.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label $text',
        style: const TextStyle(
          color: ExperimentPalette.leave,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _BackHeader extends StatelessWidget {
  final VoidCallback onBack;

  const _BackHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE6E8F0))),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back_rounded),
            color: ExperimentPalette.leave,
          ),
          const SizedBox(width: 4),
          const Text(
            'Leave Admin',
            style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700, color: AppColors.textDark),
          ),
        ],
      ),
    );
  }
}

class _PendingCard extends StatelessWidget {
  final LeaveRequest request;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _PendingCard({
    required this.request,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final r = request;
    return AnimatedCard(
      accentColor: ExperimentPalette.leave,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: ExperimentPalette.leave.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(_typeIcon(r.leaveType), color: ExperimentPalette.leave, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.employeeName ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${Formatters.enumLabel(r.leaveType)} • ${r.numberOfDays} day${r.numberOfDays == 1 ? '' : 's'}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              StatusChip(status: r.status),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${Formatters.date(r.startDate)} to ${Formatters.date(r.endDate)}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
          ),
          const SizedBox(height: 6),
          Text(r.reason, style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.4)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onReject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                    side: const BorderSide(color: Color(0xFFEF4444)),
                  ),
                  icon: const Icon(Icons.close_rounded, size: 17),
                  label: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onApprove,
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                  icon: const Icon(Icons.check_rounded, size: 17),
                  label: const Text('Approve'),
                ),
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

class _AdjustBalanceDialog extends StatefulWidget {
  final EmployeeBalance employee;

  const _AdjustBalanceDialog({required this.employee});

  static Future<LeaveBalance?> show(BuildContext context, EmployeeBalance employee) {
    return showDialog<LeaveBalance>(
      context: context,
      builder: (_) => _AdjustBalanceDialog(employee: employee),
    );
  }

  @override
  State<_AdjustBalanceDialog> createState() => _AdjustBalanceDialogState();
}

class _AdjustBalanceDialogState extends State<_AdjustBalanceDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _casual;
  late final TextEditingController _medical;
  late final TextEditingController _earned;
  late final TextEditingController _other;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final b = widget.employee.balance;
    _casual = TextEditingController(text: _value(b?.casualLeave, 12));
    _medical = TextEditingController(text: _value(b?.medicalLeave, 10));
    _earned = TextEditingController(text: _value(b?.earnedLeave, 15));
    _other = TextEditingController(text: _value(b?.otherLeave, 5));
  }

  @override
  void dispose() {
    _casual.dispose();
    _medical.dispose();
    _earned.dispose();
    _other.dispose();
    super.dispose();
  }

  String _value(double? v, double fallback) {
    final value = v ?? fallback;
    return value == value.roundToDouble() ? value.round().toString() : value.toStringAsFixed(1);
  }

  double _parse(TextEditingController c) => double.tryParse(c.text.trim()) ?? -1;

  String? _validator(TextEditingController c) {
    final value = double.tryParse(c.text.trim());
    if (value == null || value < 0) return 'Enter 0 or more';
    return null;
  }

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final balance = await LeaveService.updateUserBalance(
        userId: widget.employee.id,
        casualLeave: _parse(_casual),
        medicalLeave: _parse(_medical),
        earnedLeave: _parse(_earned),
        otherLeave: _parse(_other),
      );
      if (!mounted) return;
      Navigator.of(context).pop(balance);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      AppDialogs.showSnack(context, AppDialogs.friendlyError(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Adjust Balance — ${widget.employee.name}',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(_casual, 'Casual Leave'),
              const SizedBox(height: 12),
              _field(_medical, 'Medical Leave'),
              const SizedBox(height: 12),
              _field(_earned, 'Earned Leave'),
              const SizedBox(height: 12),
              _field(_other, 'Other Leave'),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          style: FilledButton.styleFrom(backgroundColor: ExperimentPalette.leave),
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Save Balance'),
        ),
      ],
    );
  }

  Widget _field(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(labelText: label),
      validator: (_) => _validator(controller),
    );
  }
}