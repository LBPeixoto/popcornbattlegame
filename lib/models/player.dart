import 'power_ups.dart';

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is String) return DateTime.tryParse(value);
  if (value is List && value.length >= 6) {
    return DateTime(
      (value[0] as num).toInt(),
      (value[1] as num).toInt(),
      (value[2] as num).toInt(),
      (value[3] as num).toInt(),
      (value[4] as num).toInt(),
      (value[5] as num).toInt(),
    );
  }
  return null;
}

class Player {
  final int id;
  final String username;
  final String? avatarUrl;
  final int wins;
  final int losses;
  final int tickets;
  final int level;
  final int xp;
  final int xpToNext;
  final int coins;
  final PowerUps powerUps;
  final DateTime? nextTicketAt;

  const Player({
    required this.id,
    required this.username,
    this.avatarUrl,
    required this.wins,
    required this.losses,
    required this.tickets,
    required this.level,
    required this.xp,
    required this.xpToNext,
    required this.coins,
    required this.powerUps,
    this.nextTicketAt,
  });

  factory Player.fromJson(Map<String, dynamic> json) => Player(
        id: (json['id'] as num).toInt(),
        username: json['username'] as String,
        avatarUrl: json['avatarUrl'] as String?,
        wins: (json['wins'] as num?)?.toInt() ?? 0,
        losses: (json['losses'] as num?)?.toInt() ?? 0,
        tickets: (json['challengeTickets'] as num?)?.toInt() ?? 0,
        level: (json['level'] as num?)?.toInt() ?? 1,
        xp: (json['xp'] as num?)?.toInt() ?? 0,
        xpToNext: (json['xpToNext'] as num?)?.toInt() ?? 100,
        coins: (json['coins'] as num?)?.toInt() ?? 0,
        powerUps: json['powerUps'] != null
            ? PowerUps.fromJson(json['powerUps'] as Map<String, dynamic>)
            : PowerUps.empty,
        nextTicketAt: _parseDateTime(json['nextTicketAt']),
      );

  int get totalGames => wins + losses;
  double get winRate => totalGames == 0 ? 0 : wins / totalGames;
  double get xpProgress => xpToNext == 0 ? 0 : xp / xpToNext;
}
