class LeaveRequest {
  final String id;
  final String userId;
  final String? employeeName;
  final String leaveType;
  final String startDate;
  final String endDate;
  final int numberOfDays;
  final String reason;
  final String status;
  final String? approvedBy;
  final String? decisionRemark;
  final String? decidedAt;
  final String? createdAt;

  const LeaveRequest({
    required this.id,
    required this.userId,
    this.employeeName,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.numberOfDays,
    required this.reason,
    required this.status,
    this.approvedBy,
    this.decisionRemark,
    this.decidedAt,
    this.createdAt,
  });

  bool get isPending => status == 'PENDING';

  factory LeaveRequest.fromJson(Map<String, dynamic> json) => LeaveRequest(
        id: (json['id'] ?? '').toString(),
        userId: (json['user_id'] ?? '').toString(),
        employeeName: json['employee_name']?.toString(),
        leaveType: (json['leave_type'] ?? '').toString(),
        startDate: (json['start_date'] ?? '').toString(),
        endDate: (json['end_date'] ?? '').toString(),
        numberOfDays: ((json['number_of_days'] ?? 0) as num).toInt(),
        reason: (json['reason'] ?? '').toString(),
        status: (json['status'] ?? '').toString(),
        approvedBy: json['approved_by']?.toString(),
        decisionRemark: json['decision_remark']?.toString(),
        decidedAt: json['decided_at']?.toString(),
        createdAt: json['created_at']?.toString(),
      );
}
