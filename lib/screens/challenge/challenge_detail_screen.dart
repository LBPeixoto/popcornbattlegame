import 'package:flutter/material.dart';
import '../../core/services/api_client.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_theme.dart';
import '../../models/challenge.dart';
import '../../models/round.dart';
import '../../services/challenge_service.dart';
import 'draw_round_screen.dart';
import 'play_round_screen.dart';

class ChallengeDetailScreen extends StatefulWidget {
  final int challengeId;

  const ChallengeDetailScreen({super.key, required this.challengeId});

  @override
  State<ChallengeDetailScreen> createState() => _ChallengeDetailScreenState();
}

class _ChallengeDetailScreenState extends State<ChallengeDetailScreen> {
  late Future<Challenge> _future;
  late ChallengeService _service;
  late int _myId;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final storage = await StorageService.getInstance();
    _myId = storage.playerId ?? 0;
    _service = ChallengeService(ApiClient(storage));
    _refresh();
  }

  void _refresh() {
    setState(() {
      _future = _service.getChallenge(widget.challengeId);
    });
  }

  Future<void> _action(Challenge c) async {
    final round = c.currentRound;
    if (round == null) return;

    if (round.isWaitingDrawer && round.drawer.id == _myId) {
      await Navigator.push(context, MaterialPageRoute(
        builder: (_) => DrawRoundScreen(challengeId: c.id, roundNumber: round.roundNumber),
      ));
    } else if (round.isWaitingOpponent || (round.isWaitingDrawer && round.drawer.id == _myId && round.theme != null)) {
      await Navigator.push(context, MaterialPageRoute(
        builder: (_) => PlayRoundScreen(challengeId: c.id, round: round),
      ));
    }
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Batalha')),
      body: FutureBuilder<Challenge>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }
          final c = snapshot.data!;
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async => _refresh(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(challenge: c, myId: _myId),
                  const SizedBox(height: 24),
                  Text('Rodadas', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...c.rounds.map((r) => _RoundTile(round: r, myId: _myId, challenge: c)),
                  if (c.isInProgress && c.myTurn && c.currentRound != null) ...[
                    const SizedBox(height: 24),
                    _ActionButton(challenge: c, round: c.currentRound!, myId: _myId, onAction: () => _action(c)),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final Challenge challenge;
  final int myId;

  const _Header({required this.challenge, required this.myId});

  @override
  Widget build(BuildContext context) {
    final challenger = challenge.challenger;
    final challenged = challenge.challenged;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _PlayerStat(player: challenger, isMe: challenger.id == myId),
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                    ),
                    child: const Text('VS', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                ],
              ),
              _PlayerStat(player: challenged, isMe: challenged.id == myId),
            ],
          ),
          if (challenge.isCompleted) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                challenge.resultLabel(myId),
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.secondary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PlayerStat extends StatelessWidget {
  final dynamic player;
  final bool isMe;

  const _PlayerStat({required this.player, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: isMe ? AppColors.primary.withValues(alpha: 0.2) : AppColors.surface,
          child: Text(
            player.username[0].toUpperCase(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isMe ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isMe ? 'Você' : player.username,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(
          '${player.wins}V ${player.losses}D',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}

class _RoundTile extends StatelessWidget {
  final Round round;
  final int myId;
  final Challenge challenge;

  const _RoundTile({required this.round, required this.myId, required this.challenge});

  @override
  Widget build(BuildContext context) {
    final isMyDrawer = round.drawer.id == myId;
    final myAttempt = isMyDrawer ? round.drawerAttempt : round.opponentAttempt;

    Color dotColor;
    String label;
    if (round.isCompleted) {
      if (round.result == 'DRAW') {
        dotColor = AppColors.secondary;
        label = 'Empate';
      } else {
        final isWinner = (round.result == 'DRAWER_WIN' && isMyDrawer) ||
            (round.result == 'OPPONENT_WIN' && !isMyDrawer);
        dotColor = isWinner ? AppColors.correct : AppColors.wrong;
        label = isWinner ? 'Vitória' : 'Derrota';
      }
    } else if (round.isWaitingDrawer) {
      dotColor = AppColors.secondary;
      label = isMyDrawer ? 'Sortear tema' : 'Aguardando sorteio';
    } else {
      dotColor = AppColors.primary;
      label = round.drawer.id != myId ? 'Sua vez de jogar' : 'Aguardando oponente';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 10, height: 10,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Round ${round.roundNumber}', style: const TextStyle(fontWeight: FontWeight.bold)),
                if (round.theme != null)
                  Text(
                    '${round.theme!.name} • ${round.quizTypeDisplay ?? ''}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(label, style: TextStyle(color: dotColor, fontSize: 12, fontWeight: FontWeight.w600)),
              if (myAttempt != null)
                Text(
                  '${myAttempt.correctAnswers} acertos',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final Challenge challenge;
  final Round round;
  final int myId;
  final VoidCallback onAction;

  const _ActionButton({required this.challenge, required this.round, required this.myId, required this.onAction});

  @override
  Widget build(BuildContext context) {
    String label;
    if (round.isWaitingDrawer && round.drawer.id == myId) {
      label = '🎲 Sortear tema do Round ${round.roundNumber}';
    } else {
      label = '▶ Jogar Round ${round.roundNumber}';
    }

    return ElevatedButton(
      onPressed: onAction,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        minimumSize: const Size(double.infinity, 56),
      ),
      child: Text(label, style: const TextStyle(fontSize: 18)),
    );
  }
}
