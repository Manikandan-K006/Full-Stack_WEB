class SurveyQuestion {
  final String id;
  final String text;
  final String type;
  final List<String> options;
  final String difficulty;

  const SurveyQuestion({
    required this.id,
    required this.text,
    this.type = 'MCQ',
    this.options = const [],
    this.difficulty = 'MEDIUM',
  });

  bool get isMcq => type == 'MCQ';
  bool get isTrueFalse => type == 'TRUE_FALSE';
  bool get isShortAnswer => type == 'SHORT_ANSWER';

  factory SurveyQuestion.fromJson(Map<String, dynamic> json) => SurveyQuestion(
        id: (json['id'] ?? '').toString(),
        text: (json['text'] ?? '').toString(),
        type: (json['type'] ?? 'MCQ').toString().toUpperCase(),
        options: ((json['options'] as List?) ?? const [])
            .map((o) => o.toString())
            .toList(),
        difficulty: (json['difficulty'] ?? 'MEDIUM').toString().toUpperCase(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'type': type,
        'options': options,
        'difficulty': difficulty,
      };
}
