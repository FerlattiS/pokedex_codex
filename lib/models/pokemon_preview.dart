class PokemonPreview {
  const PokemonPreview({
    required this.id,
    required this.name,
    this.types = const [],
    this.description = 'Datos disponibles al abrir el detalle.',
    this.height = '-',
    this.weight = '-',
    this.imageUrl,
    this.abilities = const [],
    this.stats = const [],
    this.moves = const [],
  });

  final int id;
  final String name;
  final List<String> types;
  final String description;
  final String height;
  final String weight;
  final String? imageUrl;
  final List<PokemonAbility> abilities;
  final List<PokemonStat> stats;
  final List<PokemonMoveSummary> moves;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'types': types,
      'description': description,
      'height': height,
      'weight': weight,
      'imageUrl': imageUrl,
      'abilities': abilities.map((ability) => ability.toJson()).toList(),
      'stats': stats.map((stat) => stat.toJson()).toList(),
      'moves': moves.map((move) => move.toJson()).toList(),
    };
  }

  factory PokemonPreview.fromJson(Map<String, dynamic> json) {
    return PokemonPreview(
      id: json['id'] as int,
      name: json['name'] as String,
      types: (json['types'] as List<dynamic>? ?? []).cast<String>(),
      description:
          json['description'] as String? ??
          'Datos disponibles al abrir el detalle.',
      height: json['height'] as String? ?? '-',
      weight: json['weight'] as String? ?? '-',
      imageUrl: json['imageUrl'] as String?,
      abilities: (json['abilities'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>()
          .map(PokemonAbility.fromJson)
          .toList(),
      stats: (json['stats'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>()
          .map(PokemonStat.fromJson)
          .toList(),
      moves: (json['moves'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>()
          .map(PokemonMoveSummary.fromJson)
          .toList(),
    );
  }
}

class PokemonStat {
  const PokemonStat({required this.name, required this.value});

  final String name;
  final int value;

  Map<String, dynamic> toJson() {
    return {'name': name, 'value': value};
  }

  factory PokemonStat.fromJson(Map<String, dynamic> json) {
    return PokemonStat(
      name: json['name'] as String,
      value: json['value'] as int,
    );
  }
}

class PokemonAbility {
  const PokemonAbility({required this.name, required this.apiName});

  final String name;
  final String apiName;

  Map<String, dynamic> toJson() {
    return {'name': name, 'apiName': apiName};
  }

  factory PokemonAbility.fromJson(Map<String, dynamic> json) {
    return PokemonAbility(
      name: json['name'] as String,
      apiName: json['apiName'] as String,
    );
  }
}

class PokemonMoveSummary {
  const PokemonMoveSummary({
    required this.name,
    required this.apiName,
    required this.learnMethod,
    required this.level,
  });

  final String name;
  final String apiName;
  final String learnMethod;
  final int level;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'apiName': apiName,
      'learnMethod': learnMethod,
      'level': level,
    };
  }

  factory PokemonMoveSummary.fromJson(Map<String, dynamic> json) {
    return PokemonMoveSummary(
      name: json['name'] as String,
      apiName: json['apiName'] as String,
      learnMethod: json['learnMethod'] as String,
      level: json['level'] as int,
    );
  }
}

class PokemonAbilityDetail {
  const PokemonAbilityDetail({
    required this.name,
    required this.englishName,
    required this.description,
    required this.englishDescription,
    required this.technicalDetail,
  });

  final String name;
  final String englishName;
  final String description;
  final String englishDescription;
  final String technicalDetail;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'englishName': englishName,
      'description': description,
      'englishDescription': englishDescription,
      'technicalDetail': technicalDetail,
    };
  }

  factory PokemonAbilityDetail.fromJson(Map<String, dynamic> json) {
    return PokemonAbilityDetail(
      name: json['name'] as String,
      englishName: json['englishName'] as String,
      description: json['description'] as String,
      englishDescription: json['englishDescription'] as String,
      technicalDetail: json['technicalDetail'] as String,
    );
  }
}

class PokemonMoveDetail {
  const PokemonMoveDetail({
    required this.name,
    required this.englishName,
    required this.type,
    required this.damageClass,
    required this.power,
    required this.pp,
    required this.accuracy,
    required this.description,
    required this.technicalDetail,
  });

  final String name;
  final String englishName;
  final String type;
  final String damageClass;
  final int? power;
  final int pp;
  final int? accuracy;
  final String description;
  final String technicalDetail;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'englishName': englishName,
      'type': type,
      'damageClass': damageClass,
      'power': power,
      'pp': pp,
      'accuracy': accuracy,
      'description': description,
      'technicalDetail': technicalDetail,
    };
  }

  factory PokemonMoveDetail.fromJson(Map<String, dynamic> json) {
    return PokemonMoveDetail(
      name: json['name'] as String,
      englishName: json['englishName'] as String,
      type: json['type'] as String,
      damageClass: json['damageClass'] as String,
      power: json['power'] as int?,
      pp: json['pp'] as int,
      accuracy: json['accuracy'] as int?,
      description: json['description'] as String,
      technicalDetail: json['technicalDetail'] as String,
    );
  }
}
