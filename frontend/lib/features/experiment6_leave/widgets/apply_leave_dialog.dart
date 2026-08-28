import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/formatters.dart';
import '../../../widgets/app_dialogs.dart';
import '../models/leave_balance.dart';
import '../services/leave_service.dart';

class ApplyLeaveDialog extends StatefulWidget {
  final LeaveBalance? balance;

  const ApplyLeaveDialog({super.key, this.balance});

  @override
  State<ApplyLeaveDialog> createState() => _ApplyLeaveDialogState();
}

class _ApplyLeaveDialogState extends State<ApplyLeaveDialog> {
  static const _types = ['CASUAL', 'MEDICAL', 'EARNED', 'OTHER'];

  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  String? _leaveType;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _submitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  bool get _rangeInvalid => _startDate != null && _endDate != null && _endDate!.isBefore(_startDate!);

  int? get _days {
    final start = _startDate;
    final end = _endDate;
    if (start == null || end == null || end.isBefore(start)) return null;
    return DateUtilsExt.daysBetween(start, end) + 1;
  }

  double get _available {
    final type = _leaveType;
    if (type == null || widget.balance == null) return 0;
    return widget.balance!.forType(type);
  }

  bool get _canSubmit {
    return !_submitting &&
        _leaveType != null &&
        _startDate != null &&
        _endDate != null &&
        !_rangeInvalid &&
        _reasonController.text.trim().length >= 10;
  }

  Future<void> _pickStart() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _startDate = picked;
      if (_endDate != null && _endDate!.isBefore(picked)) _endDate = null;
    });
  }

  Future<void> _pickEnd() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked == null || !mounted) return;
    setState(() => _endDate = picked);
  }

  Future<void> _submit() async {
    if (!_canSubmit || !_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await LeaveService.apply(
        leaveType: _leaveType!,
        startDate: DateUtilsExt.normalize(_startDate!),
        endDate: DateUtilsExt.normalize(_endDate!),
        reason: _reasonController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      AppDialogs.showSnack(context, AppDialogs.friendlyError(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final days = _days;
    return AlertDialog(
      title: const Text('Apply for Leave', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _leaveType,
                  decoration: const InputDecoration(labelText: 'Leave Type'),
                  items: [
                    for (final t in _types)
                      DropdownMenuItem(value: t, child: Text(Formatters.enumLabel(t))),
                  ],
                  onChanged: (v) => setState(() => _leaveType = v),
                  validator: (v) => v == null ? 'Select a leave type' : null,
                ),
                const SizedBox(height: 14),
                _dateField(
                  label: 'Start Date',
                  value: _startDate,
                  onTap: _pickStart,
                ),
                const SizedBox(height: 14),
                _dateField(
                  label: 'End Date',
                  value: _endDate,
                  onTap: _pickEnd,
                ),
                if (_rangeInvalid) ...[
                  const SizedBox(height: 8),
                  Text(
                    'End date must be on or after the start date',
                    style: TextStyle(color: AppColors.danger, fontSize: 12.5),
                  ),
                ],
                if (days != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.event_repeat_rounded, size: 17, color: ExperimentPalette.leave),
                      const SizedBox(width: 6),
                      Text(
                        '$days day${days == 1 ? '' : 's'} (inclusive)',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
                      ),
                      const SizedBox(width: 10),
                      if (_leaveType != null)
                        Text(
                          '${_available.toStringAsFixed(_available == _available.roundToDouble() ? 0 : 1)} available',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                        ),
                    ],
                  ),
                  if (_leaveType != null && days > _available) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Requested days exceed your available ${Formatters.enumLabel(_leaveType!)} balance',
                      style: TextStyle(color: AppColors.warning, fontSize: 12.5),
                    ),
                  ],
                ],
                const SizedBox(height: 14),
                TextFormField(
                  controller: _reasonController,
                  maxLines: 3,
                  maxLength: 500,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Reason',
                    hintText: 'Why are you applying for leave? (min 10 characters)',
                    alignLabelWithHint: true,
                  ),
                  validator: (v) => (v == null || v.trim().length < 10)
                      ? 'Reason must be at least 10 characters'
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _canSubmit ? _submit : null,
          style: FilledButton.styleFrom(
            backgroundColor: ExperimentPalette.leave,
            disabledBackgroundColor: ExperimentPalette.leave.withValues(alpha: 0.35),
            disabledForegroundColor: Colors.white,
          ),
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Submit Request'),
        ),
      ],
    );
  }

  Widget _dateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(Icons.calendar_month_rounded, size: 20, color: ExperimentPalette.leave),
        ),
        child: Text(
          value == null ? 'Select date' : Formatters.date(DateUtilsExt.normalize(value)),
          style: TextStyle(
            color: value == null ? Colors.grey.shade500 : AppColors.textDark,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}