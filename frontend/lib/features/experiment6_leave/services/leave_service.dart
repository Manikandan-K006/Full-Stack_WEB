import '../../../core/network/api_client.dart';
import '../models/employee_balance.dart';
import '../models/leave_balance.dart';
import '../models/leave_request.dart';
import '../models/leave_stats.dart';

class LeaveService {
  static Future<LeaveBalance> getBalance() async {
    final data = await ApiClient.instance.get('/api/leaves/balance');
    return LeaveBalance.fromJson(data as Map<String, dynamic>);
  }

  static Future<LeaveRequest> apply({
    required String leaveType,
    required String startDate,
    required String endDate,
    required String reason,
  }) async {
    final data = await ApiClient.instance.post('/api/leaves', body: {
      'leave_type': leaveType,
      'start_date': startDate,
      'end_date': endDate,
      'reason': reason,
    });
    return LeaveRequest.fromJson((data as Map<String, dynamic>));
  }

  static Future<List<LeaveRequest>> myRequests({String? status}) async {
    final data = await ApiClient.instance.get('/api/leaves', query: {
      if (status != null && status.isNotEmpty) 'status': status,
    });
    return _requests(data);
  }

  static Future<LeaveRequest> cancel(String requestId) async {
    final data = await ApiClient.instance.put('/api/leaves/$requestId/cancel');
    return LeaveRequest.fromJson(data as Map<String, dynamic>);
  }

  static Future<List<LeaveRequest>> allRequests({String? status, String? employee}) async {
    final data = await ApiClient.instance.get('/api/admin/leaves', query: {
      if (status != null && status.isNotEmpty) 'status': status,
      if (employee != null && employee.trim().isNotEmpty) 'employee': employee.trim(),
    });
    return _requests(data);
  }

  static Future<LeaveRequest> approve(String requestId, {String? remark}) async {
    final data = await ApiClient.instance.put('/api/admin/leaves/$requestId/approve', body: {
      if (remark != null && remark.trim().isNotEmpty) 'remark': remark.trim(),
    });
    return LeaveRequest.fromJson(data as Map<String, dynamic>);
  }

  static Future<LeaveRequest> reject(String requestId, {String? remark}) async {
    final data = await ApiClient.instance.put('/api/admin/leaves/$requestId/reject', body: {
      if (remark != null && remark.trim().isNotEmpty) 'remark': remark.trim(),
    });
    return LeaveRequest.fromJson(data as Map<String, dynamic>);
  }

  static Future<LeaveBalance> updateUserBalance({
    required String userId,
    required double casualLeave,
    required double medicalLeave,
    required double earnedLeave,
    required double otherLeave,
  }) async {
    final data = await ApiClient.instance.put('/api/admin/leaves/$userId/balance', body: {
      'casual_leave': casualLeave,
      'medical_leave': medicalLeave,
      'earned_leave': earnedLeave,
      'other_leave': otherLeave,
    });
    return LeaveBalance.fromJson(data as Map<String, dynamic>);
  }

  static Future<LeaveStats> getStats() async {
    final data = await ApiClient.instance.get('/api/admin/leaves/stats');
    return LeaveStats.fromJson(data as Map<String, dynamic>);
  }

  static Future<List<EmployeeBalance>> listUsers() async {
    final data = await ApiClient.instance.get('/api/admin/users');
    return (data as List)
        .map((e) => EmployeeBalance.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static List<LeaveRequest> _requests(dynamic data) =>
      (data as List).map((e) => LeaveRequest.fromJson(e as Map<String, dynamic>)).toList();
}