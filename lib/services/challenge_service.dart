import '../core/constants/api_constants.dart';
import '../core/services/api_client.dart';
import '../models/challenge.dart';
import '../models/question.dart';
import '../models/revealed_answer.dart';
import '../models/round.dart';

class AnswerItem {
  final int questionId;
  final int? alternativeId;
  final bool? tfAnswer;
  final List<int>? orderedItemIds;
  final List<String>? listAnswers;
  final String? guessText;
  final int? hintsUsed;

  const AnswerItem({
    required this.questionId,
    this.alternativeId,
    this.tfAnswer,
    this.orderedItemIds,
    this.listAnswers,
    this.guessText,
    this.hintsUsed,
  });

  Map<String, dynamic> toJson() => {
        'questionId': questionId,
        if (alternativeId != null) 'alternativeId': alternativeId,
        if (tfAnswer != null) 'tfAnswer': tfAnswer,
        if (orderedItemIds != null) 'orderedItemIds': orderedItemIds,
        if (listAnswers != null) 'listAnswers': listAnswers,
        if (guessText != null) 'guessText': guessText,
        if (hintsUsed != null) 'hintsUsed': hintsUsed,
      };
}

class ChallengeService {
  final ApiClient _api;

  ChallengeService(this._api);

  Future<List<Challenge>> listChallenges() async {
    final data = await _api.get(ApiConstants.challenges) as List<dynamic>;
    return data.map((e) => Challenge.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Challenge> getChallenge(int id) async {
    final data = await _api.get(ApiConstants.challengeById(id)) as Map<String, dynamic>;
    return Challenge.fromJson(data);
  }

  Future<Challenge> createChallenge(int challengedId) async {
    final data = await _api.post(ApiConstants.challenges, body: {
      'challengedId': challengedId,
    }) as Map<String, dynamic>;
    return Challenge.fromJson(data);
  }

  Future<Round> drawRound(int challengeId, int roundNumber) async {
    final data = await _api.post(ApiConstants.roundDraw(challengeId, roundNumber)) as Map<String, dynamic>;
    return Round.fromJson(data);
  }

  Future<List<Question>> getQuestions(int challengeId, int roundNumber) async {
    final data = await _api.get(ApiConstants.roundQuestions(challengeId, roundNumber)) as List<dynamic>;
    return data.map((e) => Question.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<RevealedAnswer>> getRevealedAnswers(int challengeId, int roundNumber) async {
    final data = await _api.get(ApiConstants.roundRevealed(challengeId, roundNumber)) as List<dynamic>;
    return data.map((e) => RevealedAnswer.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Round> submitAttempt({
    required int challengeId,
    required int roundNumber,
    required int totalTimeMs,
    required List<AnswerItem> answers,
  }) async {
    final data = await _api.post(
      ApiConstants.roundAttempt(challengeId, roundNumber),
      body: {
        'totalTimeMs': totalTimeMs,
        'answers': answers.map((a) => a.toJson()).toList(),
      },
    ) as Map<String, dynamic>;
    return Round.fromJson(data);
  }
}
