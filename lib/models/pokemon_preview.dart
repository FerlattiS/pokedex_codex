class PokemonPreview {
  const PokemonPreview({
    required this.id,
    required this.name,
    this.types = const [],
    this.description = 'Datos disponibles al abrir el detalle.',
    this.height = '-',
    this.weight = '-',
    this.imageUrl,
    this.frontSpriteUrl,
    this.backSpriteUrl,
    this.frontShinySpriteUrl,
    this.backShinySpriteUrl,
    this.abilities = const [],
    this.stats = const [],
    this.moves = const [],
    this.isLegendary = false,
    this.isMythical = false,
    this.evolvesByItem = false,
    this.generation,
    this.speciesColor,
    this.habitat,
    this.region,
    this.formLabel = 'Normal',
    this.evolutionStage = PokemonEvolutionStage.unknown,
    this.evolutionLine = const [],
  });

  final int id;
  final String name;
  final List<String> types;
  final String description;
  final String height;
  final String weight;
  final String? imageUrl;
  final String? frontSpriteUrl;
  final String? backSpriteUrl;
  final String? frontShinySpriteUrl;
  final String? backShinySpriteUrl;
  final List<PokemonAbility> abilities;
  final List<PokemonStat> stats;
  final List<PokemonMoveSummary> moves;
  final bool isLegendary;
  final bool isMythical;
  final bool evolvesByItem;
  final int? generation;
  final String? speciesColor;
  final String? habitat;
  final String? region;
  final String formLabel;
  final PokemonEvolutionStage evolutionStage;
  final List<PokemonEvolutionStep> evolutionLine;

  PokemonPreview copyWith({
    int? id,
    String? name,
    List<String>? types,
    String? description,
    String? height,
    String? weight,
    String? imageUrl,
    String? frontSpriteUrl,
    String? backSpriteUrl,
    String? frontShinySpriteUrl,
    String? backShinySpriteUrl,
    List<PokemonAbility>? abilities,
    List<PokemonStat>? stats,
    List<PokemonMoveSummary>? moves,
    bool? isLegendary,
    bool? isMythical,
    bool? evolvesByItem,
    int? generation,
    String? speciesColor,
    String? habitat,
    String? region,
    String? formLabel,
    PokemonEvolutionStage? evolutionStage,
    List<PokemonEvolutionStep>? evolutionLine,
  }) {
    return PokemonPreview(
      id: id ?? this.id,
      name: name ?? this.name,
      types: types ?? this.types,
      description: description ?? this.description,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      imageUrl: imageUrl ?? this.imageUrl,
      frontSpriteUrl: frontSpriteUrl ?? this.frontSpriteUrl,
      backSpriteUrl: backSpriteUrl ?? this.backSpriteUrl,
      frontShinySpriteUrl: frontShinySpriteUrl ?? this.frontShinySpriteUrl,
      backShinySpriteUrl: backShinySpriteUrl ?? this.backShinySpriteUrl,
      abilities: abilities ?? this.abilities,
      stats: stats ?? this.stats,
      moves: moves ?? this.moves,
      isLegendary: isLegendary ?? this.isLegendary,
      isMythical: isMythical ?? this.isMythical,
      evolvesByItem: evolvesByItem ?? this.evolvesByItem,
      generation: generation ?? this.generation,
      speciesColor: speciesColor ?? this.speciesColor,
      habitat: habitat ?? this.habitat,
      region: region ?? this.region,
      formLabel: formLabel ?? this.formLabel,
      evolutionStage: evolutionStage ?? this.evolutionStage,
      evolutionLine: evolutionLine ?? this.evolutionLine,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'types': types,
      'description': description,
      'height': height,
      'weight': weight,
      'imageUrl': imageUrl,
      'frontSpriteUrl': frontSpriteUrl,
      'backSpriteUrl': backSpriteUrl,
      'frontShinySpriteUrl': frontShinySpriteUrl,
      'backShinySpriteUrl': backShinySpriteUrl,
      'abilities': abilities.map((ability) => ability.toJson()).toList(),
      'stats': stats.map((stat) => stat.toJson()).toList(),
      'moves': moves.map((move) => move.toJson()).toList(),
      'isLegendary': isLegendary,
      'isMythical': isMythical,
      'evolvesByItem': evolvesByItem,
      'generation': generation,
      'speciesColor': speciesColor,
      'habitat': habitat,
      'region': region,
      'formLabel': formLabel,
      'evolutionStage': evolutionStage.name,
      'evolutionLine': evolutionLine.map((step) => step.toJson()).toList(),
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
      frontSpriteUrl: json['frontSpriteUrl'] as String?,
      backSpriteUrl: json['backSpriteUrl'] as String?,
      frontShinySpriteUrl: json['frontShinySpriteUrl'] as String?,
      backShinySpriteUrl: json['backShinySpriteUrl'] as String?,
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
      isLegendary: json['isLegendary'] as bool? ?? false,
      isMythical: json['isMythical'] as bool? ?? false,
      evolvesByItem: json['evolvesByItem'] as bool? ?? false,
      generation: json['generation'] as int?,
      speciesColor: json['speciesColor'] as String?,
      habitat: json['habitat'] as String?,
      region: json['region'] as String?,
      formLabel: json['formLabel'] as String? ?? 'Normal',
      evolutionStage: PokemonEvolutionStage.fromName(
        json['evolutionStage'] as String?,
      ),
      evolutionLine: (json['evolutionLine'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>()
          .map(PokemonEvolutionStep.fromJson)
          .toList(),
    );
  }
}

enum PokemonEvolutionStage {
  unknown,
  standalone,
  base,
  middle,
  finalStage;

  String get label {
    return switch (this) {
      PokemonEvolutionStage.unknown => 'Sin datos',
      PokemonEvolutionStage.standalone => 'Sin evolucion',
      PokemonEvolutionStage.base => 'Base',
      PokemonEvolutionStage.middle => 'Intermedia',
      PokemonEvolutionStage.finalStage => 'Final',
    };
  }

  static PokemonEvolutionStage fromName(String? name) {
    for (final stage in PokemonEvolutionStage.values) {
      if (stage.name == name) {
        return stage;
      }
    }

    return PokemonEvolutionStage.unknown;
  }
}

class PokemonEvolutionStep {
  const PokemonEvolutionStep({
    required this.id,
    required this.name,
    required this.method,
  });

  final int id;
  final String name;
  final String method;

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'method': method};
  }

  factory PokemonEvolutionStep.fromJson(Map<String, dynamic> json) {
    return PokemonEvolutionStep(
      id: json['id'] as int,
      name: json['name'] as String,
      method: json['method'] as String,
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
