import 'survey_attempt.dart';

class AdminQuestion {
  final String id;
  final String text;
  final String type;
  final List<String> options;
  final String difficulty;
  final String? correctAnswer;
  final String? explanation;
  final String? createdAt;

  const AdminQuestion({
    required this.id,
    required this.text,
    this.type = 'MCQ',
    this.options = const [],
    this.difficulty = 'MEDIUM',
    this.correctAnswer,
    this.explanation,
    this.createdAt,
  });

  factory AdminQuestion.fromJson(Map<String, dynamic> json) => AdminQuestion(
        id: (json['id'] ?? '').toString(),
        text: (json['text'] ?? '').toString(),
        type: (json['type'] ?? 'MCQ').toString().toUpperCase(),
        options: ((json['options'] as List?) ?? const [])
            .map((o) => o.toString())
            .toList(),
        difficulty: (json['difficulty'] ?? 'MEDIUM').toString().toUpperCase(),
        correctAnswer: json['correct_answer']?.toString(),
        explanation: json['explanation']?.toString(),
        createdAt: json['created_at']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'type': type,
        'options': options,
        'difficulty': difficulty,
        if (correctAnswer != null) 'correct_answer': correctAnswer,
        if (explanation != null) 'explanation': explanation,
        if (createdAt != null) 'created_at': createdAt,
      };

  Map<String, dynamic> toPayload() => {
        'text': text,
        'type': type,
        'options': options,
        'correct_answer': correctAnswer ?? '',
        'difficulty': difficulty,
        'explanation': explanation ?? '',
      };
}

class AdminQuestionStats {
  final int totalQuestions;
  final Map<String, int> questionTypes;
  final int totalAttempts;
  final double avgScore;
  final List<SurveyHistoryEntry> recent;

  const AdminQuestionStats({
    this.totalQuestions = 0,
    this.questionTypes = const {},
    this.totalAttempts = 0,
    this.avgScore = 0,
    this.recent = const [],
  });

  factory AdminQuestionStats.fromJson(Map<String, dynamic> json) =>
      AdminQuestionStats(
        totalQuestions: (json['total_questions'] as num?)?.toInt() ?? 0,
        questionTypes: (json['question_types'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, (v as num).toInt())) ??
            const {},
        totalAttempts: (json['total_attempts'] as num?)?.toInt() ?? 0,
        avgScore: (json['avg_score'] as num?)?.toDouble() ?? 0,
        recent: ((json['recent'] as List?) ?? const [])
            .map((a) => SurveyHistoryEntry.fromJson(a as Map<String, dynamic>))
            .toList(),
      );
}
