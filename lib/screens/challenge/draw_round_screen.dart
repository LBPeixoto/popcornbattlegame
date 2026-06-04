import 'package:flutter/material.dart';
import '../../core/services/api_client.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_theme.dart';
import '../../models/round.dart';
import '../../services/challenge_service.dart';
import 'play_round_screen.dart';

class DrawRoundScreen extends StatefulWidget {
  final int challengeId;
  final int roundNumber;

  const DrawRoundScreen({super.key, required this.challengeId, required this.roundNumber});

  @override
  State<DrawRoundScreen> createState() => _DrawRoundScreenState();
}

class _DrawRoundScreenState extends State<DrawRoundScreen> with SingleTickerProviderStateMixin {
  bool _loading = false;
  Round? _drawn;
  late AnimationController _spinController;
  late Animation<double> _spinAnim;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
    _spinAnim = Tween(begin: 0.0, end: 1.0).animate(_spinController);
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  Future<void> _draw() async {
    setState(() => _loading = true);
    try {
      final storage = await StorageService.getInstance();
      final service = ChallengeService(ApiClient(storage));
      final round = await service.drawRound(widget.challengeId, widget.roundNumber);
      _spinController.stop();
      setState(() {
        _drawn = round;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e'), backgroundColor: AppColors.wrong),
      );
    }
  }

  String _quizTypeEmoji(String? type) => switch (type) {
        'MULTIPLE_CHOICE' => '🔵',
        'TRUE_FALSE' => '✅',
        'ORDERING' => '🔢',
        'LIST' => '📝',
        _ => '❓',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Round ${widget.roundNumber} — Sorteio')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_drawn == null) ...[
              RotationTransition(
                turns: _spinAnim,
                child: const Text('🎲', style: TextStyle(fontSize: 80)),
              ),
              const SizedBox(height: 32),
              Text(
                'Você escolhe o tema\ndeste round!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'O tema e tipo de questão serão sorteados aleatoriamente.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _loading ? null : _draw,
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 60)),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('🎲  Sortear!', style: TextStyle(fontSize: 20)),
              ),
            ] else ...[
              const Text('✨', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 24),
              Text(
                'Tema sorteado!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 2),
                ),
                child: Column(
                  children: [
                    if (_drawn!.theme != null) ...[
                      Text(_drawn!.theme!.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.secondary)),
                      const SizedBox(height: 8),
                      Text(_drawn!.theme!.typeLabel, style: const TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 16),
                      const Divider(color: AppColors.divider),
                      const SizedBox(height: 16),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_quizTypeEmoji(_drawn!.quizType), style: const TextStyle(fontSize: 32)),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_drawn!.quizTypeDisplay ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text('${_drawn!.timeLimitSeconds ?? 0}s por questão', style: const TextStyle(color: AppColors.textSecondary)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(context, MaterialPageRoute(
                    builder: (_) => PlayRoundScreen(challengeId: widget.challengeId, round: _drawn!),
                  ));
                },
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 60)),
                child: const Text('▶  Jogar agora!', style: TextStyle(fontSize: 20)),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Jogar depois'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
