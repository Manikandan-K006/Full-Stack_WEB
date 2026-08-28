import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../services/session.dart';
import '../../../widgets/app_dialogs.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_widget.dart';
import '../../../widgets/feature_navigator.dart';
import '../../../widgets/loading_widget.dart';
import '../../../widgets/stat_card.dart';
import '../../../widgets/status_chip.dart';
import '../models/admin_question.dart';
import '../models/survey_question.dart';
import '../services/survey_service.dart';

class AdminQuestionBankScreen extends StatefulWidget {
  const AdminQuestionBankScreen({super.key});

  @override
  State<AdminQuestionBankScreen> createState() => _AdminQuestionBankScreenState();
}

class _AdminQuestionBankScreenState extends State<AdminQuestionBankScreen> {
  bool _loading = true;
  bool _saving = false;
  String? _error;
  AdminQuestionStats? _stats;
  List<SurveyQuestion> _items = const [];
  int _total = 0;
  String _type = 'ALL';
  String _difficulty = 'ALL';
  String _search = '';
  final Map<String, AdminQuestion> _full = {};

  static const List<String> _types = ['ALL', 'MCQ', 'TRUE_FALSE', 'SHORT_ANSWER'];
  static const List<String> _difficulties = ['ALL', 'EASY', 'MEDIUM', 'HARD'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final statsFuture = fetchQuestionStats();
      final itemsFuture = fetchQuestionBank(
          type: _type, difficulty: _difficulty, search: _search);
      final stats = await statsFuture;
      final items = await itemsFuture;
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _items = items.items;
        _total = items.total;
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

  Future<void> _loadItems() async {
    try {
      final items = await fetchQuestionBank(
          type: _type, difficulty: _difficulty, search: _search);
      if (!mounted) return;
      setState(() {
        _items = items.items;
        _total = items.total;
      });
    } catch (e) {
      if (!mounted) return;
      AppDialogs.showSnack(context, AppDialogs.friendlyError(e), error: true);
    }
  }

  void _onFilterChanged({String? type, String? difficulty}) {
    setState(() {
      if (type != null) _type = type;
      if (difficulty != null) _difficulty = difficulty;
    });
    _loadItems();
  }

  AdminQuestion? _adminViewOf(SurveyQuestion item) {
    final known = _full[item.id];
    if (known != null) return known;
    return AdminQuestion(
      id: item.id,
      text: item.text,
      type: item.type,
      options: item.options,
      difficulty: item.difficulty,
    );
  }

  Future<void> _openForm({AdminQuestion? existing}) async {
    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _QuestionFormDialog(existing: existing),
    );
    if (payload == null || !mounted) return;
    setState(() => _saving = true);
    try {
      if (existing == null) {
        final created = await createQuestion(payload);
        _full[created.id] = created;
      } else {
        final updated = await updateQuestion(existing.id, payload);
        _full[updated.id] = updated;
      }
      if (!mounted) return;
      AppDialogs.showSnack(context,
          existing == null ? 'Question created' : 'Question updated');
      await _load();
    } catch (e) {
      if (!mounted) return;
      AppDialogs.showSnack(context, AppDialogs.friendlyError(e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteQuestion(SurveyQuestion item) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete question',
      message: 'This will permanently remove the question from the bank.',
      confirmLabel: 'Delete',
    );
    if (!confirmed || !mounted) return;
    try {
      await deleteQuestion(item.id);
      _full.remove(item.id);
      if (!mounted) return;
      AppDialogs.showSnack(context, 'Question deleted');
      await _load();
    } catch (e) {
      if (!mounted) return;
      AppDialogs.showSnack(context, AppDialogs.friendlyError(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<Session>().user?.isAdmin ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
          child: Row(
            children: [
              IconButton(
                onPressed: () => FeatureNavigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_rounded),
                color: AppColors.textDark,
                tooltip: 'Back',
              ),
              const SizedBox(width: 4),
              const Expanded(
                child: Text(
                  'Question Bank',
                  style: TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textDark),
                ),
              ),
              FilledButton.icon(
                onPressed: _saving ? null : () => _openForm(),
                style: FilledButton.styleFrom(
                  backgroundColor: ExperimentPalette.survey,
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Question'),
              ),
            ],
          ),
        ),
        Expanded(
          child: Builder(builder: (context) {
            if (!isAdmin) {
              return const EmptyState(
                icon: Icons.lock_rounded,
                title: 'Admins only',
                subtitle: 'You need an administrator account to manage the question bank.',
              );
            }
            if (_loading) {
              return const LoadingWidget(message: 'Loading question bank…');
            }
            if (_error != null) {
              return ErrorWidgetView(message: _error!, onRetry: _load);
            }
            final stats = _stats;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (stats != null) ...[
                    _StatsRow(stats: stats),
                    if (stats.questionTypes.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final entry in stats.questionTypes.entries)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: ExperimentPalette.survey.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${Formatters.enumLabel(entry.key)} • ${entry.value}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0F766E)),
                              ),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 20),
                  ],
                  _FiltersRow(
                    type: _type,
                    difficulty: _difficulty,
                    search: _search,
                    types: _types,
                    difficulties: _difficulties,
                    onTypeChanged: (v) => _onFilterChanged(type: v),
                    onDifficultyChanged: (v) => _onFilterChanged(difficulty: v),
                    onSearchChanged: (v) {
                      setState(() => _search = v);
                      _loadItems();
                    },
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Text(
                        'Questions',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textDark),
                      ),
                      const Spacer(),
                      Text(
                        '$_total shown',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_items.isEmpty)
                    const EmptyState(
                      icon: Icons.quiz_outlined,
                      title: 'No questions found',
                      subtitle: 'Try changing the filters or add a new question.',
                    )
                  else
                    for (final item in _items) ...[
                      _QuestionTile(
                        question: item,
                        onEdit: () => _openForm(existing: _adminViewOf(item)),
                        onDelete: () => _deleteQuestion(item),
                      ),
                      const SizedBox(height: 12),
                    ],
                  const SizedBox(height: 28),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  final AdminQuestionStats stats;

  const _StatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 620;
        final cardWidth = wide ? (constraints.maxWidth - 24) / 3 : constraints.maxWidth;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: cardWidth,
              child: StatCard(
                label: 'Total Questions',
                value: stats.totalQuestions.toDouble(),
                icon: Icons.quiz_rounded,
                color: ExperimentPalette.survey,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: StatCard(
                label: 'Total Attempts',
                value: stats.totalAttempts.toDouble(),
                icon: Icons.fact_check_rounded,
                color: const Color(0xFF4F46E5),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: StatCard(
                label: 'Average Score',
                value: stats.avgScore,
                suffix: '%',
                icon: Icons.insights_rounded,
                color: const Color(0xFFF59E0B),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FiltersRow extends StatelessWidget {
  final String type;
  final String difficulty;
  final String search;
  final List<String> types;
  final List<String> difficulties;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<String> onDifficultyChanged;
  final ValueChanged<String> onSearchChanged;

  const _FiltersRow({
    required this.type,
    required this.difficulty,
    required this.search,
    required this.types,
    required this.difficulties,
    required this.onTypeChanged,
    required this.onDifficultyChanged,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 640;
        final dropdownWidth = wide ? 180.0 : 140.0;
        final row = Row(
          children: [
            SizedBox(
              width: dropdownWidth,
              child: DropdownButtonFormField<String>(
                initialValue: type,
                decoration: const InputDecoration(
                  labelText: 'Type',
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final t in types)
                    DropdownMenuItem(
                        value: t,
                        child: Text(
                            t == 'ALL' ? 'All types' : Formatters.enumLabel(t),
                            style: const TextStyle(fontSize: 13.5))),
                ],
                onChanged: (v) {
                  if (v != null) onTypeChanged(v);
                },
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: dropdownWidth,
              child: DropdownButtonFormField<String>(
                initialValue: difficulty,
                decoration: const InputDecoration(
                  labelText: 'Difficulty',
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final d in difficulties)
                    DropdownMenuItem(
                        value: d,
                        child: Text(
                            d == 'ALL' ? 'All levels' : Formatters.titleCase(d),
                            style: const TextStyle(fontSize: 13.5))),
                ],
                onChanged: (v) {
                  if (v != null) onDifficultyChanged(v);
                },
              ),
            ),
          ],
        );
        final searchField = TextField(
          onChanged: onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Search questions…',
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            isDense: true,
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE6E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE6E8F0)),
            ),
          ),
        );
        if (wide) {
          return Row(
            children: [
              Expanded(child: row),
              const SizedBox(width: 16),
              SizedBox(width: 280, child: searchField),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            row,
            const SizedBox(height: 12),
            searchField,
          ],
        );
      },
    );
  }
}

class _QuestionTile extends StatelessWidget {
  final SurveyQuestion question;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _QuestionTile({
    required this.question,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final meta = question.isMcq
        ? '${question.options.length} options'
        : question.isTrueFalse
            ? 'True / False'
            : 'Short answer';
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
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: ExperimentPalette.survey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  question.isMcq
                      ? Icons.list_alt_rounded
                      : question.isTrueFalse
                          ? Icons.flag_rounded
                          : Icons.short_text_rounded,
                  size: 20,
                  color: ExperimentPalette.survey,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  question.text,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600, height: 1.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Flexible(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    StatusChip(status: question.type),
                    StatusChip(status: question.difficulty),
                    Text(meta,
                        style:
                            TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  ],
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: onEdit,
                tooltip: 'Edit',
                visualDensity: VisualDensity.compact,
                color: const Color(0xFF4F46E5),
                icon: const Icon(Icons.edit_rounded, size: 19),
              ),
              IconButton(
                onPressed: onDelete,
                tooltip: 'Delete',
                visualDensity: VisualDensity.compact,
                color: const Color(0xFFEF4444),
                icon: const Icon(Icons.delete_outline_rounded, size: 19),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuestionFormDialog extends StatefulWidget {
  final AdminQuestion? existing;

  const _QuestionFormDialog({this.existing});

  @override
  State<_QuestionFormDialog> createState() => _QuestionFormDialogState();
}

class _QuestionFormDialogState extends State<_QuestionFormDialog> {
  late final TextEditingController _textCtrl;
  late final TextEditingController _answerCtrl;
  late final TextEditingController _explanationCtrl;
  late final List<TextEditingController> _optionCtrls;
  late String _type;
  late String _difficulty;
  String? _error;

  static const List<String> _types = ['MCQ', 'TRUE_FALSE', 'SHORT_ANSWER'];
  static const List<String> _difficulties = ['EASY', 'MEDIUM', 'HARD'];

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _textCtrl = TextEditingController(text: existing?.text ?? '');
    _answerCtrl = TextEditingController(text: existing?.correctAnswer ?? '');
    _explanationCtrl = TextEditingController(text: existing?.explanation ?? '');
    _type = existing?.type ?? 'MCQ';
    _difficulty = existing?.difficulty ?? 'MEDIUM';
    final options = existing?.options ?? const <String>[];
    _optionCtrls = [
      for (final option in options) TextEditingController(text: option),
    ];
    if (options.isEmpty) _optionCtrls.add(TextEditingController());
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _answerCtrl.dispose();
    _explanationCtrl.dispose();
    for (final ctrl in _optionCtrls) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    setState(() => _optionCtrls.add(TextEditingController()));
  }

  void _removeOption(int index) {
    setState(() {
      _optionCtrls.removeAt(index).dispose();
    });
  }

  void _setError(String message) {
    setState(() => _error = message);
  }

  void _save() {
    final text = _textCtrl.text.trim();
    if (text.length < 5) {
      _setError('Question text must be at least 5 characters.');
      return;
    }
    final options = _optionCtrls
        .map((c) => c.text.trim())
        .where((o) => o.isNotEmpty)
        .toList();
    final correctAnswer = _answerCtrl.text.trim();
    final explanation = _explanationCtrl.text.trim();

    if (_type == 'MCQ') {
      if (options.length < 2) {
        _setError('MCQ questions require at least 2 options.');
        return;
      }
      if (correctAnswer.isNotEmpty && !options.contains(correctAnswer)) {
        _setError('Correct answer must be one of the options.');
        return;
      }
      if (!_isEdit && !options.contains(correctAnswer)) {
        _setError('Correct answer must be one of the options.');
        return;
      }
    } else if (_type == 'TRUE_FALSE') {
      final normalized = correctAnswer.toUpperCase();
      if (correctAnswer.isNotEmpty && normalized != 'TRUE' && normalized != 'FALSE') {
        _setError('Correct answer must be TRUE or FALSE.');
        return;
      }
      if (!_isEdit && normalized != 'TRUE' && normalized != 'FALSE') {
        _setError('Correct answer must be TRUE or FALSE.');
        return;
      }
    } else if (!_isEdit && correctAnswer.isEmpty) {
      _setError('Correct answer is required.');
      return;
    }

    final payload = <String, dynamic>{
      'text': text,
      'type': _type,
      'options': options,
      'difficulty': _difficulty,
      if (_type == 'MCQ') ...{
        'correct_answer': _isEdit && correctAnswer.isEmpty ? null : correctAnswer,
      },
      if (_type == 'TRUE_FALSE') ...{
        'correct_answer':
            _isEdit && correctAnswer.isEmpty ? null : correctAnswer.toUpperCase(),
      },
      if (_type == 'SHORT_ANSWER') ...{
        'correct_answer': correctAnswer,
      },
      if (explanation.isNotEmpty || !_isEdit) 'explanation': explanation,
    };
    payload.removeWhere((key, value) => value == null);
    Navigator.of(context).pop(payload);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Edit Question' : 'Add Question'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_error != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 12.5),
                ),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _textCtrl,
              maxLines: 2,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Question text',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _type,
                    decoration: const InputDecoration(
                      labelText: 'Type',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      for (final t in _types)
                        DropdownMenuItem(
                            value: t,
                            child: Text(
                                t == 'TRUE_FALSE' ? 'True / False' : Formatters.enumLabel(t),
                                style: const TextStyle(fontSize: 13.5))),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _type = v);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _difficulty,
                    decoration: const InputDecoration(
                      labelText: 'Difficulty',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      for (final d in _difficulties)
                        DropdownMenuItem(
                            value: d,
                            child: Text(Formatters.titleCase(d),
                                style: const TextStyle(fontSize: 13.5))),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _difficulty = v);
                    },
                  ),
                ),
              ],
            ),
            if (_type == 'MCQ') ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  const Text('Options',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _addOption,
                    icon: const Icon(Icons.add_rounded, size: 17),
                    label: const Text('Add option'),
                  ),
                ],
              ),
              for (var i = 0; i < _optionCtrls.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _optionCtrls[i],
                          decoration: InputDecoration(
                            labelText: 'Option ${i + 1}',
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      if (_optionCtrls.length > 1)
                        IconButton(
                          onPressed: () => _removeOption(i),
                          tooltip: 'Remove option',
                          visualDensity: VisualDensity.compact,
                          color: const Color(0xFFEF4444),
                          icon: const Icon(Icons.remove_circle_outline_rounded,
                              size: 19),
                        ),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: 10),
            TextField(
              controller: _answerCtrl,
              decoration: InputDecoration(
                labelText: _type == 'TRUE_FALSE'
                    ? 'Correct answer (TRUE / FALSE)'
                    : 'Correct answer',
                hintText: _type == 'MCQ'
                    ? 'One of the options above'
                    : _type == 'TRUE_FALSE'
                        ? 'TRUE or FALSE'
                        : 'Expected answer',
                helperText: _isEdit && (widget.existing?.correctAnswer == null)
                    ? 'Leave blank to keep the current answer.'
                    : null,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _explanationCtrl,
              maxLines: 3,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Explanation (optional)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          style: FilledButton.styleFrom(backgroundColor: ExperimentPalette.survey),
          child: Text(_isEdit ? 'Save Changes' : 'Create'),
        ),
      ],
    );
  }
}