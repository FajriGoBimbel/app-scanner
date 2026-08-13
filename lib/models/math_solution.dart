class SolutionStep {
  final int stepNumber;
  final String title;
  final String content;
  final String? formula;

  const SolutionStep({
    required this.stepNumber,
    required this.title,
    required this.content,
    this.formula,
  });

  factory SolutionStep.fromJson(Map<String, dynamic> json) {
    return SolutionStep(
      stepNumber: json['stepNumber'] ?? 0,
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      formula: json['formula'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stepNumber': stepNumber,
      'title': title,
      'content': content,
      'formula': formula,
    };
  }
}

enum ExplanationLevel {
  singkat,
  detail,
  tutor,
}

class MathSolution {
  final String questionId;
  final String question;
  final List<String> answers;
  final String method;
  final List<SolutionStep> steps;
  final String? concept;
  final DateTime solvedAt;

  MathSolution({
    required this.questionId,
    required this.question,
    required this.answers,
    required this.method,
    required this.steps,
    this.concept,
    DateTime? solvedAt,
  }) : solvedAt = solvedAt ?? DateTime.now();

  factory MathSolution.fromJson(Map<String, dynamic> json) {
    return MathSolution(
      questionId: json['questionId'] ?? '',
      question: json['question'] ?? '',
      answers: List<String>.from(json['answer'] ?? json['answers'] ?? []),
      method: json['method'] ?? '',
      steps: (json['steps'] as List<dynamic>?)
              ?.map((s) => SolutionStep.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      concept: json['concept'],
      solvedAt: json['solvedAt'] != null
          ? DateTime.parse(json['solvedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'question': question,
      'answers': answers,
      'method': method,
      'steps': steps.map((s) => s.toJson()).toList(),
      'concept': concept,
      'solvedAt': solvedAt.toIso8601String(),
    };
  }
}
