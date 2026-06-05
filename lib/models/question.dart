import 'theme_model.dart';

class Alternative {
  final int id;
  final String text;

  const Alternative({required this.id, required this.text});

  factory Alternative.fromJson(Map<String, dynamic> json) => Alternative(
        id: (json['id'] as num).toInt(),
        text: json['text'] as String,
      );
}

class OrderingItem {
  final int id;
  final String text;

  const OrderingItem({required this.id, required this.text});

  factory OrderingItem.fromJson(Map<String, dynamic> json) => OrderingItem(
        id: (json['id'] as num).toInt(),
        text: json['text'] as String,
      );
}

class Question {
  final int id;
  final String statement;
  final String? imageUrl;
  final String quizType;
  final int timeLimitSeconds;
  final ThemeModel decade;
  final ThemeModel media;
  final List<ThemeModel> genres;
  // Multiple choice
  final List<Alternative>? alternatives;
  // Ordering
  final List<OrderingItem>? items;
  // List
  final int? totalAnswers;
  final List<String>? listAnswers;

  const Question({
    required this.id,
    required this.statement,
    this.imageUrl,
    required this.quizType,
    required this.timeLimitSeconds,
    required this.decade,
    required this.media,
    required this.genres,
    this.alternatives,
    this.items,
    this.totalAnswers,
    this.listAnswers,
  });

  factory Question.fromJson(Map<String, dynamic> json) => Question(
        id: (json['id'] as num).toInt(),
        statement: json['statement'] as String,
        imageUrl: json['imageUrl'] as String?,
        quizType: json['quizType'] as String,
        timeLimitSeconds: (json['timeLimitSeconds'] as num).toInt(),
        decade: ThemeModel.fromJson(json['decade'] as Map<String, dynamic>),
        media: ThemeModel.fromJson(json['media'] as Map<String, dynamic>),
        genres: (json['genres'] as List<dynamic>?)
                ?.map((e) => ThemeModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        alternatives: (json['alternatives'] as List<dynamic>?)
            ?.map((e) => Alternative.fromJson(e as Map<String, dynamic>))
            .toList(),
        items: (json['items'] as List<dynamic>?)
            ?.map((e) => OrderingItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        totalAnswers: (json['totalAnswers'] as num?)?.toInt(),
        listAnswers: (json['listAnswers'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList(),
      );
}
