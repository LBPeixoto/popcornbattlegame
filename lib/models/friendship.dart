import 'player.dart';

class FriendStatus {
  final int id;
  final String username;
  final int wins;
  final int losses;
  final bool hasOpenChallenge;

  const FriendStatus({
    required this.id,
    required this.username,
    required this.wins,
    required this.losses,
    required this.hasOpenChallenge,
  });

  factory FriendStatus.fromJson(Map<String, dynamic> json) => FriendStatus(
        id: (json['id'] as num).toInt(),
        username: json['username'] as String,
        wins: (json['wins'] as num?)?.toInt() ?? 0,
        losses: (json['losses'] as num?)?.toInt() ?? 0,
        hasOpenChallenge: json['hasOpenChallenge'] as bool? ?? false,
      );

  Player toPlayer() => Player(id: id, username: username, wins: wins, losses: losses);
}

class FriendRequest {
  final int friendshipId;
  final Player player;
  final String status;

  const FriendRequest({
    required this.friendshipId,
    required this.player,
    required this.status,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) => FriendRequest(
        friendshipId: (json['friendshipId'] as num).toInt(),
        player: Player.fromJson(json['player'] as Map<String, dynamic>),
        status: json['status'] as String,
      );
}
