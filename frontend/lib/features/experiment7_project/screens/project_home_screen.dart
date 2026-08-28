import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../widgets/animated_card.dart';
import '../../../widgets/app_dialogs.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_widget.dart';
import '../../../widgets/feature_navigator.dart';
import '../../../widgets/loading_widget.dart';
import '../../../widgets/stat_card.dart';
import '../models/project.dart';
import '../services/project_service.dart';
import '../widgets/project_form_dialog.dart';
import 'project_detail_screen.dart';

class ProjectHomeScreen extends StatefulWidget {
  const ProjectHomeScreen({super.key});

  @override
  State<ProjectHomeScreen> createState() => _ProjectHomeScreenState();
}

class _ProjectHomeScreenState extends State<ProjectHomeScreen> {
  List<Project> _projects = [];
  ProjectStats _stats = const ProjectStats();
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final results = await Future.wait([
        ProjectService.fetchProjects(),
        ProjectService.fetchTaskStats(),
      ]);
      if (!mounted) return;
      setState(() {
        _projects = results[0] as List<Project>;
        _stats = results[1] as ProjectStats;
        _loading = false;
        _error = null;
      });
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _showCreateDialog() async {
    final payload = await ProjectFormDialog.show(context);
    if (payload == null || !mounted) return;
    try {
      await ProjectService.createProject(
        name: payload['name'] as String,
        description: payload['description'] as String? ?? '',
        color: payload['color'] as String? ?? '#EC4899',
      );
      if (!mounted) return;
      AppDialogs.showSnack(context, 'Project created successfully');
      await _load(silent: true);
    } on Exception catch (e) {
      if (!mounted) return;
      AppDialogs.showSnack(context, AppDialogs.friendlyError(e), error: true);
    }
  }

  Future<void> _showEditDialog(Project project) async {
    final payload = await ProjectFormDialog.show(context, project: project);
    if (payload == null || !mounted) return;
    try {
      await ProjectService.updateProject(
        project.id,
        name: payload['name'] as String,
        description: payload['description'] as String? ?? '',
        color: payload['color'] as String? ?? project.color,
      );
      if (!mounted) return;
      AppDialogs.showSnack(context, 'Project updated successfully');
      await _load(silent: true);
    } on Exception catch (e) {
      if (!mounted) return;
      AppDialogs.showSnack(context, AppDialogs.friendlyError(e), error: true);
    }
  }

  Future<void> _deleteProject(Project project) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete Project',
      message:
          'Are you sure you want to delete "${project.name}" and all of its tasks? This cannot be undone.',
      confirmLabel: 'Delete',
      icon: Icons.delete_outline_rounded,
    );
    if (!confirmed || !mounted) return;
    try {
      await ProjectService.deleteProject(project.id);
      if (!mounted) return;
      AppDialogs.showSnack(context, 'Project deleted successfully');
      await _load(silent: true);
    } on Exception catch (e) {
      if (!mounted) return;
      AppDialogs.showSnack(context, AppDialogs.friendlyError(e), error: true);
    }
  }

  void _openProject(Project project) {
    FeatureNavigator.of(context)
        .push(ProjectDetailScreen(project: project));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const LoadingWidget(message: 'Loading projects...');
    }
    if (_error != null) {
      return ErrorWidgetView(
          message: AppDialogs.friendlyError(_error), onRetry: _load);
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildStatsRow(),
          const SizedBox(height: 24),
          Row(
            children: [
              const Text(
                'Projects',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark),
              ),
              const Spacer(),
              Text(
                '${_projects.length} ${_projects.length == 1 ? 'project' : 'projects'}',
                style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_projects.isEmpty)
            _buildEmptyState()
          else
            _buildProjectGrid(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: ExperimentPalette.project.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.dashboard_customize_rounded,
              color: ExperimentPalette.project, size: 24),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Project Management',
                style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark),
              ),
              SizedBox(height: 2),
              Text(
                'Experiment 7 • Kanban task boards',
                style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        FilledButton.icon(
          onPressed: _showCreateDialog,
          style: FilledButton.styleFrom(
            backgroundColor: ExperimentPalette.project,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          ),
          icon: const Icon(Icons.add_rounded, size: 20),
          label: const Text('New Project',
              style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns =
            constraints.maxWidth >= 1100 ? 4 : (constraints.maxWidth >= 700 ? 2 : 1);
        final cardWidth = (constraints.maxWidth - (columns - 1) * 12) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: cardWidth,
              child: StatCard(
                label: 'Total Tasks',
                value: _stats.total.toDouble(),
                icon: Icons.task_alt_rounded,
                color: ExperimentPalette.project,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: StatCard(
                label: 'In Progress',
                value: _stats.inProgress.toDouble(),
                icon: Icons.play_circle_fill_rounded,
                color: const Color(0xFF0EA5E9),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: StatCard(
                label: 'Completed',
                value: _stats.completed.toDouble(),
                icon: Icons.check_circle_rounded,
                color: const Color(0xFF10B981),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: StatCard(
                label: 'Progress',
                value: _stats.progress,
                suffix: '%',
                icon: Icons.pie_chart_rounded,
                color: const Color(0xFF8B5CF6),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProjectGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns =
            constraints.maxWidth >= 1100 ? 3 : (constraints.maxWidth >= 700 ? 2 : 1);
        final cardWidth = (constraints.maxWidth - (columns - 1) * 16) / columns;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final project in _projects)
              SizedBox(
                width: cardWidth,
                child: _ProjectCard(
                  project: project,
                  onTap: () => _openProject(project),
                  onEdit: () => _showEditDialog(project),
                  onDelete: () => _deleteProject(project),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return EmptyState(
      icon: Icons.dashboard_customize_rounded,
      title: 'No projects yet',
      subtitle: 'Create your first project to start organizing tasks on a Kanban board.',
      action: OutlinedButton.icon(
        onPressed: _showCreateDialog,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Project'),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProjectCard({
    required this.project,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final stats = project.stats;
    final color = project.colorValue;
    final progress = (stats?.progress ?? 0) / 100;
    return AnimatedCard(
      accentColor: color,
      padding: const EdgeInsets.all(16),
      hoverElevation: 10,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 14,
                height: 38,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  project.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark),
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Project actions',
                iconSize: 19,
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded,
                            size: 18, color: AppColors.danger),
                        SizedBox(width: 8),
                        Text('Delete',
                            style: TextStyle(color: AppColors.danger)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            project.description.isEmpty
                ? 'No description provided'
                : project.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 12.5,
                color: project.description.isEmpty
                    ? Colors.grey.shade400
                    : Colors.grey.shade600,
                height: 1.45),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 7,
                    backgroundColor: color.withValues(alpha: 0.14),
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                Formatters.percent(stats?.progress ?? 0),
                style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _CountItem(
                  icon: Icons.pending_actions_rounded,
                  value: stats?.pending ?? 0,
                  label: 'Pending',
                  color: const Color(0xFFF59E0B)),
              const SizedBox(width: 14),
              _CountItem(
                  icon: Icons.play_circle_outline_rounded,
                  value: stats?.inProgress ?? 0,
                  label: 'Active',
                  color: const Color(0xFF0EA5E9)),
              const SizedBox(width: 14),
              _CountItem(
                  icon: Icons.check_circle_outline_rounded,
                  value: stats?.completed ?? 0,
                  label: 'Done',
                  color: const Color(0xFF10B981)),
              const Spacer(),
              Icon(Icons.chevron_right_rounded,
                  color: color.withValues(alpha: 0.8), size: 22),
            ],
          ),
        ],
      ),
    );
  }
}

class _CountItem extends StatelessWidget {
  final IconData icon;
  final int value;
  final String label;
  final Color color;

  const _CountItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 4),
        Text('$value',
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark)),
        const SizedBox(width: 3),
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }
}