import 'package:flutter/material.dart';
import '../../core/services/api_client.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_theme.dart';
import '../../models/friendship.dart';
import '../../models/player.dart';
import '../../services/challenge_service.dart';
import '../../services/friend_service.dart';
import '../../services/player_service.dart';

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
    try {
      await _challengeService.createChallenge(friend.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Desafio enviado para ${friend.username}!'), backgroundColor: AppColors.correct),
      );
      Navigator.pop(context);
    } on ApiException catch (e) {
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
