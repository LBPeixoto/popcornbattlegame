import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/challenge.dart';

class ChallengeCard extends StatelessWidget {
  final Challenge challenge;
  final VoidCallback onTap;
  final int myId;

  const ChallengeCard({
    super.key,
    required this.challenge,
    required this.onTap,
    required this.myId,
  });

  @override
  Widget build(BuildContext context) {
    final opponent = challenge.opponent(myId);
    final isMyTurn = challenge.myTurn;
    final isCompleted = challenge.isCompleted;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isCompleted) {
      final result = challenge.result;
      if (result == 'DRAW') {
        statusColor = AppColors.secondary;
        statusText = 'Empate';
        statusIcon = Icons.handshake_outlined;
      } else {
        final winnerId = result == 'CHALLENGER_WIN'
            ? challenge.challenger.id
            : challenge.challenged.id;
        if (winnerId == myId) {
          statusColor = AppColors.correct;
          statusText = 'Vitória';
          statusIcon = Icons.emoji_events;
        } else {
          statusColor = AppColors.wrong;
          statusText = 'Derrota';
          statusIcon = Icons.sentiment_dissatisfied_outlined;
        }
      }
    } else if (isMyTurn) {
      statusColor = AppColors.primary;
      statusText = 'Sua vez!';
      statusIcon = Icons.play_arrow;
    } else {
      statusColor = AppColors.textSecondary;
      statusText = 'Aguardando ${opponent.username}';
      statusIcon = Icons.hourglass_empty;
    }

    final roundInfo = challenge.currentRound != null
        ? 'Round ${challenge.currentRound!.roundNumber}'
        : 'Rodada ${challenge.rounds.length}/${3}';

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(statusIcon, color: statusColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'vs ${opponent.username}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      roundInfo,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
