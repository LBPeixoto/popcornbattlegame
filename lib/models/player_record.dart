import 'player.dart';
import 'theme_model.dart';

class PlayerRecord {
  final ThemeModel? mostPlayedTheme;
  final ThemeModel? mostPlayedGenre;
  final ThemeModel? mostWonTheme;
  final ThemeModel? mostWonGenre;
  final ThemeModel? mostLostTheme;
  final ThemeModel? mostLostGenre;
  final Player? mostChallengedPlayer;
  final Player? mostChallengingPlayer;
  final int totalRoundsPlayed;
  final int totalCorrectAnswers;

  const PlayerRecord({
    this.mostPlayedTheme,
    this.mostPlayedGenre,
    this.mostWonTheme,
    this.mostWonGenre,
    this.mostLostTheme,
    this.mostLostGenre,
    this.mostChallengedPlayer,
    this.mostChallengingPlayer,
    required this.totalRoundsPlayed,
    required this.totalCorrectAnswers,
  });

  factory PlayerRecord.fromJson(Map<String, dynamic> json) => PlayerRecord(
        mostPlayedTheme: json['mostPlayedTheme'] != null
            ? ThemeModel.fromJson(json['mostPlayedTheme'] as Map<String, dynamic>)
            : null,
        mostPlayedGenre: json['mostPlayedGenre'] != null
            ? ThemeModel.fromJson(json['mostPlayedGenre'] as Map<String, dynamic>)
            : null,
        mostWonTheme: json['mostWonTheme'] != null
            ? ThemeModel.fromJson(json['mostWonTheme'] as Map<String, dynamic>)
            : null,
        mostWonGenre: json['mostWonGenre'] != null
            ? ThemeModel.fromJson(json['mostWonGenre'] as Map<String, dynamic>)
            : null,
        mostLostTheme: json['mostLostTheme'] != null
            ? ThemeModel.fromJson(json['mostLostTheme'] as Map<String, dynamic>)
            : null,
        mostLostGenre: json['mostLostGenre'] != null
            ? ThemeModel.fromJson(json['mostLostGenre'] as Map<String, dynamic>)
            : null,
        mostChallengedPlayer: json['mostChallengedPlayer'] != null
            ? Player.fromJson(json['mostChallengedPlayer'] as Map<String, dynamic>)
            : null,
        mostChallengingPlayer: json['mostChallengingPlayer'] != null
            ? Player.fromJson(json['mostChallengingPlayer'] as Map<String, dynamic>)
            : null,
        totalRoundsPlayed: (json['totalRoundsPlayed'] as num).toInt(),
        totalCorrectAnswers: (json['totalCorrectAnswers'] as num).toInt(),
      );
}
