import 'leave_balance.dart';

class EmployeeBalance {
  final String id;
  final String name;
  final String email;
  final String role;
  final LeaveBalance? balance;

  const EmployeeBalance({
    required this.id,
    required this.name,
    required this.email,
    this.role = 'USER',
    this.balance,
  });

  factory EmployeeBalance.fromJson(Map<String, dynamic> json) => EmployeeBalance(
        id: (json['id'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        email: (json['email'] ?? '').toString(),
        role: (json['role'] ?? 'USER').toString(),
      );

  EmployeeBalance copyWith({LeaveBalance? balance}) => EmployeeBalance(
        id: id,
        name: name,
        email: email,
        role: role,
        balance: balance ?? this.balance,
      );
}