class PokemonNote {
  const PokemonNote({
    required this.pokemonId,
    required this.text,
    required this.updatedAt,
  });

  final int pokemonId;
  final String text;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'pokemonId': pokemonId,
      'text': text,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory PokemonNote.fromJson(Map<String, dynamic> json) {
    return PokemonNote(
      pokemonId: json['pokemonId'] as int,
      text: json['text'] as String,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

class PokemonTeam {
  const PokemonTeam({
    required this.id,
    required this.name,
    required this.pokemonIds,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final List<int> pokemonIds;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'pokemonIds': pokemonIds,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory PokemonTeam.fromJson(Map<String, dynamic> json) {
    return PokemonTeam(
      id: json['id'] as String,
      name: json['name'] as String,
      pokemonIds: (json['pokemonIds'] as List<dynamic>).cast<int>(),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
