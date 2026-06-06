import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/services/api_client.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_theme.dart';
import '../../models/question.dart';
import '../../models/round.dart';
import '../../services/challenge_service.dart';
import 'round_result_screen.dart';

class PlayRoundScreen extends StatefulWidget {
  final int challengeId;
  final Round round;

  const PlayRoundScreen({super.key, required this.challengeId, required this.round});

  @override
  State<PlayRoundScreen> createState() => _PlayRoundScreenState();
}

class _PlayRoundScreenState extends State<PlayRoundScreen> {
  List<Question>? _questions;
  int _current = 0;
  bool _loading = true;
  String? _error;
  int _myId = 0;

  // Per-question answers
  final Map<int, AnswerItem> _answers = {};

  // Timer
  Timer? _timer;
  int _timeLeft = 30;
  final _stopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    try {
      final storage = await StorageService.getInstance();
      _myId = storage.playerId ?? 0;
      final service = ChallengeService(ApiClient(storage));
      final questions = await service.getQuestions(widget.challengeId, widget.round.roundNumber);
      setState(() {
        _questions = questions;
        _loading = false;
      });
      _startTimer();
      _stopwatch.start();
    } catch (e) {
      setState(() { _loading = false; _error = '$e'; });
    }
  }

  void _startTimer() {
    final q = _questions![_current];
    _timeLeft = q.timeLimitSeconds;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_timeLeft <= 1) {
        t.cancel();
        _nextQuestion();
      } else {
        setState(() => _timeLeft--);
      }
    });
  }

  void _recordAnswer(AnswerItem answer) {
    setState(() => _answers[_questions![_current].id] = answer);
  }

  void _nextQuestion() {
    _timer?.cancel();
    if (_current >= (_questions!.length - 1)) {
      _submit();
    } else {
      setState(() => _current++);
      _startTimer();
    }
  }

  Future<void> _submit() async {
    _stopwatch.stop();
    setState(() => _loading = true);
    try {
      final storage = await StorageService.getInstance();
      final service = ChallengeService(ApiClient(storage));
      final round = await service.submitAttempt(
        challengeId: widget.challengeId,
        roundNumber: widget.round.roundNumber,
        totalTimeMs: _stopwatch.elapsedMilliseconds,
        answers: _answers.values.toList(),
      );
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => RoundResultScreen(
          round: round,
          questions: _questions!,
          myId: _myId,
          submittedAnswers: Map.from(_answers),
          challengeId: widget.challengeId,
        ),
      ));
    } catch (e) {
      setState(() { _loading = false; _error = '$e'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Jogar')),
        body: Center(child: Text('Erro: $_error', style: const TextStyle(color: AppColors.wrong))),
      );
    }

    final questions = _questions!;
    final q = questions[_current];
    final answered = _answers.containsKey(q.id);

    return Scaffold(
      appBar: AppBar(
        title: Text('Round ${widget.round.roundNumber} — ${widget.round.quizTypeDisplay ?? ''}'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          _ProgressHeader(current: _current, total: questions.length, timeLeft: _timeLeft, timeLimitSeconds: q.timeLimitSeconds),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (q.imageUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(q.imageUrl!, height: 180, width: double.infinity, fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink()),
                    ),
                  const SizedBox(height: 16),
                  Text(q.statement, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  _ThemeChips(question: q),
                  const SizedBox(height: 20),
                  _QuestionWidget(
                    question: q,
                    currentAnswer: _answers[q.id],
                    onAnswer: _recordAnswer,
                  ),
                ],
              ),
            ),
          ),
          _BottomBar(
            answered: answered,
            isLast: _current == questions.length - 1,
            onNext: _nextQuestion,
          ),
        ],
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  final int current;
  final int total;
  final int timeLeft;
  final int timeLimitSeconds;

  const _ProgressHeader({required this.current, required this.total, required this.timeLeft, required this.timeLimitSeconds});

  @override
  Widget build(BuildContext context) {
    final pct = timeLeft / timeLimitSeconds;
    final color = pct > 0.5 ? AppColors.correct : pct > 0.25 ? AppColors.secondary : AppColors.wrong;

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Questão ${current + 1}/$total', style: const TextStyle(fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.timer_outlined, color: color, size: 16),
                    const SizedBox(width: 4),
                    Text('$timeLeft s', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeChips extends StatelessWidget {
  final Question question;

  const _ThemeChips({required this.question});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      children: [
        _Chip(question.decade.name, Colors.blue),
        _Chip(question.media.name, AppColors.secondary),
        ...question.genres.map((g) => _Chip(g.name, AppColors.textSecondary)),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;

  const _Chip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500)),
    );
  }
}

class _QuestionWidget extends StatelessWidget {
  final Question question;
  final AnswerItem? currentAnswer;
  final void Function(AnswerItem) onAnswer;

  const _QuestionWidget({required this.question, required this.currentAnswer, required this.onAnswer});

  @override
  Widget build(BuildContext context) {
    return switch (question.quizType) {
      'MULTIPLE_CHOICE' => _MultipleChoiceWidget(question: question, current: currentAnswer, onAnswer: onAnswer),
      'TRUE_FALSE' => _TrueFalseWidget(question: question, current: currentAnswer, onAnswer: onAnswer),
      'ORDERING' => _OrderingWidget(key: ValueKey(question.id), question: question, current: currentAnswer, onAnswer: onAnswer),
      'LIST' => _ListWidget(question: question, current: currentAnswer, onAnswer: onAnswer),
      'HINTS' => _HintsWidget(key: ValueKey(question.id), question: question, current: currentAnswer, onAnswer: onAnswer),
      _ => const Text('Tipo de questão desconhecido'),
    };
  }
}

class _MultipleChoiceWidget extends StatelessWidget {
  final Question question;
  final AnswerItem? current;
  final void Function(AnswerItem) onAnswer;

  const _MultipleChoiceWidget({required this.question, required this.current, required this.onAnswer});

  @override
  Widget build(BuildContext context) {
    final alts = question.alternatives ?? [];
    return Column(
      children: alts.map((alt) {
        final selected = current?.alternativeId == alt.id;
        return GestureDetector(
          onTap: () => onAnswer(AnswerItem(questionId: question.id, alternativeId: alt.id)),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary.withValues(alpha: 0.2) : AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.divider,
                width: selected ? 2 : 1,
              ),
            ),
            child: Text(alt.text, style: TextStyle(fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
          ),
        );
      }).toList(),
    );
  }
}

class _TrueFalseWidget extends StatelessWidget {
  final Question question;
  final AnswerItem? current;
  final void Function(AnswerItem) onAnswer;

  const _TrueFalseWidget({required this.question, required this.current, required this.onAnswer});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _TFButton(label: 'Verdadeiro ✅', value: true, selected: current?.tfAnswer == true, onTap: () => onAnswer(AnswerItem(questionId: question.id, tfAnswer: true)))),
        const SizedBox(width: 12),
        Expanded(child: _TFButton(label: 'Falso ❌', value: false, selected: current?.tfAnswer == false, onTap: () => onAnswer(AnswerItem(questionId: question.id, tfAnswer: false)))),
      ],
    );
  }
}

class _TFButton extends StatelessWidget {
  final String label;
  final bool value;
  final bool selected;
  final VoidCallback onTap;

  const _TFButton({required this.label, required this.value, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = value ? AppColors.correct : AppColors.wrong;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.2) : AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? color : AppColors.divider, width: selected ? 2 : 1),
        ),
        child: Text(label, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: selected ? color : null)),
      ),
    );
  }
}

class _OrderingWidget extends StatefulWidget {
  final Question question;
  final AnswerItem? current;
  final void Function(AnswerItem) onAnswer;

  const _OrderingWidget({super.key, required this.question, required this.current, required this.onAnswer});

  @override
  State<_OrderingWidget> createState() => _OrderingWidgetState();
}

class _OrderingWidgetState extends State<_OrderingWidget> {
  late List<OrderingItem> _items;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.question.items ?? []);
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _items.removeAt(oldIndex);
      _items.insert(newIndex, item);
    });
    widget.onAnswer(AnswerItem(
      questionId: widget.question.id,
      orderedItemIds: _items.map((i) => i.id).toList(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Arraste para ordenar:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 8),
        ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          onReorder: _reorder,
          children: _items.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            return ReorderableDragStartListener(
              key: ValueKey(item.id),
              index: i,
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(child: Text('${i + 1}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(item.text)),
                    const Icon(Icons.drag_handle, color: AppColors.textSecondary),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _ListWidget extends StatefulWidget {
  final Question question;
  final AnswerItem? current;
  final void Function(AnswerItem) onAnswer;

  const _ListWidget({required this.question, required this.current, required this.onAnswer});

  @override
  State<_ListWidget> createState() => _ListWidgetState();
}

class _ListWidgetState extends State<_ListWidget> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final List<String> _correct = [];
  String? _feedback;
  bool _feedbackIsError = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  int get _limit => widget.question.totalAnswers ?? 3;
  List<String>? get _validAnswers => widget.question.listAnswers;

  bool _isCorrect(String text) {
    final answers = _validAnswers;
    if (answers == null) return true;
    return answers.any((a) => a.toLowerCase() == text.toLowerCase());
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    if (_correct.length >= _limit) {
      setState(() { _feedback = 'Você já encontrou todos os $_limit itens!'; _feedbackIsError = false; });
      return;
    }

    final alreadyFound = _correct.any((e) => e.toLowerCase() == text.toLowerCase());
    if (alreadyFound) {
      setState(() { _feedback = '"$text" já está na lista.'; _feedbackIsError = false; });
      _controller.clear();
      _focusNode.requestFocus();
      return;
    }

    if (!_isCorrect(text)) {
      setState(() { _feedback = '"$text" não está na lista.'; _feedbackIsError = true; });
      _controller.clear();
      _focusNode.requestFocus();
      return;
    }

    setState(() {
      _correct.add(text);
      _feedback = null;
      _feedbackIsError = false;
    });
    _controller.clear();
    _focusNode.requestFocus();

    widget.onAnswer(AnswerItem(
      questionId: widget.question.id,
      listAnswers: List.from(_correct),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final found = _correct.length;
    final done = found >= _limit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Encontre $_limit itens — $found/$_limit encontrado${found == 1 ? '' : 's'}',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                onSubmitted: (_) => _submit(),
                textInputAction: TextInputAction.send,
                enabled: !done,
                decoration: const InputDecoration(
                  hintText: 'Digite um nome...',
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: done ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(0, 50),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Enviar'),
            ),
          ],
        ),
        if (_feedback != null) ...[
          const SizedBox(height: 6),
          Text(
            _feedback!,
            style: TextStyle(
              color: _feedbackIsError ? AppColors.wrong : AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
        if (_correct.isNotEmpty) ...[
          const SizedBox(height: 14),
          ..._correct.asMap().entries.map((entry) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.correct.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.correct.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.correct, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(entry.value, style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.correct))),
                Text('${entry.key + 1}', style: const TextStyle(color: AppColors.correct, fontSize: 12)),
              ],
            ),
          )),
        ],
      ],
    );
  }
}

class _HintsWidget extends StatefulWidget {
  final Question question;
  final AnswerItem? current;
  final void Function(AnswerItem) onAnswer;

  const _HintsWidget({super.key, required this.question, required this.current, required this.onAnswer});

  @override
  State<_HintsWidget> createState() => _HintsWidgetState();
}

class _HintsWidgetState extends State<_HintsWidget> {
  int _revealed = 0;
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.current?.guessText != null) {
      _controller.text = widget.current!.guessText!;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<HintItem> get _hints =>
      (widget.question.hints ?? [])..sort((a, b) => a.position.compareTo(b.position));

  String _orientationLabel() => switch (widget.question.orientation) {
        'TITLE'     => 'Qual o título?',
        'CHARACTER' => 'Qual o personagem?',
        'ACTOR'     => 'Qual o ator/atriz?',
        _           => 'Qual a resposta?',
      };

  void _revealNext() {
    final total = _hints.length;
    if (_revealed < total) {
      setState(() => _revealed++);
      _updateAnswer();
    }
  }

  void _updateAnswer() {
    widget.onAnswer(AnswerItem(
      questionId: widget.question.id,
      guessText: _controller.text.trim().isEmpty ? null : _controller.text.trim(),
      hintsUsed: _revealed,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final hints = _hints;
    final total = hints.length;
    final canReveal = _revealed < total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Orientação
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.lightbulb_outline, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                _orientationLabel(),
                style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Contador de dicas
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Dicas reveladas: $_revealed / $total',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13),
            ),
            if (canReveal)
              TextButton.icon(
                onPressed: _revealNext,
                icon: const Icon(Icons.visibility_outlined, size: 16),
                label: const Text('Revelar dica', style: TextStyle(fontSize: 13)),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.secondary,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Dicas reveladas
        if (_revealed == 0)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.divider, style: BorderStyle.solid),
            ),
            child: const Text(
              'Nenhuma dica revelada ainda.\nTente adivinhar ou revele uma dica!',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          )
        else
          ...hints.take(_revealed).map((h) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.secondary.withValues(alpha: 0.4)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${h.position}',
                          style: const TextStyle(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(h.text,
                          style: const TextStyle(fontSize: 14)),
                    ),
                  ],
                ),
              )),

        const SizedBox(height: 16),

        // Campo de resposta
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                onChanged: (_) => _updateAnswer(),
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: 'Digite sua resposta...',
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _controller.clear();
                            _updateAnswer();
                          },
                        )
                      : null,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  final bool answered;
  final bool isLast;
  final VoidCallback onNext;

  const _BottomBar({required this.answered, required this.isLast, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: ElevatedButton(
        onPressed: onNext,
        style: ElevatedButton.styleFrom(
          backgroundColor: answered ? AppColors.primary : AppColors.card,
          minimumSize: const Size(double.infinity, 52),
        ),
        child: Text(isLast ? 'Finalizar' : 'Próxima →', style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}
