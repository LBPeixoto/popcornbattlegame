import 'player.dart';
import 'theme_model.dart';

class RoundAttempt {
  final int correctAnswers;
  final int totalTimeMs;
  final List<bool> questionResults;

  const RoundAttempt({
    required this.correctAnswers,
    required this.totalTimeMs,
    required this.questionResults,
  });

  factory RoundAttempt.fromJson(Map<String, dynamic> json) => RoundAttempt(
        correctAnswers: (json['correctAnswers'] as num).toInt(),
        totalTimeMs: (json['totalTimeMs'] as num).toInt(),
        questionResults: (json['questionResults'] as List<dynamic>)
            .map((e) => e as bool)
            .toList(),
      );
}

class Round {
  final int id;
  final int roundNumber;
  final Player drawer;
  final ThemeModel? theme;
  final String? quizType;
  final String? quizTypeDisplay;
  final int? timeLimitSeconds;
  final String status;
  final String? result;
  final RoundAttempt? drawerAttempt;
  final RoundAttempt? opponentAttempt;

  const Round({
    required this.id,
    required this.roundNumber,
    required this.drawer,
    this.theme,
    this.quizType,
    this.quizTypeDisplay,
    this.timeLimitSeconds,
    required this.status,
    this.result,
    this.drawerAttempt,
    this.opponentAttempt,
  });

  factory Round.fromJson(Map<String, dynamic> json) => Round(
        id: (json['id'] as num).toInt(),
        roundNumber: (json['roundNumber'] as num).toInt(),
        drawer: Player.fromJson(json['drawer'] as Map<String, dynamic>),
        theme: json['theme'] != null
            ? ThemeModel.fromJson(json['theme'] as Map<String, dynamic>)
            : null,
        quizType: json['quizType'] as String?,
        quizTypeDisplay: json['quizTypeDisplay'] as String?,
        timeLimitSeconds: (json['timeLimitSeconds'] as num?)?.toInt(),
        status: json['status'] as String,
        result: json['result'] as String?,
        drawerAttempt: json['drawerAttempt'] != null
            ? RoundAttempt.fromJson(json['drawerAttempt'] as Map<String, dynamic>)
            : null,
        opponentAttempt: json['opponentAttempt'] != null
            ? RoundAttempt.fromJson(json['opponentAttempt'] as Map<String, dynamic>)
            : null,
      );

  bool get isCompleted => status == 'COMPLETED';
  bool get isWaitingDrawer => status == 'WAITING_DRAWER';
  bool get isWaitingOpponent => status == 'WAITING_OPPONENT';
}
