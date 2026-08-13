class MathQuestion {
  final String id;
  final String rawText;
  final String parsedExpression;
  final String type;
  final String variable;
  final DateTime scannedAt;

  MathQuestion({
    required this.id,
    required this.rawText,
    required this.parsedExpression,
    this.type = 'unknown',
    this.variable = 'x',
    DateTime? scannedAt,
  }) : scannedAt = scannedAt ?? DateTime.now();

  factory MathQuestion.fromJson(Map<String, dynamic> json) {
    return MathQuestion(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      rawText: json['rawText'] ?? '',
      parsedExpression: json['parsedExpression'] ?? json['rawText'] ?? '',
      type: json['type'] ?? 'unknown',
      variable: json['variable'] ?? 'x',
      scannedAt: json['scannedAt'] != null
          ? DateTime.parse(json['scannedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rawText': rawText,
      'parsedExpression': parsedExpression,
      'type': type,
      'variable': variable,
      'scannedAt': scannedAt.toIso8601String(),
    };
  }

  MathQuestion copyWith({
    String? rawText,
    String? parsedExpression,
    String? type,
    String? variable,
  }) {
    return MathQuestion(
      id: id,
      rawText: rawText ?? this.rawText,
      parsedExpression: parsedExpression ?? this.parsedExpression,
      type: type ?? this.type,
      variable: variable ?? this.variable,
      scannedAt: scannedAt,
    );
  }
}
