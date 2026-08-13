import 'package:flutter/material.dart';

/// Widget for rendering math expressions with proper formatting.
/// Handles inline math rendering with styled text.
class MathText extends StatelessWidget {
  final String expression;
  final double fontSize;
  final Color? color;
  final FontWeight fontWeight;

  const MathText({
    super.key,
    required this.expression,
    this.fontSize = 16,
    this.color,
    this.fontWeight = FontWeight.w500,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = color ?? Colors.white;

    return Text(
      _formatMathText(expression),
      style: TextStyle(
        color: textColor,
        fontSize: fontSize,
        fontFamily: 'monospace',
        fontWeight: fontWeight,
        height: 1.4,
      ),
    );
  }

  /// Format math text with proper Unicode symbols for display.
  String _formatMathText(String text) {
    String formatted = text;

    // Convert text notation back to display symbols
    formatted = formatted.replaceAll('^2', '\u00B2');
    formatted = formatted.replaceAll('^3', '\u00B3');
    formatted = formatted.replaceAll('sqrt(', '\u221A(');
    formatted = formatted.replaceAll('pi', '\u03C0');
    formatted = formatted.replaceAll('infinity', '\u221E');
    formatted = formatted.replaceAll('<=', '\u2264');
    formatted = formatted.replaceAll('>=', '\u2265');
    formatted = formatted.replaceAll('!=', '\u2260');

    return formatted;
  }
}

/// Widget for displaying a step with numbered indicator and content.
class StepWidget extends StatelessWidget {
  final int stepNumber;
  final String title;
  final String content;
  final String? formula;
  final bool isLast;

  const StepWidget({
    super.key,
    required this.stepNumber,
    required this.title,
    required this.content,
    this.formula,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step number badge
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: isLast
                  ? Colors.green.withOpacity(0.2)
                  : Colors.deepPurple.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color:
                    isLast ? Colors.green.shade400 : Colors.deepPurple.shade300,
              ),
            ),
            child: Center(
              child: isLast
                  ? Icon(Icons.check, size: 14, color: Colors.green.shade300)
                  : Text(
                      '$stepNumber',
                      style: TextStyle(
                        color: Colors.deepPurple.shade200,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          // Step content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                if (formula != null && formula!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  MathText(
                    expression: formula!,
                    fontSize: 14,
                    color: Colors.deepPurple.shade200,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
