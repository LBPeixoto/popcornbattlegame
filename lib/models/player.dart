class Player {
  final int id;
  final String username;
  final String? avatarUrl;
  final int wins;
  final int losses;

  const Player({
    required this.id,
    required this.username,
    this.avatarUrl,
    required this.wins,
    required this.losses,
  });

  factory Player.fromJson(Map<String, dynamic> json) => Player(
        id: (json['id'] as num).toInt(),
        username: json['username'] as String,
        avatarUrl: json['avatarUrl'] as String?,
        wins: (json['wins'] as num?)?.toInt() ?? 0,
        losses: (json['losses'] as num?)?.toInt() ?? 0,
      );

  int get totalGames => wins + losses;
  double get winRate => totalGames == 0 ? 0 : wins / totalGames;
}
