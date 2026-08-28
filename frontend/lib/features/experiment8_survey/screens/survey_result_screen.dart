import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../widgets/app_dialogs.dart';
import '../../../widgets/error_widget.dart';
import '../../../widgets/feature_navigator.dart';
import '../../../widgets/loading_widget.dart';
import '../../../widgets/status_chip.dart';
import '../models/survey_attempt.dart';
import '../services/survey_service.dart';

class SurveyResultScreen extends StatefulWidget {
  final String attemptId;
  final SurveyAttemptResult? initial;
  final VoidCallback? onTryAgain;
  final VoidCallback? onBackToHome;

  const SurveyResultScreen({
    super.key,
    required this.attemptId,
    this.initial,
    this.onTryAgain,
    this.onBackToHome,
  });

  @override
  State<SurveyResultScreen> createState() => _SurveyResultScreenState();
}

class _SurveyResultScreenState extends State<SurveyResultScreen> {
  bool _loading = false;
  String? _error;
  SurveyAttemptResult? _result;

  @override
  void initState() {
    super.initState();
    _result = widget.initial;
    if (_result == null) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await fetchAttemptResult(widget.attemptId);
      if (!mounted) return;
      setState(() {
        _result = result;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = AppDialogs.friendlyError(e);
        _loading = false;
      });
    }
  }

  void _backToHome() {
    FeatureNavigator.of(context).popUntilRoot();
    widget.onBackToHome?.call();
  }

  void _tryAgain() {
    if (widget.onTryAgain != null) {
      FeatureNavigator.of(context).popUntilRoot();
      widget.onTryAgain?.call();
    } else {
      FeatureNavigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BackHeader(title: 'Survey Results', onBack: () => FeatureNavigator.of(context).pop()),
        Expanded(
          child: Builder(builder: (context) {
            if (_loading) {
              return const LoadingWidget(message: 'Loading results…');
            }
            if (_error != null) {
              return ErrorWidgetView(message: _error!, onRetry: _load);
            }
            final result = _result;
            if (result == null) {
              return const SizedBox.shrink();
            }
            return _ResultBody(
              result: result,
              onTryAgain: _tryAgain,
              onBackToHome: _backToHome,
            );
          }),
        ),
      ],
    );
  }
}

class _BackHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const _BackHeader({required this.title, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
            color: AppColors.textDark,
            tooltip: 'Back',
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textDark),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultBody extends StatelessWidget {
  final SurveyAttemptResult result;
  final VoidCallback onTryAgain;
  final VoidCallback onBackToHome;

  const _ResultBody({
    required this.result,
    required this.onTryAgain,
    required this.onBackToHome,
  });

  @override
  Widget build(BuildContext context) {
    final details = result.details;
    final scored = details.where((d) => d.isScored).length;
    final correct = details.where((d) => d.isCorrect).length;
    final wrong = scored - correct;
    final notScored = details.length - scored;
    final percent = result.scorePercentage ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: _ScoreRing(percent: percent / 100),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              '${correct} of $scored scored questions correct',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ),
          const SizedBox(height: 20),
          _CountsRow(correct: correct, wrong: wrong, notScored: notScored),
          const SizedBox(height: 22),
          const Text(
            'Answer Review',
            style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textDark),
          ),
          const SizedBox(height: 12),
          if (details.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text('No question details available.',
                    style: TextStyle(color: Color(0xFF64748B))),
              ),
            )
          else
            for (final detail in details) ...[
              _ReviewCard(detail: detail),
              const SizedBox(height: 12),
            ],
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onTryAgain,
                  style: FilledButton.styleFrom(
                    backgroundColor: ExperimentPalette.survey,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 19),
                  label: const Text('Try again'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onBackToHome,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ExperimentPalette.survey,
                    side: const BorderSide(color: ExperimentPalette.survey),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  icon: const Icon(Icons.home_rounded, size: 19),
                  label: const Text('Back to home'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }
}

class _ScoreRing extends StatelessWidget {
  final double percent;

  const _ScoreRing({required this.percent});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: percent.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 1300),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return SizedBox(
          width: 190,
          height: 190,
          child: CustomPaint(
            painter: _RingPainter(progress: value, color: ExperimentPalette.survey),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    Formatters.percent(value * 100),
                    style: const TextStyle(
                        fontSize: 34, fontWeight: FontWeight.w800, color: AppColors.textDark),
                  ),
                  Text(
                    value >= percent ? 'scored' : '…',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12.5),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;

  const _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 13.0;
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = const Color(0xFFE6E8F0);
    canvas.drawCircle(center, radius, trackPaint);
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

class _CountsRow extends StatelessWidget {
  final int correct;
  final int wrong;
  final int notScored;

  const _CountsRow({
    required this.correct,
    required this.wrong,
    required this.notScored,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 620;
        final width = wide ? (constraints.maxWidth - 24) / 3 : constraints.maxWidth;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _CountCard(
              label: 'Correct',
              value: correct,
              icon: Icons.check_circle_rounded,
              color: const Color(0xFF10B981),
              width: width,
            ),
            _CountCard(
              label: 'Wrong',
              value: wrong,
              icon: Icons.cancel_rounded,
              color: const Color(0xFFEF4444),
              width: width,
            ),
            _CountCard(
              label: 'Not scored',
              value: notScored,
              icon: Icons.remove_circle_outline_rounded,
              color: const Color(0xFF94A3B8),
              width: width,
            ),
          ],
        );
      },
    );
  }
}

class _CountCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final double width;

  const _CountCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$value', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
              Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final SurveyAnswerDetail detail;

  const _ReviewCard({required this.detail});

  @override
  Widget build(BuildContext context) {
    final right = detail.isCorrect && detail.isScored;
    final iconColor = detail.isScored
        ? (right ? const Color(0xFF10B981) : const Color(0xFFEF4444))
        : const Color(0xFF94A3B8);
    final icon = detail.isScored
        ? (right ? Icons.check_circle_rounded : Icons.cancel_rounded)
        : Icons.remove_circle_outline_rounded;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: iconColor, size: 21),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detail.questionText,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600, height: 1.4),
                    ),
                    const SizedBox(height: 6),
                    StatusChip(status: detail.questionType),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _AnswerRow(
            label: 'Your answer',
            value: detail.givenAnswer.isEmpty ? 'No answer' : detail.givenAnswer,
            highlight: detail.isCorrect && detail.isScored,
          ),
          if (detail.isScored) ...[
            const SizedBox(height: 6),
            _AnswerRow(
              label: 'Correct answer',
              value: detail.correctAnswer.isEmpty ? '—' : detail.correctAnswer,
              highlight: false,
            ),
          ] else ...[
            const SizedBox(height: 6),
            _AnswerRow(
              label: 'Not auto-scored',
              value: 'Short answers are reviewed manually.',
              highlight: false,
            ),
          ],
          if (detail.explanation.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ExperimentPalette.survey.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Explanation: ${detail.explanation}',
                style: const TextStyle(
                    fontSize: 12.5, color: Color(0xFF0F766E), height: 1.45),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AnswerRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _AnswerRow({
    required this.label,
    required this.value,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    final color = highlight ? const Color(0xFF10B981) : Colors.grey.shade700;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 108,
          child: Text(label, style: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8))),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
                fontSize: 13, color: color, fontWeight: highlight ? FontWeight.w600 : FontWeight.w500),
          ),
        ),
      ],
    );
  }
}