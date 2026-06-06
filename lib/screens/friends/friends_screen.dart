import 'package:flutter/material.dart';
import '../../core/services/api_client.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_theme.dart';
import '../../models/friendship.dart';
import '../../models/player.dart';
import '../../services/challenge_service.dart';
import '../../services/friend_service.dart';
import '../../services/player_service.dart';

enum _TicketAction { buyWithCoins, watchAd }

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  late FriendService _friendService;
  late PlayerService _playerService;
  late ChallengeService _challengeService;
  late int _myId;
  Player? _me;

  late Future<List<FriendStatus>> _friendsFuture;
  late Future<List<FriendRequest>> _pendingFuture;

  final _searchCtrl = TextEditingController();
  List<Player>? _searchResults;
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _setup();
  }

  Future<void> _setup() async {
    final storage = await StorageService.getInstance();
    _myId = storage.playerId ?? 0;
    final api = ApiClient(storage);
    _friendService = FriendService(api);
    _playerService = PlayerService(api);
    _challengeService = ChallengeService(api);
    _refresh();
    _playerService.getMe().then((p) {
      if (mounted) setState(() => _me = p);
    }).catchError((_) {});
  }

  void _refresh() {
    setState(() {
      _friendsFuture = _friendService.listFriends();
      _pendingFuture = _friendService.listPending();
    });
  }

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) {
      setState(() => _searchResults = null);
      return;
    }
    setState(() => _searching = true);
    try {
      final results = await _playerService.search(q.trim());
      setState(() => _searchResults = results.where((p) => p.id != _myId).toList());
    } finally {
      setState(() => _searching = false);
    }
  }

  Future<void> _sendRequest(Player player) async {
    try {
      await _friendService.sendRequest(player.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pedido enviado para ${player.username}'), backgroundColor: AppColors.correct),
      );
      _refresh();
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.wrong),
      );
    }
  }

  Future<void> _accept(FriendRequest req) async {
    await _friendService.accept(req.friendshipId);
    _refresh();
  }

  Future<void> _reject(FriendRequest req) async {
    await _friendService.reject(req.friendshipId);
    _refresh();
  }

  Future<void> _challenge(FriendStatus friend) async {
    if (_me != null && _me!.tickets <= 0) {
      final action = await showDialog<_TicketAction>(
        context: context,
        builder: (_) => _NoTicketDialog(coins: _me!.coins),
      );
      if (action == null || !mounted) return;
      if (action == _TicketAction.buyWithCoins) {
        await _buyTicketAndChallenge(friend);
      } else {
        _watchAdAndChallenge(friend);
      }
      return;
    }
    await _doChallenge(friend);
  }

  Future<void> _buyTicketAndChallenge(FriendStatus friend) async {
    if (_me!.coins < 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Moedas insuficientes.'), backgroundColor: AppColors.wrong),
      );
      return;
    }
    try {
      final updated = await _playerService.buyTicketWithCoins();
      if (!mounted) return;
      setState(() => _me = updated);
      await _doChallenge(friend);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.wrong),
      );
    }
  }

  void _watchAdAndChallenge(FriendStatus friend) {
    // TODO: integrar SDK de anúncios e chamar _doChallenge(friend) ao concluir
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Anúncios em breve!'), backgroundColor: AppColors.surface),
    );
  }

  Future<void> _doChallenge(FriendStatus friend) async {
    try {
      await _challengeService.createChallenge(friend.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Desafio enviado para ${friend.username}!'), backgroundColor: AppColors.correct),
      );
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.wrong),
      );
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Amigos'),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'Meus amigos'),
            Tab(text: 'Pendentes'),
          ],
        ),
      ),
      body: Column(
        children: [
          _SearchBar(
            controller: _searchCtrl,
            searching: _searching,
            onSearch: _search,
            results: _searchResults,
            onSendRequest: _sendRequest,
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _FriendsList(future: _friendsFuture, onChallenge: _challenge),
                _PendingList(future: _pendingFuture, onAccept: _accept, onReject: _reject),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final bool searching;
  final void Function(String) onSearch;
  final List<Player>? results;
  final void Function(Player) onSendRequest;

  const _SearchBar({
    required this.controller,
    required this.searching,
    required this.onSearch,
    required this.results,
    required this.onSendRequest,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: [
          TextField(
            controller: controller,
            onChanged: onSearch,
            decoration: InputDecoration(
              hintText: 'Buscar jogador...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searching
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : null,
            ),
          ),
          if (results != null) ...[
            const SizedBox(height: 8),
            if (results!.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Nenhum jogador encontrado', style: TextStyle(color: AppColors.textSecondary)),
              )
            else
              ...results!.map((p) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.card,
                      child: Icon(Icons.person, color: AppColors.textSecondary),
                    ),
                    title: Text(p.username),
                    subtitle: Text('${p.wins}V ${p.losses}D'),
                    trailing: ElevatedButton(
                      onPressed: () => onSendRequest(p),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(80, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: const Text('Adicionar'),
                    ),
                  )),
            const Divider(),
          ],
        ],
      ),
    );
  }
}

class _FriendsList extends StatelessWidget {
  final Future<List<FriendStatus>> future;
  final void Function(FriendStatus) onChallenge;

  const _FriendsList({required this.future, required this.onChallenge});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<FriendStatus>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final friends = snapshot.data ?? [];
        if (friends.isEmpty) {
          return const Center(
            child: Text('Nenhum amigo ainda.\nBusque jogadores para adicionar.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
          );
        }
        return ListView.builder(
          itemCount: friends.length,
          itemBuilder: (_, i) {
            final f = friends[i];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.card,
                child: Text(f.username[0].toUpperCase(), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
              title: Text(f.username),
              subtitle: Text('${f.wins}V ${f.losses}D'),
              trailing: f.hasOpenChallenge
                  ? const Chip(
                      label: Text('Em batalha', style: TextStyle(fontSize: 11)),
                      backgroundColor: AppColors.card,
                    )
                  : ElevatedButton(
                      onPressed: () => onChallenge(f),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(90, 34),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        textStyle: const TextStyle(fontSize: 13),
                      ),
                      child: const Text('Desafiar'),
                    ),
            );
          },
        );
      },
    );
  }
}

class _NoTicketDialog extends StatelessWidget {
  final int coins;
  const _NoTicketDialog({required this.coins});

  @override
  Widget build(BuildContext context) {
    final canAfford = coins >= 50;
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Row(
        children: [
          Icon(Icons.confirmation_num, color: AppColors.primary),
          SizedBox(width: 8),
          Text('Sem tickets!'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Você não tem tickets para criar um novo desafio.'),
          const SizedBox(height: 16),
          const Text('Como deseja obter um ticket?',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 12),
          _OptionTile(
            icon: Icons.monetization_on,
            iconColor: AppColors.secondary,
            title: 'Comprar por 50 moedas',
            subtitle: 'Você tem $coins moedas${canAfford ? '' : ' (insuficiente)'}',
            enabled: canAfford,
            onTap: () => Navigator.pop(context, _TicketAction.buyWithCoins),
          ),
          const SizedBox(height: 8),
          _OptionTile(
            icon: Icons.play_circle_outline,
            iconColor: AppColors.primary,
            title: 'Assistir propaganda',
            subtitle: 'Ganhe 1 ticket gratuito',
            enabled: true,
            onTap: () => Navigator.pop(context, _TicketAction.watchAd),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
        ),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(subtitle,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingList extends StatelessWidget {
  final Future<List<FriendRequest>> future;
  final void Function(FriendRequest) onAccept;
  final void Function(FriendRequest) onReject;

  const _PendingList({required this.future, required this.onAccept, required this.onReject});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<FriendRequest>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final pending = snapshot.data ?? [];
        if (pending.isEmpty) {
          return const Center(
            child: Text('Nenhuma solicitação pendente.', style: TextStyle(color: AppColors.textSecondary)),
          );
        }
        return ListView.builder(
          itemCount: pending.length,
          itemBuilder: (_, i) {
            final req = pending[i];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.card,
                child: Text(req.player.username[0].toUpperCase(), style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold)),
              ),
              title: Text(req.player.username),
              subtitle: const Text('Quer ser seu amigo'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check_circle, color: AppColors.correct),
                    onPressed: () => onAccept(req),
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel, color: AppColors.wrong),
                    onPressed: () => onReject(req),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
