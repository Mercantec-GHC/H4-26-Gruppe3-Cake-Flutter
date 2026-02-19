/// Quiz question retrieved from API
class QuizQuestion {
  final String questionText;
  final int type;
  final List<QuizOption> options;

  QuizQuestion({
    required this.questionText,
    required this.type,
    required this.options,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      questionText: json['questionText'] ?? '',
      type: json['type'] ?? 0,
      options: (json['options'] as List<dynamic>?)
              ?.map((o) => QuizOption.fromJson(o))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questionText': questionText,
      'type': type,
      'options': options.map((o) => o.toJson()).toList(),
    };
  }
}

/// Quiz answer option
class QuizOption {
  final String text;

  QuizOption({required this.text});

  factory QuizOption.fromJson(Map<String, dynamic> json) {
    return QuizOption(
      text: json['text'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
    };
  }
}
