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
import '../models/survey_attempt.dart';
import '../services/survey_service.dart';
import 'admin_question_bank_screen.dart';
import 'survey_attempt_screen.dart';
import 'survey_result_screen.dart';

class SurveyHomeScreen extends StatefulWidget {
  const SurveyHomeScreen({super.key});

  @override
  State<SurveyHomeScreen> createState() => _SurveyHomeScreenState();
}

class _SurveyHomeScreenState extends State<SurveyHomeScreen> {
  @override
  Widget build(BuildContext context) {
    return FeatureNavigator(
      backColor: ExperimentPalette.survey,
      backLabel: 'Survey',
      home: const _SurveyHomeBody(),
    );
  }
}

class _SurveyHomeBody extends StatefulWidget {
  const _SurveyHomeBody();

  @override
  State<_SurveyHomeBody> createState() => _SurveyHomeBodyState();
}

class _SurveyHomeBodyState extends State<_SurveyHomeBody> {
  bool _loading = true;
  bool _starting = false;
  String? _error;
  List<SurveyHistoryEntry> _history = const [];
  SurveyStats _stats = const SurveyStats();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_history.isEmpty) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final data = await fetchHistory();
      if (!mounted) return;
      setState(() {
        _history = data.history.where((a) => a.isCompleted).toList();
        _stats = data.stats;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      if (_history.isEmpty) {
        setState(() {
          _error = AppDialogs.friendlyError(e);
          _loading = false;
        });
      } else {
        AppDialogs.showSnack(context, AppDialogs.friendlyError(e), error: true);
      }
    }
  }

  Future<void> _startAttempt() async {
    if (_starting) return;
    setState(() => _starting = true);
    try {
      final start = await startSurvey();
      if (!mounted) return;
      FeatureNavigator.of(context).push(SurveyAttemptScreen(
        attemptId: start.attemptId,
        questions: start.questions,
        onCompleted: _load,
        onTryAgain: _startAttempt,
      ));
    } catch (e) {
      if (!mounted) return;
      AppDialogs.showSnack(context, AppDialogs.friendlyError(e), error: true);
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  void _openQuestionBank() {
    FeatureNavigator.of(context).push(const AdminQuestionBankScreen());
  }

  void _viewResults(SurveyHistoryEntry entry) {
    FeatureNavigator.of(context).push(SurveyResultScreen(attemptId: entry.id));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const LoadingWidget(message: 'Loading survey…');
    }
    if (_error != null) {
      return ErrorWidgetView(message: _error!, onRetry: _load);
    }
    final isAdmin = context.watch<Session>().user?.isAdmin ?? false;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeroCard(starting: _starting, onStart: _startAttempt),
          const SizedBox(height: 20),
          Row(
            children: [
              const Text(
                'Your Statistics',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark),
              ),
              const Spacer(),
              Text(
                '${_stats.attempts} completed',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _StatsRow(stats: _stats),
          if (isAdmin) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: AnimatedCard(
                accentColor: ExperimentPalette.survey,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                onTap: _openQuestionBank,
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: ExperimentPalette.survey.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(Icons.admin_panel_settings_rounded,
                          color: ExperimentPalette.survey, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Question Bank',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            'Manage survey questions, add, edit or delete.',
                            style: TextStyle(
                                fontSize: 12.5, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: Color(0xFF94A3B8)),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 22),
          Row(
            children: [
              const Text(
                'Previous Attempts',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark),
              ),
              const Spacer(),
              if (_history.isNotEmpty)
                Text(
                  '${_history.length} attempts',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_history.isEmpty)
            EmptyState(
              icon: Icons.quiz_outlined,
              title: 'No attempts yet',
              subtitle: 'Start your first survey and your scores will appear here.',
              action: FilledButton.icon(
                onPressed: _startAttempt,
                style: FilledButton.styleFrom(
                  backgroundColor: ExperimentPalette.survey,
                ),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Start New Attempt'),
              ),
            )
          else
            for (final entry in _history) ...[
              _HistoryCard(entry: entry, onView: () => _viewResults(entry)),
              const SizedBox(height: 12),
            ],
          const SizedBox(height: 28),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final bool starting;
  final VoidCallback onStart;

  const _HeroCard({required this.starting, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B3B36), Color(0xFF0F766E), Color(0xFF14B8A6)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Color(0x5514B8A6), blurRadius: 24, offset: Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.quiz_rounded, color: Colors.white, size: 30),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ONLINE SURVEY',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                    Text(
                      'Experiment 8',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Test your full stack knowledge',
            style: TextStyle(
                color: Colors.white, fontSize: 21, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          for (final point in const [
            '5 random questions on every attempt',
            'MCQ and True/False answers are auto-scored',
            'Short answers are recorded, not auto-scored',
            'Instant results with correct answers & explanations',
          ]) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Colors.white70, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    point,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: 13,
                        height: 1.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: starting ? null : onStart,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF0F766E),
                padding: const EdgeInsets.symmetric(vertical: 14),
                disabledBackgroundColor: Colors.white70,
              ),
              icon: starting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Color(0xFF0F766E)),
                    )
                  : const Icon(Icons.play_arrow_rounded),
              label: Text(starting ? 'Starting…' : 'Start New Attempt'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final SurveyStats stats;

  const _StatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 620;
        final cardWidth = wide ? (constraints.maxWidth - 24) / 3 : constraints.maxWidth;
        final cards = [
          StatCard(
            label: 'Attempts',
            value: stats.attempts.toDouble(),
            icon: Icons.flag_rounded,
            color: ExperimentPalette.survey,
          ),
          StatCard(
            label: 'Best Score',
            value: stats.best,
            suffix: '%',
            icon: Icons.star_rounded,
            color: const Color(0xFFF59E0B),
          ),
          StatCard(
            label: 'Average',
            value: stats.average,
            suffix: '%',
            icon: Icons.insights_rounded,
            color: const Color(0xFF4F46E5),
          ),
        ];
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final card in cards)
              SizedBox(width: cardWidth, child: card),
          ],
        );
      },
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final SurveyHistoryEntry entry;
  final VoidCallback onView;

  const _HistoryCard({required this.entry, required this.onView});

  @override
  Widget build(BuildContext context) {
    final percent = entry.scorePercentage ?? 0;
    return AnimatedCard(
      accentColor: ExperimentPalette.survey,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: ExperimentPalette.survey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.assignment_turned_in_rounded,
                color: ExperimentPalette.survey, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Formatters.dateTime(entry.startedAt),
                  style: const TextStyle(
                      fontSize: 13.5, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    StatusChip(status: entry.status),
                    if (entry.isCompleted && entry.totalScored != null)
                      Text(
                        '${entry.score ?? 0}/${entry.totalScored} correct',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (entry.isCompleted) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Formatters.percent(percent),
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: ExperimentPalette.survey),
                ),
                TextButton(
                  onPressed: onView,
                  style: TextButton.styleFrom(
                    foregroundColor: ExperimentPalette.survey,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('View results',
                      style: TextStyle(fontSize: 12.5)),
                ),
              ],
            ),
          ] else
            const Icon(Icons.hourglass_top_rounded,
                color: Color(0xFF94A3B8), size: 20),
        ],
      ),
    );
  }
}
