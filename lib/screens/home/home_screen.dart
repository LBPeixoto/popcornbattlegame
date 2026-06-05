import 'package:flutter/material.dart';
import '../../core/services/api_client.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_theme.dart';
import '../../models/challenge.dart';
import '../../models/player.dart';
import '../../services/auth_service.dart';
import '../../services/player_service.dart';
import '../../services/challenge_service.dart';
import '../../widgets/challenge_card.dart';
import '../auth/login_screen.dart';
import '../challenge/challenge_detail_screen.dart';
import '../friends/friends_screen.dart';
import '../player/profile_screen.dart';
import '../player/privacy_screen.dart';
import '../player/records_screen.dart';
import '../suggestions/suggest_question_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  late Future<List<Challenge>> _challengesFuture;
  late ChallengeService _challengeService;
  late PlayerService _playerService;
  late StorageService _storage;
  late int _myId;
  late String _username;
  Player? _player;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _init();
  }

  Future<void> _init() async {
    _storage = await StorageService.getInstance();
    _myId = _storage.playerId ?? 0;
    _username = _storage.username ?? '';
    final api = ApiClient(_storage);
    _challengeService = ChallengeService(api);
    _playerService = PlayerService(api);
    _refresh();
    _playerService.getMe().then((p) {
      if (mounted) setState(() => _player = p);
    }).catchError((_) {});
  }

  void _refresh() {
    setState(() {
      _challengesFuture = _challengeService.listChallenges();
    });
  }

  Future<void> _logout() async {
    final storage = await StorageService.getInstance();
    final api = ApiClient(storage);
    await AuthService(api, storage).logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _AppDrawer(
        username: _username,
        myId: _myId,
        player: _player,
        onLogout: _logout,
      ),
      appBar: AppBar(
        title: Column(
          children: [
            const Text('🍿 POPCORN BATTLE', style: TextStyle(fontSize: 16)),
            Text('Olá, $_username', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.people_outline),
            tooltip: 'Amigos',
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const FriendsScreen()));
              _refresh();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'Em andamento'),
            Tab(text: 'Concluídos'),
          ],
        ),
      ),
      body: FutureBuilder<List<Challenge>>(
        future: _challengesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorState(error: '${snapshot.error}', onRetry: _refresh);
          }
          final all = snapshot.data ?? [];
          final active = all.where((c) => c.isInProgress).toList();
          final done = all.where((c) => c.isCompleted).toList();

          return TabBarView(
            controller: _tabs,
            children: [
              _ChallengeList(
                challenges: active,
                myId: _myId,
                emptyMessage: 'Nenhum desafio em andamento.\nDesafie um amigo!',
                onTap: (c) async {
                  await Navigator.push(context, MaterialPageRoute(
                    builder: (_) => ChallengeDetailScreen(challengeId: c.id),
                  ));
                  _refresh();
                },
              ),
              _ChallengeList(
                challenges: done,
                myId: _myId,
                emptyMessage: 'Nenhuma batalha concluída ainda.',
                onTap: (c) => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => ChallengeDetailScreen(challengeId: c.id),
                )),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const FriendsScreen()));
          _refresh();
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Novo Desafio', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

class _ChallengeList extends StatelessWidget {
  final List<Challenge> challenges;
  final int myId;
  final String emptyMessage;
  final void Function(Challenge) onTap;

  const _ChallengeList({
    required this.challenges,
    required this.myId,
    required this.emptyMessage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (challenges.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🍿', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {},
      child: ListView.builder(
        itemCount: challenges.length,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemBuilder: (_, i) => ChallengeCard(
          challenge: challenges[i],
          myId: myId,
          onTap: () => onTap(challenges[i]),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(error, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Tentar novamente')),
          ],
        ),
      ),
    );
  }
}

class _AppDrawer extends StatelessWidget {
  final String username;
  final int myId;
  final Player? player;
  final VoidCallback onLogout;

  const _AppDrawer({
    required this.username,
    required this.myId,
    required this.player,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AppColors.surface),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primary,
                      child: Icon(Icons.person, color: Colors.white, size: 28),
                    ),
                    const Spacer(),
                    if (player != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Nível ${player!.level}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(username,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Text('🍿 Popcorn Battle',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                if (player != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.confirmation_num_outlined,
                          size: 13, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text('${player!.tickets} tickets',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(width: 12),
                      const Icon(Icons.monetization_on_outlined,
                          size: 13, color: AppColors.secondary),
                      const SizedBox(width: 4),
                      Text('${player!.coins} moedas',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Editar Perfil'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart_outlined),
            title: const Text('Meus Recordes'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RecordsScreen(playerId: myId, playerName: username),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Privacidade'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyScreen()));
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.lightbulb_outline),
            title: const Text('Sugerir Pergunta'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SuggestQuestionScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sair', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              onLogout();
            },
          ),
        ],
      ),
    );
  }
}
