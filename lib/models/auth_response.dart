import 'player.dart';

class AuthResponse {
  final String token;
  final Player player;

  AuthResponse({required this.token, required this.player});

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        token: json['token'] as String,
        player: Player.fromJson(json['player'] as Map<String, dynamic>),
      );
}
