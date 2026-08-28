import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../widgets/app_dialogs.dart';
import '../../../widgets/feature_navigator.dart';
import '../../../widgets/status_chip.dart';
import '../models/survey_question.dart';
import '../services/survey_service.dart';
import 'survey_result_screen.dart';

class SurveyAttemptScreen extends StatefulWidget {
  final String attemptId;
  final List<SurveyQuestion> questions;
  final VoidCallback? onCompleted;
  final VoidCallback? onTryAgain;

  const SurveyAttemptScreen({
    super.key,
    required this.attemptId,
    required this.questions,
    this.onCompleted,
    this.onTryAgain,
  });

  @override
  State<SurveyAttemptScreen> createState() => _SurveyAttemptScreenState();
}

class _SurveyAttemptScreenState extends State<SurveyAttemptScreen> {
  int _index = 0;
  bool _submitting = false;
  final Map<String, String> _answers = {};
  late final TextEditingController _textCtrl;

  SurveyQuestion get _current => widget.questions[_index];

  @override
  void initState() {
    super.initState();
    _textCtrl = TextEditingController(text: _answers[_current.id] ?? '');
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  bool get _currentAnswered {
    final answer = _answers[_current.id];
    return answer != null && answer.trim().isNotEmpty;
  }

  void _saveShortAnswer() {
    if (_current.isShortAnswer) {
      _answers[_current.id] = _textCtrl.text.trim();
    }
  }

  void _selectAnswer(String value) {
    setState(() => _answers[_current.id] = value);
  }

  void _goTo(int newIndex) {
    _saveShortAnswer();
    setState(() => _index = newIndex);
    _textCtrl.text = _answers[widget.questions[_index].id] ?? '';
  }

  void _next() {
    if (!_currentAnswered) {
      AppDialogs.showSnack(context, 'Please answer this question before continuing.',
          error: true);
      return;
    }
    _goTo(_index + 1);
  }

  void _previous() {
    _goTo(_index - 1);
  }

  Future<void> _submit() async {
    _saveShortAnswer();
    if (!_currentAnswered) {
      AppDialogs.showSnack(context, 'Please answer this question before submitting.',
          error: true);
      return;
    }
    setState(() => _submitting = true);
    try {
      final result = await submitSurvey(attemptId: widget.attemptId, answers: _answers);
      widget.onCompleted?.call();
      if (!mounted) return;
      FeatureNavigator.of(context).pushReplacement(SurveyResultScreen(
        attemptId: widget.attemptId,
        initial: result,
        onTryAgain: widget.onTryAgain,
        onBackToHome: widget.onCompleted,
      ));
    } catch (e) {
      if (!mounted) return;
      AppDialogs.showSnack(context, AppDialogs.friendlyError(e), error: true);
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.questions.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BackHeader(
          title: 'Survey - Question ${_index + 1} of $total',
          trailing: StatusChip(status: _current.difficulty),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (_index + 1) / total,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFE6E8F0),
                    color: ExperimentPalette.survey,
                  ),
                ),
                const SizedBox(height: 18),
                _QuestionCard(question: _current),
                const SizedBox(height: 16),
                _AnswerArea(
                  question: _current,
                  answer: _answers[_current.id] ?? '',
                  textCtrl: _textCtrl,
                  onSelect: _selectAnswer,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    if (_index > 0)
                      OutlinedButton.icon(
                        onPressed: _previous,
                        icon: const Icon(Icons.arrow_back_rounded, size: 18),
                        label: const Text('Previous'),
                      ),
                    const Spacer(),
                    if (_index < total - 1)
                      FilledButton.icon(
                        onPressed: _next,
                        style: FilledButton.styleFrom(
                          backgroundColor: ExperimentPalette.survey,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 22, vertical: 12),
                        ),
                        icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                        label: const Text('Next'),
                      )
                    else
                      FilledButton.icon(
                        onPressed: _submitting ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: ExperimentPalette.survey,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 22, vertical: 12),
                        ),
                        icon: _submitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.check_circle_rounded, size: 19),
                        label: Text(_submitting ? 'Submitting…' : 'Submit Survey'),
                      ),
                  ],
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BackHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const _BackHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => FeatureNavigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_rounded),
            color: AppColors.textDark,
            tooltip: 'Exit survey',
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textDark),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final SurveyQuestion question;

  const _QuestionCard({required this.question});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            Formatters.enumLabel(question.type),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            question.text,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
                height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _AnswerArea extends StatelessWidget {
  final SurveyQuestion question;
  final String answer;
  final TextEditingController textCtrl;
  final ValueChanged<String> onSelect;

  const _AnswerArea({
    required this.question,
    required this.answer,
    required this.textCtrl,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (question.isShortAnswer) {
      return TextField(
        controller: textCtrl,
        minLines: 3,
        maxLines: 5,
        decoration: InputDecoration(
          hintText: 'Type your answer here…',
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE6E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE6E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: ExperimentPalette.survey, width: 1.6),
          ),
        ),
      );
    }

    final items = question.isTrueFalse
        ? ['True', 'False']
        : question.options.where((o) => o.trim().isNotEmpty).toList();

    if (question.isTrueFalse) {
      return Row(
        children: [
          for (final option in items) ...[
            Expanded(
              child: _TrueFalseButton(
                label: option,
                selected: answer == option,
                onTap: () => onSelect(option),
              ),
            ),
            if (option != items.last) const SizedBox(width: 12),
          ],
        ],
      );
    }

    return Column(
      children: [
        for (final option in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onSelect(option),
                borderRadius: BorderRadius.circular(12),
                child: Ink(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: answer == option
                        ? ExperimentPalette.survey.withValues(alpha: 0.09)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: answer == option
                          ? ExperimentPalette.survey
                          : const Color(0xFFE6E8F0),
                      width: answer == option ? 1.6 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        answer == option
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        size: 21,
                        color: answer == option
                            ? ExperimentPalette.survey
                            : const Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          option,
                          style: const TextStyle(fontSize: 14.5, height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _TrueFalseButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TrueFalseButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected
              ? ExperimentPalette.survey.withValues(alpha: 0.09)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? ExperimentPalette.survey : const Color(0xFFE6E8F0),
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              label == 'True' ? Icons.check_rounded : Icons.close_rounded,
              size: 20,
              color: selected ? ExperimentPalette.survey : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: selected ? ExperimentPalette.survey : AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}