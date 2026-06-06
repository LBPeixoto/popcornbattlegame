import 'package:flutter/material.dart';
import '../../core/services/api_client.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_theme.dart';
import '../../models/question.dart';
import '../../models/revealed_answer.dart';
import '../../models/round.dart';
import '../../services/challenge_service.dart';

class RoundResultScreen extends StatefulWidget {
  final Round round;
  final List<Question> questions;
  final int myId;
  final Map<int, AnswerItem> submittedAnswers;
  final int challengeId;

  const RoundResultScreen({
    super.key,
    required this.round,
    required this.questions,
    required this.myId,
    required this.submittedAnswers,
    required this.challengeId,
  });

  @override
  State<RoundResultScreen> createState() => _RoundResultScreenState();
}

class _RoundResultScreenState extends State<RoundResultScreen> {
  List<RevealedAnswer>? _revealed;

  @override
  void initState() {
    super.initState();
    _fetchRevealed();
  }

  Future<void> _fetchRevealed() async {
    try {
      final storage = await StorageService.getInstance();
      final service = ChallengeService(ApiClient(storage));
      final revealed = await service.getRevealedAnswers(
          widget.challengeId, widget.round.roundNumber);
      if (mounted) setState(() => _revealed = revealed);
    } catch (_) {}
  }

  int _maxScore() {
    if (widget.questions.isEmpty) return 1;
    final type = widget.questions.first.quizType;
    if (type == 'ORDERING') {
      return widget.questions.fold(0, (sum, q) => sum + (q.items?.length ?? 1));
    }
    if (type == 'LIST') {
      return widget.questions.fold(0, (sum, q) => sum + (q.totalAnswers ?? 1));
    }
    // MULTIPLE_CHOICE, TRUE_FALSE, HINTS: 1 ponto por questão
    return widget.questions.length;
  }

  @override
  Widget build(BuildContext context) {
    final isDrawer = widget.round.drawer.id == widget.myId;
    final myAttempt = isDrawer ? widget.round.drawerAttempt : widget.round.opponentAttempt;
    final maxScore = _maxScore();
    final correct = myAttempt?.correctAnswers ?? 0;

    final emoji = correct == maxScore
        ? '🏆'
        : correct >= maxScore * 0.7
            ? '🎉'
            : correct >= maxScore * 0.4
                ? '👍'
                : '😅';

    return Scaffold(
      appBar: AppBar(
          title: Text('Round ${widget.round.roundNumber} — Resultado'),
          automaticallyImplyLeading: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Text(emoji, style: const TextStyle(fontSize: 72)),
            const SizedBox(height: 16),
            Text(
              '$correct / $maxScore',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: correct >= maxScore * 0.5
                        ? AppColors.correct
                        : AppColors.wrong,
                  ),
            ),
            if (myAttempt != null) ...[
              const SizedBox(height: 4),
              Text(
                'Tempo: ${(myAttempt.totalTimeMs / 1000).toStringAsFixed(1)}s',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
            const SizedBox(height: 24),
            if (widget.round.isCompleted && widget.round.opponentAttempt != null) ...[
              _ComparisonCard(round: widget.round, myId: widget.myId),
              const SizedBox(height: 24),
            ],
            Text('Gabarito',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ..._buildQuestionCards(myAttempt),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () =>
                  Navigator.popUntil(context, (route) => route.isFirst),
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50)),
              child: const Text('Voltar para home'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildQuestionCards(RoundAttempt? attempt) {
    return widget.questions.asMap().entries.map((entry) {
      final i = entry.key;
      final q = entry.value;
      final isCorrect =
          attempt != null && i < attempt.questionResults.length
              ? attempt.questionResults[i]
              : false;
      final revealed =
          _revealed?.where((r) => r.questionId == q.id).firstOrNull;
      final submitted = widget.submittedAnswers[q.id];

      return _QuestionCard(
        question: q,
        index: i,
        isCorrect: isCorrect,
        revealed: revealed,
        submitted: submitted,
      );
    }).toList();
  }
}

class _QuestionCard extends StatelessWidget {
  final Question question;
  final int index;
  final bool isCorrect;
  final RevealedAnswer? revealed;
  final AnswerItem? submitted;

  const _QuestionCard({
    required this.question,
    required this.index,
    required this.isCorrect,
    required this.revealed,
    required this.submitted,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isCorrect
        ? AppColors.correct.withValues(alpha: 0.5)
        : AppColors.wrong.withValues(alpha: 0.5);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isCorrect ? Icons.check_circle : Icons.cancel,
                  color: isCorrect ? AppColors.correct : AppColors.wrong,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${index + 1}. ${question.statement}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          if (revealed != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: _AnswerDetail(
                  question: question, revealed: revealed!, submitted: submitted),
            )
          else
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
    );
  }
}

class _AnswerDetail extends StatelessWidget {
  final Question question;
  final RevealedAnswer revealed;
  final AnswerItem? submitted;

  const _AnswerDetail(
      {required this.question,
      required this.revealed,
      required this.submitted});

  @override
  Widget build(BuildContext context) {
    return switch (question.quizType) {
      'MULTIPLE_CHOICE' => _McDetail(question: question, revealed: revealed, submitted: submitted),
      'TRUE_FALSE' => _TfDetail(revealed: revealed, submitted: submitted),
      'ORDERING' => _OrderingDetail(question: question, revealed: revealed, submitted: submitted),
      'LIST' => _ListDetail(revealed: revealed, submitted: submitted),
      'HINTS' => _HintsResultDetail(revealed: revealed, submitted: submitted),
      _ => const SizedBox.shrink(),
    };
  }
}

class _McDetail extends StatelessWidget {
  final Question question;
  final RevealedAnswer revealed;
  final AnswerItem? submitted;

  const _McDetail(
      {required this.question, required this.revealed, required this.submitted});

  @override
  Widget build(BuildContext context) {
    final alts = question.alternatives ?? [];
    return Column(
      children: alts.map((alt) {
        final isCorrectAlt = alt.id == revealed.correctAlternativeId;
        final isSelected = alt.id == submitted?.alternativeId;
        Color? bg;
        Color border = AppColors.divider;
        if (isCorrectAlt) {
          bg = AppColors.correct.withValues(alpha: 0.15);
          border = AppColors.correct;
        } else if (isSelected && !isCorrectAlt) {
          bg = AppColors.wrong.withValues(alpha: 0.1);
          border = AppColors.wrong;
        }
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              Expanded(
                  child: Text(alt.text,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: isCorrectAlt || isSelected
                              ? FontWeight.bold
                              : FontWeight.normal))),
              if (isCorrectAlt)
                const Icon(Icons.check, color: AppColors.correct, size: 16),
              if (isSelected && !isCorrectAlt)
                const Icon(Icons.close, color: AppColors.wrong, size: 16),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _TfDetail extends StatelessWidget {
  final RevealedAnswer revealed;
  final AnswerItem? submitted;

  const _TfDetail({required this.revealed, required this.submitted});

  @override
  Widget build(BuildContext context) {
    final correct = revealed.correctTfAnswer;
    final answer = submitted?.tfAnswer;
    return Row(
      children: [
        _TfChip(
          label: 'Verdadeiro',
          isCorrect: correct == true,
          isSelected: answer == true,
        ),
        const SizedBox(width: 8),
        _TfChip(
          label: 'Falso',
          isCorrect: correct == false,
          isSelected: answer == false,
        ),
      ],
    );
  }
}

class _TfChip extends StatelessWidget {
  final String label;
  final bool isCorrect;
  final bool isSelected;

  const _TfChip(
      {required this.label,
      required this.isCorrect,
      required this.isSelected});

  @override
  Widget build(BuildContext context) {
    Color color;
    if (isCorrect) {
      color = AppColors.correct;
    } else if (isSelected && !isCorrect) {
      color = AppColors.wrong;
    } else {
      color = AppColors.divider;
    }
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: (isCorrect || (isSelected && !isCorrect))
              ? color.withValues(alpha: 0.15)
              : null,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color == AppColors.divider
                        ? AppColors.textSecondary
                        : color)),
            if (isCorrect) ...[
              const SizedBox(width: 4),
              Icon(Icons.check, size: 14, color: color),
            ],
            if (isSelected && !isCorrect) ...[
              const SizedBox(width: 4),
              Icon(Icons.close, size: 14, color: color),
            ],
          ],
        ),
      ),
    );
  }
}

class _OrderingDetail extends StatelessWidget {
  final Question question;
  final RevealedAnswer revealed;
  final AnswerItem? submitted;

  const _OrderingDetail(
      {required this.question, required this.revealed, required this.submitted});

  @override
  Widget build(BuildContext context) {
    final allItems = question.items ?? [];
    final correctIds = revealed.correctItemIds ?? [];
    final submittedIds = submitted?.orderedItemIds ?? [];

    String nameOf(int id) =>
        allItems.where((i) => i.id == id).map((i) => i.text).firstOrNull ?? '?';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Sua ordem',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              if (submittedIds.isEmpty)
                const Text('—',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.textSecondary))
              else
                ...submittedIds.asMap().entries.map((e) {
                  final isRight =
                      e.key < correctIds.length && correctIds[e.key] == e.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text('${e.key + 1}. ${nameOf(e.value)}',
                        style: TextStyle(
                            fontSize: 11,
                            color: isRight ? AppColors.correct : AppColors.wrong,
                            fontWeight: FontWeight.w500)),
                  );
                }),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Ordem correta',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.correct)),
              const SizedBox(height: 4),
              ...correctIds.asMap().entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text('${e.key + 1}. ${nameOf(e.value)}',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.correct)),
                  )),
            ],
          ),
        ),
      ],
    );
  }
}

class _ListDetail extends StatelessWidget {
  final RevealedAnswer revealed;
  final AnswerItem? submitted;

  const _ListDetail({required this.revealed, required this.submitted});

  @override
  Widget build(BuildContext context) {
    final valid = revealed.validAnswers ?? [];
    final typed = submitted?.listAnswers ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (typed.isNotEmpty) ...[
          const Text('Suas respostas:',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: typed
                .map((t) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.correct.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.correct.withValues(alpha: 0.5)),
                      ),
                      child: Text(t,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.correct)),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
        ],
        const Text('Respostas válidas:',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: valid
              .map((v) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Text(v,
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary)),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class _HintsResultDetail extends StatelessWidget {
  final RevealedAnswer revealed;
  final AnswerItem? submitted;

  const _HintsResultDetail({required this.revealed, required this.submitted});

  @override
  Widget build(BuildContext context) {
    final correctAnswer = revealed.validAnswers?.firstOrNull ?? '—';
    final playerGuess = submitted?.guessText;
    final hintsUsed = submitted?.hintsUsed ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.lightbulb_outline, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text('Dicas usadas: $hintsUsed',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
        const SizedBox(height: 8),
        if (playerGuess != null && playerGuess.isNotEmpty) ...[
          const Text('Sua resposta:',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.divider),
            ),
            child: Text(playerGuess,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
          const SizedBox(height: 8),
        ],
        const Text('Resposta correta:',
            style: TextStyle(fontSize: 11, color: AppColors.correct)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.correct.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.correct.withValues(alpha: 0.5)),
          ),
          child: Text(correctAnswer,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.correct)),
        ),
      ],
    );
  }
}

class _ComparisonCard extends StatelessWidget {
  final Round round;
  final int myId;

  const _ComparisonCard({required this.round, required this.myId});

  @override
  Widget build(BuildContext context) {
    final isDrawer = round.drawer.id == myId;
    final myAttempt = isDrawer ? round.drawerAttempt : round.opponentAttempt;
    final theirAttempt = isDrawer ? round.opponentAttempt : round.drawerAttempt;
    final theirLabel = isDrawer ? 'Oponente' : round.drawer.username;

    String resultLabel;
    Color resultColor;

    if (round.result == 'DRAW') {
      resultLabel = 'Empate!';
      resultColor = AppColors.secondary;
    } else {
      final iWon = (round.result == 'DRAWER_WIN' && isDrawer) ||
          (round.result == 'OPPONENT_WIN' && !isDrawer);
      resultLabel = iWon ? 'Você venceu!' : 'Você perdeu';
      resultColor = iWon ? AppColors.correct : AppColors.wrong;
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
          Text(resultLabel,
              style: TextStyle(
                  color: resultColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _AttemptStat(label: 'Você', attempt: myAttempt),
              const Text('vs',
                  style: TextStyle(color: AppColors.textSecondary)),
              _AttemptStat(label: theirLabel, attempt: theirAttempt),
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
    if (attempt == null) {
      return Text(label,
          style: const TextStyle(color: AppColors.textSecondary));
    }
    return Column(
      children: [
        Text('${attempt!.correctAnswers} pts',
            style:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        Text('${(attempt!.totalTimeMs / 1000).toStringAsFixed(1)}s',
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 12)),
        Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 11)),
      ],
    );
  }
}
