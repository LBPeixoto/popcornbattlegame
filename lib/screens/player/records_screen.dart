import 'package:flutter/material.dart';
import '../../core/services/api_client.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_theme.dart';
import '../../models/player_record.dart';
import '../../services/player_service.dart';

class RecordsScreen extends StatefulWidget {
  final int playerId;
  final String playerName;

  const RecordsScreen({super.key, required this.playerId, required this.playerName});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  late Future<PlayerRecord> _recordFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final storage = await StorageService.getInstance();
    final service = PlayerService(ApiClient(storage));
    setState(() {
      _recordFuture = service.getRecords(widget.playerId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recordes de ${widget.playerName}'),
      ),
      body: FutureBuilder<PlayerRecord>(
        future: _recordFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline, size: 48, color: AppColors.textSecondary),
                  const SizedBox(height: 12),
                  Text(
                    'Recordes não disponíveis',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }
          final r = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SummaryCard(
                totalRounds: r.totalRoundsPlayed,
                totalCorrect: r.totalCorrectAnswers,
              ),
              const SizedBox(height: 16),
              _SectionHeader('Temas'),
              _RecordTile(label: 'Mais jogado', value: r.mostPlayedTheme?.name),
              _RecordTile(label: 'Mais vencido', value: r.mostWonTheme?.name),
              _RecordTile(label: 'Mais perdido', value: r.mostLostTheme?.name),
              const SizedBox(height: 8),
              _SectionHeader('Gêneros'),
              _RecordTile(label: 'Mais jogado', value: r.mostPlayedGenre?.name),
              _RecordTile(label: 'Mais vencido', value: r.mostWonGenre?.name),
              _RecordTile(label: 'Mais perdido', value: r.mostLostGenre?.name),
              const SizedBox(height: 8),
              _SectionHeader('Rivais'),
              _RecordTile(label: 'Mais desafiado', value: r.mostChallengedPlayer?.username),
              _RecordTile(label: 'Mais desafiante', value: r.mostChallengingPlayer?.username),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final int totalRounds;
  final int totalCorrect;
  const _SummaryCard({required this.totalRounds, required this.totalCorrect});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _BigStat(label: 'Rodadas', value: '$totalRounds', icon: Icons.sports_esports),
          _BigStat(label: 'Acertos', value: '$totalCorrect', icon: Icons.check_circle_outline),
          _BigStat(
            label: 'Aproveit.',
            value: totalRounds == 0
                ? '—'
                : (totalCorrect / totalRounds).toStringAsFixed(1),
            icon: Icons.trending_up,
          ),
        ],
      ),
    );
  }
}

class _BigStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _BigStat({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 28),
        const SizedBox(height: 6),
        Text(value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _RecordTile extends StatelessWidget {
  final String label;
  final String? value;
  const _RecordTile({required this.label, this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      title: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
      trailing: Text(
        value ?? '—',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: value != null ? AppColors.primary : AppColors.textSecondary,
        ),
      ),
    );
  }
}
