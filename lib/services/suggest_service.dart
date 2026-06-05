import '../core/constants/api_constants.dart';
import '../core/services/api_client.dart';
import '../models/theme_model.dart';

class ThemeCatalog {
  final List<ThemeModel> decades;
  final List<ThemeModel> medias;
  final List<ThemeModel> genres;

  const ThemeCatalog({
    required this.decades,
    required this.medias,
    required this.genres,
  });

  factory ThemeCatalog.fromJson(Map<String, dynamic> json) => ThemeCatalog(
        decades: (json['decades'] as List<dynamic>)
            .map((e) => ThemeModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        medias: (json['medias'] as List<dynamic>)
            .map((e) => ThemeModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        genres: (json['genres'] as List<dynamic>)
            .map((e) => ThemeModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class AlternativeInput {
  String text;
  bool correct;
  AlternativeInput({this.text = '', this.correct = false});
}

class SuggestService {
  final ApiClient _api;

  SuggestService(this._api);

  Future<ThemeCatalog> getThemes() async {
    final data = await _api.get(ApiConstants.themes) as Map<String, dynamic>;
    return ThemeCatalog.fromJson(data);
  }

  Future<void> suggestMultipleChoice({
    required String statement,
    String? imageUrl,
    int? decadeId,
    int? mediaId,
    required List<int> genreIds,
    required List<AlternativeInput> alternatives,
  }) async {
    await _api.post(ApiConstants.suggestMc, body: {
      'statement': statement,
      'imageUrl': imageUrl,
      'decadeId': decadeId,
      'mediaId': mediaId,
      'genreIds': genreIds,
      'alternatives': alternatives
          .map((a) => {'text': a.text, 'correct': a.correct})
          .toList(),
    });
  }

  Future<void> suggestTrueFalse({
    required String statement,
    String? imageUrl,
    int? decadeId,
    int? mediaId,
    required List<int> genreIds,
    required bool correctAnswer,
  }) async {
    await _api.post(ApiConstants.suggestTf, body: {
      'statement': statement,
      'imageUrl': imageUrl,
      'decadeId': decadeId,
      'mediaId': mediaId,
      'genreIds': genreIds,
      'correctAnswer': correctAnswer,
    });
  }

  Future<void> suggestOrdering({
    required String statement,
    String? imageUrl,
    int? decadeId,
    int? mediaId,
    required List<int> genreIds,
    required List<String> items,
  }) async {
    await _api.post(ApiConstants.suggestOrdering, body: {
      'statement': statement,
      'imageUrl': imageUrl,
      'decadeId': decadeId,
      'mediaId': mediaId,
      'genreIds': genreIds,
      'items': items,
    });
  }

  Future<void> suggestList({
    required String statement,
    String? imageUrl,
    int? decadeId,
    int? mediaId,
    required List<int> genreIds,
    required List<String> answers,
  }) async {
    await _api.post(ApiConstants.suggestList, body: {
      'statement': statement,
      'imageUrl': imageUrl,
      'decadeId': decadeId,
      'mediaId': mediaId,
      'genreIds': genreIds,
      'answers': answers,
    });
  }
}
