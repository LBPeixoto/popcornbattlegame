class PowerUps {
  final int hint;
  final int skip;
  final int shield;

  const PowerUps({
    required this.hint,
    required this.skip,
    required this.shield,
  });

  factory PowerUps.fromJson(Map<String, dynamic> json) => PowerUps(
        hint: (json['hint'] as num?)?.toInt() ?? 0,
        skip: (json['skip'] as num?)?.toInt() ?? 0,
        shield: (json['shield'] as num?)?.toInt() ?? 0,
      );

  static const empty = PowerUps(hint: 0, skip: 0, shield: 0);

  bool get hasAny => hint > 0 || skip > 0 || shield > 0;
}
