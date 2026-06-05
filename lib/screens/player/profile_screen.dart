import 'package:flutter/material.dart';
import '../../core/services/api_client.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_theme.dart';
import '../../models/player.dart';
import '../../services/player_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _avatarCtrl = TextEditingController();

  late PlayerService _playerService;
  Player? _current;
  bool _loading = true;
  bool _saving = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final storage = await StorageService.getInstance();
    _playerService = PlayerService(ApiClient(storage));
    final player = await _playerService.getMe();
    setState(() {
      _current = player;
      _usernameCtrl.text = player.username;
      _avatarCtrl.text = player.avatarUrl ?? '';
      _loading = false;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final updated = await _playerService.updateProfile(
        username: _usernameCtrl.text.trim().isEmpty ? null : _usernameCtrl.text.trim(),
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        password: _passwordCtrl.text.isEmpty ? null : _passwordCtrl.text,
        avatarUrl: _avatarCtrl.text.trim().isEmpty ? null : _avatarCtrl.text.trim(),
      );
      if (!mounted) return;
      setState(() => _current = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil atualizado!'), backgroundColor: AppColors.primary),
      );
      _passwordCtrl.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _avatarCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Perfil')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _AvatarPreview(url: _avatarCtrl.text),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _usernameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nome de usuário',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) => v != null && v.trim().length < 3 && v.trim().isNotEmpty
                          ? 'Mínimo 3 caracteres'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Novo e-mail (opcional)',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordCtrl,
                      decoration: InputDecoration(
                        labelText: 'Nova senha (opcional)',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      obscureText: _obscurePassword,
                      validator: (v) => v != null && v.isNotEmpty && v.length < 6
                          ? 'Mínimo 6 caracteres'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _avatarCtrl,
                      decoration: const InputDecoration(
                        labelText: 'URL do avatar (opcional)',
                        prefixIcon: Icon(Icons.image_outlined),
                      ),
                      keyboardType: TextInputType.url,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Salvar alterações'),
                    ),
                    const SizedBox(height: 12),
                    _StatRow(player: _current!),
                  ],
                ),
              ),
            ),
    );
  }
}

class _AvatarPreview extends StatelessWidget {
  final String url;
  const _AvatarPreview({required this.url});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircleAvatar(
        radius: 48,
        backgroundColor: AppColors.surface,
        backgroundImage: url.isNotEmpty ? NetworkImage(url) : null,
        child: url.isEmpty
            ? const Icon(Icons.person, size: 48, color: AppColors.textSecondary)
            : null,
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final Player player;
  const _StatRow({required this.player});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _LevelCard(player: player),
        const SizedBox(height: 12),
        _ResourceRow(player: player),
        const SizedBox(height: 12),
        _WinRow(player: player),
        if (player.powerUps.hasAny) ...[
          const SizedBox(height: 12),
          _PowerUpsCard(player: player),
        ],
      ],
    );
  }
}

class _LevelCard extends StatelessWidget {
  final Player player;
  const _LevelCard({required this.player});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Nível ${player.level}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${player.xp} / ${player.xpToNext} XP',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: player.xpProgress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: AppColors.card,
              valueColor: const AlwaysStoppedAnimation(AppColors.secondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResourceRow extends StatelessWidget {
  final Player player;
  const _ResourceRow({required this.player});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ResourceCard(
            icon: Icons.confirmation_num_outlined,
            label: 'Tickets',
            value: '${player.tickets}',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ResourceCard(
            icon: Icons.monetization_on_outlined,
            label: 'Moedas',
            value: '${player.coins}',
            color: AppColors.secondary,
          ),
        ),
      ],
    );
  }
}

class _ResourceCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _ResourceCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              Text(label,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _WinRow extends StatelessWidget {
  final Player player;
  const _WinRow({required this.player});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Stat(label: 'Vitórias', value: '${player.wins}', color: Colors.green),
          _Stat(label: 'Derrotas', value: '${player.losses}', color: Colors.red),
          _Stat(
            label: 'Aproveit.',
            value: '${(player.winRate * 100).toStringAsFixed(0)}%',
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _PowerUpsCard extends StatelessWidget {
  final Player player;
  const _PowerUpsCard({required this.player});

  @override
  Widget build(BuildContext context) {
    final pu = player.powerUps;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Power-ups',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              if (pu.hint > 0)
                _PowerUpChip(icon: Icons.lightbulb_outline, label: 'Dica', count: pu.hint),
              if (pu.skip > 0)
                _PowerUpChip(icon: Icons.skip_next_outlined, label: 'Pular', count: pu.skip),
              if (pu.shield > 0)
                _PowerUpChip(icon: Icons.shield_outlined, label: 'Escudo', count: pu.shield),
            ],
          ),
        ],
      ),
    );
  }
}

class _PowerUpChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  const _PowerUpChip({required this.icon, required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.card,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.secondary, size: 22),
            ),
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Stat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}
