import 'survey_question.dart';

class SurveyStart {
  final String attemptId;
  final List<SurveyQuestion> questions;

  const SurveyStart({required this.attemptId, this.questions = const []});

  factory SurveyStart.fromJson(Map<String, dynamic> json) => SurveyStart(
        attemptId: (json['attempt_id'] ?? '').toString(),
        questions: ((json['questions'] as List?) ?? const [])
            .map((q) => SurveyQuestion.fromJson(q as Map<String, dynamic>))
            .toList(),
      );
}

class SurveyAnswerDetail {
  final String questionId;
  final String questionText;
  final String questionType;
  final String givenAnswer;
  final String correctAnswer;
  final bool isCorrect;
  final bool isScored;
  final String explanation;

  const SurveyAnswerDetail({
    required this.questionId,
    required this.questionText,
    this.questionType = 'MCQ',
    this.givenAnswer = '',
    this.correctAnswer = '',
    this.isCorrect = false,
    this.isScored = true,
    this.explanation = '',
  });

  factory SurveyAnswerDetail.fromJson(Map<String, dynamic> json) =>
      SurveyAnswerDetail(
        questionId: (json['question_id'] ?? '').toString(),
        questionText: (json['question_text'] ?? '').toString(),
        questionType: (json['question_type'] ?? 'MCQ').toString().toUpperCase(),
        givenAnswer: (json['given_answer'] ?? '').toString(),
        correctAnswer: (json['correct_answer'] ?? '').toString(),
        isCorrect: json['is_correct'] == true,
        isScored: json['is_scored'] == true,
        explanation: (json['explanation'] ?? '').toString(),
      );
}

class SurveyAttemptResult {
  final String id;
  final String status;
  final int? score;
  final double? scorePercentage;
  final String? startedAt;
  final String? completedAt;
  final int? totalScored;
  final List<SurveyAnswerDetail> details;

  const SurveyAttemptResult({
    required this.id,
    this.status = 'IN_PROGRESS',
    this.score,
    this.scorePercentage,
    this.startedAt,
    this.completedAt,
    this.totalScored,
    this.details = const [],
  });

  factory SurveyAttemptResult.fromJson(Map<String, dynamic> json) =>
      SurveyAttemptResult(
        id: (json['id'] ?? '').toString(),
        status: (json['status'] ?? 'IN_PROGRESS').toString().toUpperCase(),
        score: (json['score'] as num?)?.toInt(),
        scorePercentage: (json['score_percentage'] as num?)?.toDouble(),
        startedAt: json['started_at']?.toString(),
        completedAt: json['completed_at']?.toString(),
        totalScored: (json['total_scored'] as num?)?.toInt(),
        details: ((json['details'] as List?) ?? const [])
            .map((d) => SurveyAnswerDetail.fromJson(d as Map<String, dynamic>))
            .toList(),
      );
}

class SurveyHistoryEntry {
  final String id;
  final String status;
  final int? score;
  final double? scorePercentage;
  final int? totalScored;
  final String? startedAt;
  final String? completedAt;

  const SurveyHistoryEntry({
    required this.id,
    this.status = 'IN_PROGRESS',
    this.score,
    this.scorePercentage,
    this.totalScored,
    this.startedAt,
    this.completedAt,
  });

  bool get isCompleted => status == 'COMPLETED';

  factory SurveyHistoryEntry.fromJson(Map<String, dynamic> json) =>
      SurveyHistoryEntry(
        id: (json['id'] ?? '').toString(),
        status: (json['status'] ?? 'IN_PROGRESS').toString().toUpperCase(),
        score: (json['score'] as num?)?.toInt(),
        scorePercentage: (json['score_percentage'] as num?)?.toDouble(),
        totalScored: (json['total_scored'] as num?)?.toInt(),
        startedAt: json['started_at']?.toString(),
        completedAt: json['completed_at']?.toString(),
      );
}

class SurveyStats {
  final int attempts;
  final double best;
  final double average;

  const SurveyStats({
    this.attempts = 0,
    this.best = 0,
    this.average = 0,
  });

  factory SurveyStats.fromJson(Map<String, dynamic> json) => SurveyStats(
        attempts: (json['attempts'] as num?)?.toInt() ?? 0,
        best: (json['best'] as num?)?.toDouble() ?? 0,
        average: (json['average'] as num?)?.toDouble() ?? 0,
      );
}
