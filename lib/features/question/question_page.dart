import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../scanner/scanner_controller.dart';

/// Page for editing/correcting the scanned math expression before solving.
/// Allows user to fix OCR misreads before submitting for solution.
class QuestionPage extends StatefulWidget {
  const QuestionPage({super.key});

  @override
  State<QuestionPage> createState() => _QuestionPageState();
}

class _QuestionPageState extends State<QuestionPage> {
  late TextEditingController _textController;
  bool _hasEdited = false;

  @override
  void initState() {
    super.initState();
    final controller = context.read<ScannerController>();
    _textController = TextEditingController(text: controller.detectedText);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Soal',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
      body: Consumer<ScannerController>(
        builder: (context, controller, _) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info card
                _buildInfoCard(),

                const SizedBox(height: 24),

                // Original scan result label
                const Text(
                  'Hasil Scan',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),

                // Original text (non-editable)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Text(
                    controller.detectedText,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 16,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Editable field
                const Text(
                  'Soal (edit jika perlu)',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.deepPurple.shade300.withOpacity(0.5),
                    ),
                  ),
                  child: TextField(
                    controller: _textController,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 3,
                    minLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Ketik soal matematika...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                      contentPadding: const EdgeInsets.all(16),
                      border: InputBorder.none,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _hasEdited = value != controller.detectedText;
                      });
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Quick symbols row
                _buildSymbolsRow(),

                const Spacer(),

                // Action buttons
                _buildActionButtons(controller),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepPurple.shade800),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.deepPurple, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Periksa dan perbaiki soal jika hasil scan kurang tepat sebelum diselesaikan.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSymbolsRow() {
    final symbols = [
      ('x²', '^2'),
      ('√', 'sqrt('),
      ('π', 'pi'),
      ('÷', '/'),
      ('×', '*'),
      ('()', '()'),
      ('≤', '<='),
      ('≥', '>='),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: symbols.map((symbol) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _insertSymbol(symbol.$2),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24),
                ),
                child: Text(
                  symbol.$1,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _insertSymbol(String symbol) {
    final text = _textController.text;
    final selection = _textController.selection;
    final cursorPos = selection.baseOffset >= 0 ? selection.baseOffset : text.length;

    final newText =
        text.substring(0, cursorPos) + symbol + text.substring(cursorPos);
    _textController.text = newText;
    _textController.selection = TextSelection.fromPosition(
      TextPosition(offset: cursorPos + symbol.length),
    );

    setState(() {
      _hasEdited = true;
    });
  }

  Widget _buildActionButtons(ScannerController controller) {
    return Column(
      children: [
        // Solve button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () {
              final text = _textController.text.trim();
              if (text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Soal tidak boleh kosong')),
                );
                return;
              }

              // Update controller with edited text
              if (_hasEdited) {
                controller.updateDetectedText(text);
              }

              // Navigate to solving page
              Navigator.pushNamed(
                context,
                '/solving',
                arguments: controller.currentQuestion,
              );
            },
            icon: const Icon(Icons.auto_awesome, size: 20),
            label: const Text(
              'Selesaikan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Back to scan button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () {
              controller.reset();
              Navigator.pop(context);
            },
            icon: const Icon(Icons.camera_alt_outlined, size: 18),
            label: const Text('Scan Ulang'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white70,
              side: const BorderSide(color: Colors.white24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
