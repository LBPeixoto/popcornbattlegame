import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'suggest_mc_screen.dart';
import 'suggest_tf_screen.dart';
import 'suggest_ordering_screen.dart';
import 'suggest_list_screen.dart';

class SuggestQuestionScreen extends StatelessWidget {
  const SuggestQuestionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sugerir Pergunta')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Escolha o tipo de pergunta que deseja sugerir. Sua sugestão será avaliada antes de entrar no jogo.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          _TypeCard(
            icon: Icons.radio_button_checked,
            title: 'Múltipla Escolha',
            subtitle: 'Uma pergunta com 4 alternativas',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SuggestMcScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _TypeCard(
            icon: Icons.check_circle_outline,
            title: 'Verdadeiro ou Falso',
            subtitle: 'Uma afirmação para julgar',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SuggestTfScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _TypeCard(
            icon: Icons.swap_vert,
            title: 'Ordenação',
            subtitle: 'Itens para colocar na ordem certa',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SuggestOrderingScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _TypeCard(
            icon: Icons.list_alt,
            title: 'Lista',
            subtitle: 'Respostas abertas para completar uma lista',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SuggestListScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _TypeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
