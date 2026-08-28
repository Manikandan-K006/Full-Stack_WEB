import '../../../core/network/api_client.dart';
import '../models/admin_question.dart';
import '../models/survey_attempt.dart';
import '../models/survey_question.dart';

const String _surveyPath = '/api/survey';
const String _questionsPath = '/api/questions';
const String _adminQuestionsPath = '/api/admin/questions';

Future<SurveyStart> startSurvey() async {
  final data =
      await ApiClient.instance.get('$_surveyPath/start') as Map<String, dynamic>;
  return SurveyStart.fromJson(data);
}

Future<SurveyAttemptResult> submitSurvey({
  required String attemptId,
  required Map<String, String> answers,
}) async {
  final data = await ApiClient.instance.post('$_surveyPath/submit', body: {
    'attempt_id': attemptId,
    'answers': [
      for (final entry in answers.entries)
        {'question_id': entry.key, 'answer': entry.value},
    ],
  }) as Map<String, dynamic>;
  return SurveyAttemptResult.fromJson(data);
}

Future<SurveyAttemptResult> fetchAttemptResult(String attemptId) async {
  final data = await ApiClient.instance
      .get('$_surveyPath/results', query: {'attempt_id': attemptId}) as Map<String, dynamic>;
  return SurveyAttemptResult.fromJson(data);
}

Future<({List<SurveyHistoryEntry> history, SurveyStats stats})> fetchHistory() async {
  final data =
      await ApiClient.instance.get('$_surveyPath/history') as Map<String, dynamic>;
  final history = ((data['history'] as List?) ?? const [])
      .map((a) => SurveyHistoryEntry.fromJson(a as Map<String, dynamic>))
      .toList();
  final stats =
      SurveyStats.fromJson((data['stats'] as Map<String, dynamic>?) ?? const {});
  return (history: history, stats: stats);
}

Future<({List<SurveyQuestion> items, int total})> fetchQuestionBank({
  String? type,
  String? difficulty,
  String? search,
}) async {
  final data = await ApiClient.instance.get(_questionsPath, query: {
    if (type != null && type != 'ALL') 'qtype': type,
    if (difficulty != null && difficulty != 'ALL') 'difficulty': difficulty,
    if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
  }) as Map<String, dynamic>;
  final items = ((data['items'] as List?) ?? const [])
      .map((q) => SurveyQuestion.fromJson(q as Map<String, dynamic>))
      .toList();
  return (items: items, total: (data['total'] as num?)?.toInt() ?? items.length);
}

Future<AdminQuestionStats> fetchQuestionStats() async {
  final data =
      await ApiClient.instance.get('$_questionsPath/stats') as Map<String, dynamic>;
  return AdminQuestionStats.fromJson(data);
}

Future<AdminQuestion> createQuestion(Map<String, dynamic> payload) async {
  final data = await ApiClient.instance
      .post(_adminQuestionsPath, body: payload) as Map<String, dynamic>;
  return AdminQuestion.fromJson(data);
}

Future<AdminQuestion> updateQuestion(String id, Map<String, dynamic> payload) async {
  final data = await ApiClient.instance
      .put('$_adminQuestionsPath/$id', body: payload) as Map<String, dynamic>;
  return AdminQuestion.fromJson(data);
}

Future<void> deleteQuestion(String id) async {
  await ApiClient.instance.delete('$_adminQuestionsPath/$id');
}
