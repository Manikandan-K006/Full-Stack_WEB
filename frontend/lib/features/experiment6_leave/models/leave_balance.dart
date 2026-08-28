class LeaveBalance {
  final String id;
  final String userId;
  final double casualLeave;
  final double medicalLeave;
  final double earnedLeave;
  final double otherLeave;
  final String? createdAt;

  const LeaveBalance({
    required this.id,
    this.userId = '',
    required this.casualLeave,
    required this.medicalLeave,
    required this.earnedLeave,
    required this.otherLeave,
    this.createdAt,
  });

  factory LeaveBalance.fromJson(Map<String, dynamic> json) => LeaveBalance(
        id: (json['id'] ?? '').toString(),
        userId: (json['user_id'] ?? '').toString(),
        casualLeave: ((json['casual_leave'] ?? 0) as num).toDouble(),
        medicalLeave: ((json['medical_leave'] ?? 0) as num).toDouble(),
        earnedLeave: ((json['earned_leave'] ?? 0) as num).toDouble(),
        otherLeave: ((json['other_leave'] ?? 0) as num).toDouble(),
        createdAt: json['created_at']?.toString(),
      );

  double forType(String leaveType) {
    switch (leaveType) {
      case 'CASUAL':
        return casualLeave;
      case 'MEDICAL':
        return medicalLeave;
      case 'EARNED':
        return earnedLeave;
      case 'OTHER':
        return otherLeave;
      default:
        return 0;
    }
  }
}
