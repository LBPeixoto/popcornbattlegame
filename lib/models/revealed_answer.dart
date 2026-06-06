class RevealedAnswer {
  final int questionId;
  final String quizType;
  final int? correctAlternativeId;
  final bool? correctTfAnswer;
  final List<int>? correctItemIds;
  final List<String>? validAnswers;

  const RevealedAnswer({
    required this.questionId,
    required this.quizType,
    this.correctAlternativeId,
    this.correctTfAnswer,
    this.correctItemIds,
    this.validAnswers,
  });

  factory RevealedAnswer.fromJson(Map<String, dynamic> json) => RevealedAnswer(
        questionId: (json['questionId'] as num).toInt(),
        quizType: json['quizType'] as String,
        correctAlternativeId: (json['correctAlternativeId'] as num?)?.toInt(),
        correctTfAnswer: json['correctTfAnswer'] as bool?,
        correctItemIds: (json['correctItemIds'] as List<dynamic>?)
            ?.map((e) => (e as num).toInt())
            .toList(),
        validAnswers: (json['validAnswers'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList(),
      );
}
