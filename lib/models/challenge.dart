import 'player.dart';
import 'round.dart';

class Challenge {
  final int id;
  final Player challenger;
  final Player challenged;
  final String status;
  final String? result;
  final bool myTurn;
  final Round? currentRound;
  final List<Round> rounds;
  final String createdAt;

  const Challenge({
    required this.id,
    required this.challenger,
    required this.challenged,
    required this.status,
    this.result,
    required this.myTurn,
    this.currentRound,
    required this.rounds,
    required this.createdAt,
  });

  factory Challenge.fromJson(Map<String, dynamic> json) => Challenge(
        id: (json['id'] as num).toInt(),
        challenger: Player.fromJson(json['challenger'] as Map<String, dynamic>),
        challenged: Player.fromJson(json['challenged'] as Map<String, dynamic>),
        status: json['status'] as String,
        result: json['result'] as String?,
        myTurn: json['myTurn'] as bool? ?? false,
        currentRound: json['currentRound'] != null
            ? Round.fromJson(json['currentRound'] as Map<String, dynamic>)
            : null,
        rounds: (json['rounds'] as List<dynamic>?)
                ?.map((e) => Round.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        createdAt: json['createdAt']?.toString() ?? '',
      );

  bool get isCompleted => status == 'COMPLETED';
  bool get isInProgress => status == 'IN_PROGRESS';

  Player opponent(int myId) =>
      challenger.id == myId ? challenged : challenger;

  String resultLabel(int myId) {
    if (result == null) return '';
    if (result == 'DRAW') return 'Empate';
    final winnerId = result == 'CHALLENGER_WIN'
        ? challenger.id
        : challenged.id;
    return winnerId == myId ? 'Você venceu!' : 'Você perdeu';
  }
}
