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
}

class PokemonStat {
  const PokemonStat({required this.name, required this.value});

  final String name;
  final int value;
}

class PokemonAbility {
  const PokemonAbility({required this.name, required this.apiName});

  final String name;
  final String apiName;
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
}
