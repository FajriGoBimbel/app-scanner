import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Service for performing OCR optimized for mathematical expressions.
/// Uses Google ML Kit for on-device text recognition, then applies
/// math-specific post-processing to normalize symbols.
class OcrService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  /// Recognize text from an image file and return raw OCR result.
  Future<String> recognizeText(File imageFile) async {
    try {
      final InputImage inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText =
          await _textRecognizer.processImage(inputImage);

      return recognizedText.text;
    } catch (e) {
      print('OCR Error: $e');
      return '';
    }
  }

  /// Recognize and parse mathematical expression from image.
  /// Applies math-specific normalization after OCR.
  Future<String> recognizeMathExpression(File imageFile) async {
    final rawText = await recognizeText(imageFile);
    if (rawText.isEmpty) return '';

    return _normalizeMathExpression(rawText);
  }

  /// Normalize OCR output to standard math notation.
  /// Handles common OCR misreads and converts symbols.
  String _normalizeMathExpression(String raw) {
    String result = raw.trim();

    // Replace common Unicode math symbols with text equivalents
    result = result.replaceAll('²', '^2');
    result = result.replaceAll('³', '^3');
    result = result.replaceAll('⁴', '^4');
    result = result.replaceAll('⁵', '^5');
    result = result.replaceAll('√', 'sqrt');
    result = result.replaceAll('×', '*');
    result = result.replaceAll('÷', '/');
    result = result.replaceAll('·', '*');
    result = result.replaceAll('–', '-');
    result = result.replaceAll('—', '-');
    result = result.replaceAll('≤', '<=');
    result = result.replaceAll('≥', '>=');
    result = result.replaceAll('≠', '!=');
    result = result.replaceAll('π', 'pi');
    result = result.replaceAll('∞', 'infinity');

    // Fix common OCR misreads
    result = result.replaceAll('l', '1'); // lowercase L often misread
    result = result.replaceAll('O', '0'); // capital O often misread as zero
    // Only apply above when in numeric context — simplified for MVP

    // Normalize whitespace
    result = result.replaceAll(RegExp(r'\s+'), ' ');

    // Handle fraction-like patterns (line-based)
    result = _parseFractions(result);

    return result;
  }

  /// Attempt to parse fraction patterns from multi-line OCR output.
  /// Example: "x + 2\n─────\n3" becomes "(x + 2) / 3"
  String _parseFractions(String text) {
    final lines = text.split('\n');
    if (lines.length < 3) return text;

    final result = <String>[];
    int i = 0;

    while (i < lines.length) {
      // Check if current line is a fraction bar
      if (_isFractionBar(lines[i]) && i > 0 && i < lines.length - 1) {
        final numerator = result.removeLast().trim();
        final denominator = lines[i + 1].trim();
        result.add('($numerator) / ($denominator)');
        i += 2; // Skip bar and denominator
      } else {
        result.add(lines[i]);
        i++;
      }
    }

    return result.join(' ');
  }

  /// Check if a line looks like a fraction bar (e.g., "─────", "-----")
  bool _isFractionBar(String line) {
    final trimmed = line.trim();
    if (trimmed.length < 3) return false;

    // Check if the line consists mostly of dashes or horizontal lines
    final dashChars = RegExp(r'[─\-_=]');
    final dashCount = trimmed.split('').where((c) => dashChars.hasMatch(c)).length;
    return dashCount / trimmed.length > 0.7;
  }

  void dispose() {
    _textRecognizer.close();
  }
}
