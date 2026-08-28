import 'package:flutter/material.dart';

class ProjectStats {
  final int total;
  final int completed;
  final int inProgress;
  final int pending;
  final double progress;

  const ProjectStats({
    this.total = 0,
    this.completed = 0,
    this.inProgress = 0,
    this.pending = 0,
    this.progress = 0.0,
  });

  factory ProjectStats.fromJson(Map<String, dynamic> json) => ProjectStats(
        total: (json['total'] as num?)?.toInt() ?? 0,
        completed: (json['completed'] as num?)?.toInt() ?? 0,
        inProgress: (json['in_progress'] as num?)?.toInt() ?? 0,
        pending: (json['pending'] as num?)?.toInt() ?? 0,
        progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      );
}

class Project {
  final String id;
  final String name;
  final String description;
  final String color;
  final String? createdAt;
  final ProjectStats? stats;

  const Project({
    required this.id,
    required this.name,
    this.description = '',
    this.color = '#4f46e5',
    this.createdAt,
    this.stats,
  });

  factory Project.fromJson(Map<String, dynamic> json) => Project(
        id: (json['id'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        description: (json['description'] ?? '').toString(),
        color: (json['color'] ?? '#4f46e5').toString(),
        createdAt: json['created_at']?.toString(),
        stats: json['stats'] is Map<String, dynamic>
            ? ProjectStats.fromJson(json['stats'] as Map<String, dynamic>)
            : null,
      );

  static Color colorFromHex(String hex, {Color fallback = const Color(0xFFEC4899)}) {
    var cleaned = hex.replaceAll('#', '');
    if (cleaned.length == 6) cleaned = 'FF$cleaned';
    final value = int.tryParse(cleaned, radix: 16);
    return value == null ? fallback : Color(value);
  }

  Color get colorValue => colorFromHex(color);
}
