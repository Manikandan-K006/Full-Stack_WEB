import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  final String status;
  final Color? color;
  const StatusChip({super.key, required this.status, this.color});

  static Color colorFor(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
      case 'APPROVED':
      case 'DELIVERED':
      case 'AVAILABLE':
      case 'ACTIVE':
      case 'CONFIRMED':
        return const Color(0xFF10B981);
      case 'PENDING':
      case 'IN_PROGRESS':
      case 'PLACED':
      case 'PREPARING':
      case 'MEDIUM':
        return const Color(0xFFF59E0B);
      case 'REJECTED':
      case 'CANCELLED':
      case 'REMOVED':
      case 'SOLD':
      case 'CRITICAL':
        return const Color(0xFFEF4444);
      case 'OUT_FOR_DELIVERY':
      case 'HIGH':
        return const Color(0xFF0EA5E9);
      case 'URGENT':
        return const Color(0xFF8B5CF6);
      case 'LOW':
        return const Color(0xFF94A3B8);
      default:
        return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = color ?? colorFor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: TextStyle(
          color: c,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}