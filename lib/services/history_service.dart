import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/math_question.dart';
import '../models/math_solution.dart';

/// Local history storage using SharedPreferences.
/// Stores scanned questions and their solutions on device.
class HistoryService {
  static const String _historyKey = 'math_history';
  static const int _maxHistoryItems = 100;

  /// Save a solved question to local history.
  Future<void> saveToHistory({
    required MathQuestion question,
    required MathSolution solution,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getHistory();

    final entry = {
      'question': question.toJson(),
      'solution': solution.toJson(),
      'timestamp': DateTime.now().toIso8601String(),
    };

    history.insert(0, entry);

    // Keep only last N items
    if (history.length > _maxHistoryItems) {
      history.removeRange(_maxHistoryItems, history.length);
    }

    await prefs.setString(_historyKey, jsonEncode(history));
  }

  /// Get all history entries.
  Future<List<Map<String, dynamic>>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_historyKey);

    if (historyJson == null || historyJson.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> decoded = jsonDecode(historyJson);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  /// Get history as structured objects.
  Future<List<HistoryEntry>> getHistoryEntries() async {
    final raw = await getHistory();
    return raw.map((e) => HistoryEntry.fromJson(e)).toList();
  }

  /// Clear all history.
  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }

  /// Delete a specific history entry by question ID.
  Future<void> deleteEntry(String questionId) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getHistory();

    history.removeWhere((entry) {
      final q = entry['question'] as Map<String, dynamic>?;
      return q?['id'] == questionId;
    });

    await prefs.setString(_historyKey, jsonEncode(history));
  }
}

class HistoryEntry {
  final MathQuestion question;
  final MathSolution solution;
  final DateTime timestamp;

  HistoryEntry({
    required this.question,
    required this.solution,
    required this.timestamp,
  });

  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    return HistoryEntry(
      question: MathQuestion.fromJson(json['question'] ?? {}),
      solution: MathSolution.fromJson(json['solution'] ?? {}),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }
}
