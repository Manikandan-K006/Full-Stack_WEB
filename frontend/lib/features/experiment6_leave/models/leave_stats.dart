class LeaveStats {
  final int total;
  final int pending;
  final int approved;
  final int rejected;
  final int cancelled;

  const LeaveStats({
    required this.total,
    required this.pending,
    required this.approved,
    required this.rejected,
    required this.cancelled,
  });

  factory LeaveStats.fromJson(Map<String, dynamic> json) => LeaveStats(
        total: ((json['total'] ?? 0) as num).toInt(),
        pending: ((json['pending'] ?? 0) as num).toInt(),
        approved: ((json['approved'] ?? 0) as num).toInt(),
        rejected: ((json['rejected'] ?? 0) as num).toInt(),
        cancelled: ((json['cancelled'] ?? 0) as num).toInt(),
      );
}
