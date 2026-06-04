import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/question.dart';
import '../../models/round.dart';

class RoundResultScreen extends StatelessWidget {
  final Round round;
  final List<Question> questions;

  const RoundResultScreen({super.key, required this.round, required this.questions});

  @override
  Widget build(BuildContext context) {
    final myAttempt = round.drawerAttempt ?? round.opponentAttempt;
    final total = questions.length;
    final correct = myAttempt?.correctAnswers ?? 0;

    final emoji = correct == total
        ? '🏆'
        : correct >= total * 0.7
            ? '🎉'
            : correct >= total * 0.4
                ? '👍'
                : '😅';

    return Scaffold(
      appBar: AppBar(title: Text('Round ${round.roundNumber} — Resultado'), automaticallyImplyLeading: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 24),
            Text(emoji, style: const TextStyle(fontSize: 72)),
            const SizedBox(height: 16),
            Text(
              '$correct/$total acertos',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: correct >= total * 0.5 ? AppColors.correct : AppColors.wrong,
              ),
            ),
            const SizedBox(height: 8),
            if (myAttempt != null)
              Text(
                'Tempo total: ${(myAttempt.totalTimeMs / 1000).toStringAsFixed(1)}s',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            const SizedBox(height: 32),
            if (round.isCompleted && round.opponentAttempt != null) ...[
              _ComparisonCard(round: round),
              const SizedBox(height: 24),
            ],
            ..._buildQuestionResults(questions, myAttempt),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
              child: const Text('Voltar para home'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildQuestionResults(List<Question> questions, RoundAttempt? attempt) {
    if (attempt == null) return [];
    return questions.asMap().entries.map((entry) {
      final i = entry.key;
      final q = entry.value;
      final correct = i < attempt.questionResults.length ? attempt.questionResults[i] : false;
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: correct ? AppColors.correct.withValues(alpha: 0.4) : AppColors.wrong.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            Icon(
              correct ? Icons.check_circle : Icons.cancel,
              color: correct ? AppColors.correct : AppColors.wrong,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                q.statement,
                style: const TextStyle(fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}

class _ComparisonCard extends StatelessWidget {
  final Round round;

  const _ComparisonCard({required this.round});

  @override
  Widget build(BuildContext context) {
    final drawer = round.drawerAttempt;
    final opponent = round.opponentAttempt;

    String resultLabel;
    Color resultColor;

    if (round.result == 'DRAW') {
      resultLabel = 'Empate!';
      resultColor = AppColors.secondary;
    } else {
      resultLabel = round.result == 'DRAWER_WIN' ? 'Você venceu!' : 'Você perdeu';
      resultColor = round.result == 'DRAWER_WIN' ? AppColors.correct : AppColors.wrong;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: resultColor.withValues(alpha: 0.4), width: 2),
      ),
      child: Column(
        children: [
          Text(resultLabel, style: TextStyle(color: resultColor, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _AttemptStat(label: 'Você (drawer)', attempt: drawer),
              const Text('vs', style: TextStyle(color: AppColors.textSecondary)),
              _AttemptStat(label: round.drawer.username, attempt: opponent),
            ],
          ),
        ],
      ),
    );
  }
}

class _AttemptStat extends StatelessWidget {
  final String label;
  final RoundAttempt? attempt;

  const _AttemptStat({required this.label, required this.attempt});

  @override
  Widget build(BuildContext context) {
    if (attempt == null) return Text(label, style: const TextStyle(color: AppColors.textSecondary));
    final att = attempt!;
    return Column(
      children: [
        Text(
          '${att.correctAnswers} acertos',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        Text('${(att.totalTimeMs / 1000).toStringAsFixed(1)}s', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
      ],
    );
  }
}
