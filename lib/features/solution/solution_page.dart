import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/math_question.dart';
import '../../models/math_solution.dart';
import '../../services/math_service.dart';
import '../../services/history_service.dart';

/// Page that displays the step-by-step solution like a tutor.
class SolutionPage extends StatefulWidget {
  const SolutionPage({super.key});

  @override
  State<SolutionPage> createState() => _SolutionPageState();
}

class _SolutionPageState extends State<SolutionPage>
    with TickerProviderStateMixin {
  MathSolution? _solution;
  bool _isLoading = true;
  String? _error;
  ExplanationLevel _explanationLevel = ExplanationLevel.detail;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isLoading && _solution == null) {
      _solveProblem();
    }
  }

  Future<void> _solveProblem() async {
    final question =
        ModalRoute.of(context)?.settings.arguments as MathQuestion?;
    if (question == null) {
      setState(() {
        _error = 'Soal tidak ditemukan';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final mathService = context.read<MathService>();
      final solution = await mathService.solve(
        question,
        level: _explanationLevel,
      );

      // Save to history
      final historyService = context.read<HistoryService>();
      await historyService.saveToHistory(
        question: question,
        solution: solution,
      );

      setState(() {
        _solution = solution;
        _isLoading = false;
      });

      _animController.forward();
    } catch (e) {
      setState(() {
        _error = 'Gagal menyelesaikan: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _animController.dispose();
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
          'Hasil',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        actions: [
          // Explanation level toggle
          PopupMenuButton<ExplanationLevel>(
            icon: const Icon(Icons.tune, color: Colors.white),
            color: const Color(0xFF2A2A4A),
            onSelected: (level) {
              setState(() {
                _explanationLevel = level;
                _isLoading = true;
                _solution = null;
              });
              _animController.reset();
              _solveProblem();
            },
            itemBuilder: (context) => [
              _buildLevelMenuItem(
                ExplanationLevel.singkat,
                'Singkat',
                'Langkah minimal',
                Icons.short_text,
              ),
              _buildLevelMenuItem(
                ExplanationLevel.detail,
                'Detail',
                'Penjelasan setiap langkah',
                Icons.format_list_numbered,
              ),
              _buildLevelMenuItem(
                ExplanationLevel.tutor,
                'Tutor',
                'Penjelasan konsep + langkah',
                Icons.school,
              ),
            ],
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  PopupMenuItem<ExplanationLevel> _buildLevelMenuItem(
    ExplanationLevel level,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final isSelected = _explanationLevel == level;
    return PopupMenuItem(
      value: level,
      child: Row(
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.deepPurple : Colors.white54,
            size: 20,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.deepPurple : Colors.white,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
          if (isSelected) ...[
            const Spacer(),
            const Icon(Icons.check, color: Colors.deepPurple, size: 18),
          ],
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_solution == null) {
      return _buildErrorState();
    }

    return _buildSolutionContent();
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated solving indicator
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.deepPurple.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.deepPurple,
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'AI sedang menyelesaikan...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Memahami soal dan menyusun langkah penyelesaian',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade300, size: 48),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Terjadi kesalahan',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 15),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                _animController.reset();
                _solveProblem();
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSolutionContent() {
    final solution = _solution!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question card
          _buildQuestionCard(solution),

          const SizedBox(height: 20),

          // Answer card
          _buildAnswerCard(solution),

          const SizedBox(height: 20),

          // Concept card (if tutor mode)
          if (solution.concept != null && solution.concept!.isNotEmpty)
            _buildConceptCard(solution),

          if (solution.concept != null && solution.concept!.isNotEmpty)
            const SizedBox(height: 20),

          // Steps section
          _buildStepsSection(solution),

          const SizedBox(height: 32),

          // Bottom action
          _buildBottomAction(),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(MathSolution solution) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.help_outline,
                  color: Colors.deepPurple.shade200, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Soal',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            solution.question,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
            ),
          ),
          if (solution.method.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Metode: ${solution.method}',
                style: TextStyle(
                  color: Colors.deepPurple.shade200,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnswerCard(MathSolution solution) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.deepPurple.shade900.withOpacity(0.6),
            Colors.deepPurple.shade800.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.deepPurple.shade600),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Jawaban',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...solution.answers.map(
            (answer) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                answer,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConceptCard(MathSolution solution) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.blue.shade800),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline,
                  color: Colors.amber.shade300, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Konsep',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            solution.concept!,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepsSection(MathSolution solution) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.format_list_numbered, color: Colors.white70, size: 20),
            SizedBox(width: 8),
            Text(
              'Cara Pengerjaan',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...solution.steps.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;
          return _buildStepCard(step, index, solution.steps.length);
        }),
      ],
    );
  }

  Widget _buildStepCard(SolutionStep step, int index, int totalSteps) {
    final isLast = index == totalSteps - 1;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step indicator with line
        Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isLast
                    ? Colors.green.withOpacity(0.2)
                    : Colors.deepPurple.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isLast
                      ? Colors.green.shade400
                      : Colors.deepPurple.shade300,
                  width: 2,
                ),
              ),
              child: Center(
                child: isLast
                    ? Icon(Icons.check, color: Colors.green.shade300, size: 16)
                    : Text(
                        '${step.stepNumber}',
                        style: TextStyle(
                          color: Colors.deepPurple.shade200,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: Colors.white12,
              ),
          ],
        ),

        const SizedBox(width: 14),

        // Step content
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  step.content,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
                if (step.formula != null && step.formula!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      step.formula!,
                      style: TextStyle(
                        color: Colors.deepPurple.shade200,
                        fontSize: 15,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomAction() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () {
          // Go back to scanner
          Navigator.popUntil(context, (route) => route.isFirst);
        },
        icon: const Icon(Icons.camera_alt_outlined, size: 20),
        label: const Text(
          'Scan Soal Berikutnya',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
