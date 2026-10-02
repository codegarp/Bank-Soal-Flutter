class QuestionOption {
  final String key; // 'A', 'B', 'C', 'D', 'E'
  final String text;

  const QuestionOption({
    required this.key,
    required this.text,
  });

  Map<String, dynamic> toJson() => {
    'key': key,
    'text': text,
  };

  factory QuestionOption.fromJson(Map<String, dynamic> json) => QuestionOption(
    key: json['key']?.toString() ?? '',
    text: json['text']?.toString() ?? '',
  );

  QuestionOption copyWith({String? key, String? text}) => QuestionOption(
    key: key ?? this.key,
    text: text ?? this.text,
  );
}

class QuestionModel {
  final int number;
  final String questionText;
  final String questionType; // 'PG', 'Essay', 'Isian'
  final List<QuestionOption> options;
  final String correctAnswer; // e.g. 'A', 'B' or string for essay
  final String explanation; // Pembahasan lengkap
  final String difficulty; // 'Mudah', 'Sedang', 'Sulit', 'HOTS'
  final String topic; // Materi spesifik

  const QuestionModel({
    required this.number,
    required this.questionText,
    this.questionType = 'PG',
    this.options = const [],
    required this.correctAnswer,
    required this.explanation,
    this.difficulty = 'Sedang',
    this.topic = '',
  });

  bool get isMultipleChoice => questionType.toUpperCase().contains('PG') || options.isNotEmpty;

  QuestionModel copyWith({
    int? number,
    String? questionText,
    String? questionType,
    List<QuestionOption>? options,
    String? correctAnswer,
    String? explanation,
    String? difficulty,
    String? topic,
  }) {
    return QuestionModel(
      number: number ?? this.number,
      questionText: questionText ?? this.questionText,
      questionType: questionType ?? this.questionType,
      options: options ?? this.options,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      explanation: explanation ?? this.explanation,
      difficulty: difficulty ?? this.difficulty,
      topic: topic ?? this.topic,
    );
  }

  Map<String, dynamic> toJson() => {
    'number': number,
    'questionText': questionText,
    'questionType': questionType,
    'options': options.map((o) => o.toJson()).toList(),
    'correctAnswer': correctAnswer,
    'explanation': explanation,
    'difficulty': difficulty,
    'topic': topic,
  };

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    List<QuestionOption> opts = [];
    if (json['options'] != null && json['options'] is List) {
      opts = (json['options'] as List).map((o) {
        if (o is Map<String, dynamic>) {
          return QuestionOption.fromJson(o);
        } else if (o is String) {
          // If option is string like "A. Jawaban..."
          final trimmed = o.trim();
          if (trimmed.length > 2 && trimmed[1] == '.') {
            return QuestionOption(
              key: trimmed.substring(0, 1).toUpperCase(),
              text: trimmed.substring(2).trim(),
            );
          }
          return QuestionOption(key: '', text: o);
        }
        return QuestionOption(key: '', text: o.toString());
      }).toList();
    }

    return QuestionModel(
      number: json['number'] is int ? json['number'] : int.tryParse(json['number']?.toString() ?? '1') ?? 1,
      questionText: json['questionText']?.toString() ?? json['question']?.toString() ?? '',
      questionType: json['questionType']?.toString() ?? (opts.isNotEmpty ? 'PG' : 'Essay'),
      options: opts,
      correctAnswer: json['correctAnswer']?.toString() ?? json['answer']?.toString() ?? '',
      explanation: json['explanation']?.toString() ?? json['pembahasan']?.toString() ?? '',
      difficulty: json['difficulty']?.toString() ?? json['tingkat_kesulitan']?.toString() ?? 'Sedang',
      topic: json['topic']?.toString() ?? json['materi']?.toString() ?? '',
    );
  }
}
