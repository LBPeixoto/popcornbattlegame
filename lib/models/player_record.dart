import 'player.dart';
import 'theme_model.dart';

class PlayerRecord {
  final ThemeModel? mostPlayedTheme;
  final ThemeModel? mostWonTheme;
  final ThemeModel? mostLostTheme;
  final String? mostPlayedQuizType;
  final String? mostWonQuizType;
  final String? mostLostQuizType;
  final Player? mostChallengedPlayer;
  final Player? mostChallengingPlayer;
  final int totalRoundsPlayed;
  final int totalCorrectAnswers;

  const PlayerRecord({
    this.mostPlayedTheme,
    this.mostWonTheme,
    this.mostLostTheme,
    this.mostPlayedQuizType,
    this.mostWonQuizType,
    this.mostLostQuizType,
    this.mostChallengedPlayer,
    this.mostChallengingPlayer,
    required this.totalRoundsPlayed,
    required this.totalCorrectAnswers,
  });

  factory PlayerRecord.fromJson(Map<String, dynamic> json) => PlayerRecord(
        mostPlayedTheme: json['mostPlayedTheme'] != null
            ? ThemeModel.fromJson(json['mostPlayedTheme'] as Map<String, dynamic>)
            : null,
        mostWonTheme: json['mostWonTheme'] != null
            ? ThemeModel.fromJson(json['mostWonTheme'] as Map<String, dynamic>)
            : null,
        mostLostTheme: json['mostLostTheme'] != null
            ? ThemeModel.fromJson(json['mostLostTheme'] as Map<String, dynamic>)
            : null,
        mostPlayedQuizType: json['mostPlayedQuizType'] as String?,
        mostWonQuizType: json['mostWonQuizType'] as String?,
        mostLostQuizType: json['mostLostQuizType'] as String?,
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
