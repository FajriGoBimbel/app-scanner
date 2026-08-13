import 'package:dio/dio.dart';
import '../models/math_question.dart';
import '../models/math_solution.dart';

/// Service that handles math solving and AI explanation generation.
/// 
/// Architecture:
///   Math OCR → Math Parser → Math Solver → AI Explanation
/// 
/// For MVP, this uses an AI API endpoint to both solve and explain.
/// In production, a dedicated backend would separate concerns.
class MathService {
  final Dio _dio;
  
  // Configure your API endpoint here
  static const String _baseUrl = 'https://api.openai.com/v1';
  static const String _apiKey = ''; // Set via environment or config

  MathService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: _baseUrl,
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 60),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $_apiKey',
              },
            ));

  /// Parse the raw OCR text into a structured MathQuestion.
  MathQuestion parseQuestion(String rawText) {
    final expression = rawText.trim();
    final type = _detectQuestionType(expression);
    final variable = _detectVariable(expression);

    return MathQuestion(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      rawText: rawText,
      parsedExpression: expression,
      type: type,
      variable: variable,
    );
  }

  /// Solve the math question and generate step-by-step explanation.
  Future<MathSolution> solve(
    MathQuestion question, {
    ExplanationLevel level = ExplanationLevel.detail,
  }) async {
    try {
      final prompt = _buildPrompt(question, level);
      final response = await _callAI(prompt);
      return _parseAIResponse(question, response);
    } catch (e) {
      // Fallback: return a basic solution with error info
      return _createFallbackSolution(question, e.toString());
    }
  }

  /// Build prompt for the AI based on question and explanation level.
  String _buildPrompt(MathQuestion question, ExplanationLevel level) {
    final levelInstruction = switch (level) {
      ExplanationLevel.singkat =>
        'Berikan jawaban singkat dengan langkah-langkah minimal.',
      ExplanationLevel.detail =>
        'Berikan penjelasan detail setiap langkah penyelesaian.',
      ExplanationLevel.tutor =>
        'Jelaskan seperti seorang guru/tutor. Sertakan konsep matematika yang digunakan dan alasan setiap langkah.',
    };

    return '''
Kamu adalah tutor matematika AI. Selesaikan soal berikut dan berikan penjelasan langkah demi langkah dalam Bahasa Indonesia.

Soal: ${question.parsedExpression}

$levelInstruction

Format jawaban dalam JSON:
{
  "question": "soal yang dibaca",
  "answer": ["jawaban1", "jawaban2"],
  "method": "metode yang digunakan",
  "concept": "konsep matematika yang digunakan",
  "steps": [
    {
      "stepNumber": 1,
      "title": "Judul langkah",
      "content": "Penjelasan langkah",
      "formula": "rumus jika ada"
    }
  ]
}
''';
  }

  /// Call the AI API to get solution.
  Future<String> _callAI(String prompt) async {
    try {
      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'system',
              'content':
                  'Kamu adalah tutor matematika AI yang ahli. Selalu jawab dalam format JSON yang valid. Gunakan Bahasa Indonesia.',
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'temperature': 0.2,
          'max_tokens': 2000,
        },
      );

      final content =
          response.data['choices'][0]['message']['content'] as String;
      return content;
    } catch (e) {
      throw MathServiceException('AI API Error: $e');
    }
  }

  /// Parse the AI response JSON into a MathSolution.
  MathSolution _parseAIResponse(MathQuestion question, String response) {
    try {
      // Extract JSON from response (AI might wrap it in markdown code blocks)
      String jsonStr = response;
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
      if (jsonMatch != null) {
        jsonStr = jsonMatch.group(0)!;
      }

      // Parse using dart:convert would be imported at top in real usage
      // For now, we create a manual parse approach
      // In production, use json.decode(jsonStr)
      
      // Simplified: return the AI-generated solution
      return MathSolution(
        questionId: question.id,
        question: question.parsedExpression,
        answers: _extractAnswers(jsonStr),
        method: _extractField(jsonStr, 'method'),
        steps: _extractSteps(jsonStr),
        concept: _extractField(jsonStr, 'concept'),
      );
    } catch (e) {
      return _createFallbackSolution(question, 'Parse error: $e');
    }
  }

  /// Create a fallback solution when AI is unavailable.
  /// Uses basic local solving for simple expressions.
  MathSolution _createFallbackSolution(MathQuestion question, String error) {
    // Try local solving for basic math
    final localResult = _tryLocalSolve(question);
    if (localResult != null) return localResult;

    return MathSolution(
      questionId: question.id,
      question: question.parsedExpression,
      answers: ['Tidak dapat menyelesaikan saat ini'],
      method: 'error',
      steps: [
        SolutionStep(
          stepNumber: 1,
          title: 'Error',
          content:
              'Tidak dapat terhubung ke server. Pastikan koneksi internet aktif.\nDetail: $error',
        ),
      ],
    );
  }

  /// Try to solve simple expressions locally without AI.
  MathSolution? _tryLocalSolve(MathQuestion question) {
    final expr = question.parsedExpression;

    // Simple linear equation: ax + b = c
    final linearMatch =
        RegExp(r'(-?\d*)x\s*([+-]\s*\d+)\s*=\s*(-?\d+)').firstMatch(expr);
    if (linearMatch != null) {
      return _solveLinearEquation(question, linearMatch);
    }

    // Simple arithmetic: a + b, a - b, a * b, a / b
    final arithmeticMatch =
        RegExp(r'(-?\d+\.?\d*)\s*([+\-*/])\s*(-?\d+\.?\d*)').firstMatch(expr);
    if (arithmeticMatch != null) {
      return _solveArithmetic(question, arithmeticMatch);
    }

    return null;
  }

  /// Solve a simple linear equation locally.
  MathSolution? _solveLinearEquation(MathQuestion question, RegExpMatch match) {
    try {
      final aStr = match.group(1)!;
      final a = aStr.isEmpty || aStr == '+' ? 1 : (aStr == '-' ? -1 : int.parse(aStr));
      final b = int.parse(match.group(2)!.replaceAll(' ', ''));
      final c = int.parse(match.group(3)!);

      final result = (c - b) / a;
      final resultStr = result == result.toInt()
          ? result.toInt().toString()
          : result.toStringAsFixed(2);

      return MathSolution(
        questionId: question.id,
        question: question.parsedExpression,
        answers: ['x = $resultStr'],
        method: 'persamaan_linear',
        steps: [
          SolutionStep(
            stepNumber: 1,
            title: 'Pindahkan konstanta',
            content:
                'Kurangkan $b pada kedua ruas.\n${a}x + $b - $b = $c - $b\n${a}x = ${c - b}',
          ),
          SolutionStep(
            stepNumber: 2,
            title: 'Bagi kedua ruas',
            content:
                'Bagi kedua ruas dengan $a.\n${a}x / $a = ${c - b} / $a\nx = $resultStr',
          ),
          SolutionStep(
            stepNumber: 3,
            title: 'Jawaban',
            content: 'Jadi, x = $resultStr',
          ),
        ],
        concept: 'Persamaan Linear Satu Variabel',
      );
    } catch (e) {
      return null;
    }
  }

  /// Solve basic arithmetic locally.
  MathSolution? _solveArithmetic(MathQuestion question, RegExpMatch match) {
    try {
      final a = double.parse(match.group(1)!);
      final op = match.group(2)!;
      final b = double.parse(match.group(3)!);

      double result;
      String method;
      switch (op) {
        case '+':
          result = a + b;
          method = 'penjumlahan';
          break;
        case '-':
          result = a - b;
          method = 'pengurangan';
          break;
        case '*':
          result = a * b;
          method = 'perkalian';
          break;
        case '/':
          if (b == 0) return null;
          result = a / b;
          method = 'pembagian';
          break;
        default:
          return null;
      }

      final resultStr = result == result.toInt()
          ? result.toInt().toString()
          : result.toStringAsFixed(2);

      return MathSolution(
        questionId: question.id,
        question: question.parsedExpression,
        answers: [resultStr],
        method: method,
        steps: [
          SolutionStep(
            stepNumber: 1,
            title: 'Hitung',
            content: '$a $op $b = $resultStr',
          ),
        ],
      );
    } catch (e) {
      return null;
    }
  }

  /// Detect the type of math question.
  String _detectQuestionType(String expression) {
    if (expression.contains('^2') || expression.contains('²')) {
      if (expression.contains('=')) return 'quadratic_equation';
      return 'quadratic_expression';
    }
    if (expression.contains('sqrt') || expression.contains('√')) {
      return 'radical';
    }
    if (expression.contains('sin') ||
        expression.contains('cos') ||
        expression.contains('tan')) {
      return 'trigonometry';
    }
    if (expression.contains('log') || expression.contains('ln')) {
      return 'logarithm';
    }
    if (expression.contains('lim')) {
      return 'limit';
    }
    if (expression.contains('∫') || expression.contains('integral')) {
      return 'integral';
    }
    if (RegExp(r'[a-z]\s*[+\-]\s*\d+\s*=').hasMatch(expression)) {
      return 'linear_equation';
    }
    if (RegExp(r'\d+\s*[+\-*/]\s*\d+').hasMatch(expression)) {
      return 'arithmetic';
    }
    return 'unknown';
  }

  /// Detect the main variable in the expression.
  String _detectVariable(String expression) {
    final variableMatch = RegExp(r'[a-z]').firstMatch(expression);
    return variableMatch?.group(0) ?? 'x';
  }

  // Helper methods for parsing AI response strings
  List<String> _extractAnswers(String json) {
    final match = RegExp(r'"answer"\s*:\s*\[(.*?)\]').firstMatch(json);
    if (match != null) {
      return match
          .group(1)!
          .split(',')
          .map((s) => s.trim().replaceAll('"', ''))
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return ['Jawaban tidak tersedia'];
  }

  String _extractField(String json, String field) {
    final match = RegExp('"$field"\\s*:\\s*"(.*?)"').firstMatch(json);
    return match?.group(1) ?? '';
  }

  List<SolutionStep> _extractSteps(String json) {
    final stepsMatch =
        RegExp(r'"steps"\s*:\s*\[([\s\S]*?)\]').firstMatch(json);
    if (stepsMatch == null) return [];

    final stepsContent = stepsMatch.group(1)!;
    final stepMatches =
        RegExp(r'\{([\s\S]*?)\}').allMatches(stepsContent);

    final steps = <SolutionStep>[];
    int index = 1;
    for (final stepMatch in stepMatches) {
      final stepStr = stepMatch.group(1)!;
      final title =
          RegExp(r'"title"\s*:\s*"(.*?)"').firstMatch(stepStr)?.group(1) ??
              'Langkah $index';
      final content =
          RegExp(r'"content"\s*:\s*"(.*?)"').firstMatch(stepStr)?.group(1) ??
              '';
      final formula =
          RegExp(r'"formula"\s*:\s*"(.*?)"').firstMatch(stepStr)?.group(1);

      steps.add(SolutionStep(
        stepNumber: index,
        title: title,
        content: content,
        formula: formula,
      ));
      index++;
    }

    return steps;
  }

  void dispose() {
    _dio.close();
  }
}

class MathServiceException implements Exception {
  final String message;
  MathServiceException(this.message);

  @override
  String toString() => 'MathServiceException: $message';
}
