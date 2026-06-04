class ThemeModel {
  final int id;
  final String name;
  final String type;

  const ThemeModel({required this.id, required this.name, required this.type});

  factory ThemeModel.fromJson(Map<String, dynamic> json) => ThemeModel(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String,
        type: json['type'] as String,
      );

  String get typeLabel => switch (type) {
        'DECADE' => 'Década',
        'MEDIA' => 'Mídia',
        'GENRE' => 'Gênero',
        _ => type,
      };
}
