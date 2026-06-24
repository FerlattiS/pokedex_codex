import 'pokemon_preview.dart';

class PokemonQuestionDefinition {
  const PokemonQuestionDefinition({
    required this.id,
    required this.category,
    required this.label,
    required this.answer,
  });

  final String id;
  final String category;
  final String label;
  final bool Function(PokemonPreview pokemon) answer;
}

List<PokemonQuestionDefinition> buildPokemonQuestions() {
  return [
    for (var generation = 1; generation <= 9; generation++)
      PokemonQuestionDefinition(
        id: 'generation-$generation',
        category: 'Generacion',
        label: 'Pertenece a la generacion $generation?',
        answer: (pokemon) =>
            (pokemon.generation ?? _generationFromId(pokemon.id)) == generation,
      ),
    for (var generation = 2; generation <= 9; generation++)
      PokemonQuestionDefinition(
        id: 'before-generation-$generation',
        category: 'Generacion',
        label: 'Salio antes de la generacion $generation?',
        answer: (pokemon) =>
            (pokemon.generation ?? _generationFromId(pokemon.id)) < generation,
      ),
    for (var generation = 1; generation <= 8; generation++)
      PokemonQuestionDefinition(
        id: 'after-generation-$generation',
        category: 'Generacion',
        label: 'Salio despues de la generacion $generation?',
        answer: (pokemon) =>
            (pokemon.generation ?? _generationFromId(pokemon.id)) > generation,
      ),
    for (final type in _pokemonTypes)
      PokemonQuestionDefinition(
        id: 'type-$type',
        category: 'Tipo',
        label: 'Es de tipo $type?',
        answer: (pokemon) => pokemon.types.contains(type),
      ),
    for (final color in _pokemonColors)
      PokemonQuestionDefinition(
        id: 'color-$color',
        category: 'Color',
        label: 'Su color principal es $color?',
        answer: (pokemon) => pokemon.speciesColor == color,
      ),
    for (final region in _pokemonRegions)
      PokemonQuestionDefinition(
        id: 'region-$region',
        category: 'Region',
        label: 'Pertenece a la region de $region?',
        answer: (pokemon) => pokemon.region == region,
      ),
    for (final habitat in _pokemonHabitats)
      PokemonQuestionDefinition(
        id: 'habitat-$habitat',
        category: 'Habitat',
        label: 'Su habitat habitual es $habitat?',
        answer: (pokemon) => pokemon.habitat == habitat,
      ),
    PokemonQuestionDefinition(
      id: 'dual-type',
      category: 'Tipo',
      label: 'Tiene doble tipo?',
      answer: (pokemon) => pokemon.types.length >= 2,
    ),
    PokemonQuestionDefinition(
      id: 'mono-type',
      category: 'Tipo',
      label: 'Es monotipo?',
      answer: (pokemon) => pokemon.types.length == 1,
    ),
    PokemonQuestionDefinition(
      id: 'legendary',
      category: 'Rareza',
      label: 'Es legendario?',
      answer: (pokemon) => pokemon.isLegendary,
    ),
    PokemonQuestionDefinition(
      id: 'mythical',
      category: 'Rareza',
      label: 'Es mitico?',
      answer: (pokemon) => pokemon.isMythical,
    ),
    PokemonQuestionDefinition(
      id: 'item-evolution',
      category: 'Evolucion',
      label: 'Evoluciona por objeto?',
      answer: (pokemon) => pokemon.evolvesByItem,
    ),
    PokemonQuestionDefinition(
      id: 'has-evolution',
      category: 'Evolucion',
      label: 'Tiene linea evolutiva?',
      answer: (pokemon) => pokemon.evolutionLine.length > 1,
    ),
    PokemonQuestionDefinition(
      id: 'final-stage',
      category: 'Evolucion',
      label: 'Es etapa final?',
      answer: (pokemon) =>
          pokemon.evolutionStage == PokemonEvolutionStage.finalStage ||
          pokemon.evolutionStage == PokemonEvolutionStage.standalone,
    ),
    PokemonQuestionDefinition(
      id: 'alternative-form',
      category: 'Forma',
      label: 'Es una forma alternativa?',
      answer: (pokemon) => pokemon.formLabel != 'Normal',
    ),
    for (var stage = 1; stage <= 3; stage++)
      PokemonQuestionDefinition(
        id: 'stage-$stage',
        category: 'Evolucion',
        label: 'Es etapa evolutiva $stage?',
        answer: (pokemon) => _stageNumber(pokemon) == stage,
      ),
    PokemonQuestionDefinition(
      id: 'height-small',
      category: 'Altura',
      label: 'Mide menos de 1 metro?',
      answer: (pokemon) => (_metricValue(pokemon.height) ?? 999) < 1,
    ),
    PokemonQuestionDefinition(
      id: 'height-large',
      category: 'Altura',
      label: 'Mide 2 metros o mas?',
      answer: (pokemon) => (_metricValue(pokemon.height) ?? 0) >= 2,
    ),
    PokemonQuestionDefinition(
      id: 'weight-light',
      category: 'Peso',
      label: 'Pesa menos de 20 kg?',
      answer: (pokemon) => (_metricValue(pokemon.weight) ?? 999) < 20,
    ),
    PokemonQuestionDefinition(
      id: 'weight-heavy',
      category: 'Peso',
      label: 'Pesa 100 kg o mas?',
      answer: (pokemon) => (_metricValue(pokemon.weight) ?? 0) >= 100,
    ),
    for (final stat in _questionStats)
      PokemonQuestionDefinition(
        id: 'top-stat-$stat',
        category: 'Stats',
        label: 'Su stat mas alto es $stat?',
        answer: (pokemon) => _highestStat(pokemon) == stat,
      ),
    for (final move in _questionMoves)
      PokemonQuestionDefinition(
        id: 'move-${move.apiName}',
        category: 'Movimiento',
        label: 'Puede aprender ${move.name}?',
        answer: (pokemon) => pokemon.moves.any(
          (pokemonMove) => pokemonMove.apiName == move.apiName,
        ),
      ),
    for (final ability in _questionAbilities)
      PokemonQuestionDefinition(
        id: 'ability-${ability.apiName}',
        category: 'Habilidad',
        label: 'Puede tener ${ability.name}?',
        answer: (pokemon) => pokemon.abilities.any(
          (pokemonAbility) => pokemonAbility.apiName == ability.apiName,
        ),
      ),
  ];
}

int _generationFromId(int id) {
  if (id <= 151) return 1;
  if (id <= 251) return 2;
  if (id <= 386) return 3;
  if (id <= 493) return 4;
  if (id <= 649) return 5;
  if (id <= 721) return 6;
  if (id <= 809) return 7;
  if (id <= 905) return 8;
  return 9;
}

int? _stageNumber(PokemonPreview pokemon) {
  return switch (pokemon.evolutionStage) {
    PokemonEvolutionStage.standalone || PokemonEvolutionStage.base => 1,
    PokemonEvolutionStage.middle => 2,
    PokemonEvolutionStage.finalStage =>
      pokemon.evolutionLine.length <= 2 ? 2 : 3,
    PokemonEvolutionStage.unknown => null,
  };
}

double? _metricValue(String value) {
  final match = RegExp(r'\d+(\.\d+)?').firstMatch(value);
  return match == null ? null : double.tryParse(match.group(0)!);
}

String _highestStat(PokemonPreview pokemon) {
  if (pokemon.stats.isEmpty) {
    return '-';
  }
  final stats = [...pokemon.stats]
    ..sort((first, second) => second.value.compareTo(first.value));
  return stats.first.name;
}

const _pokemonTypes = [
  'Normal',
  'Fuego',
  'Agua',
  'Planta',
  'Electrico',
  'Hielo',
  'Lucha',
  'Veneno',
  'Tierra',
  'Volador',
  'Psiquico',
  'Bicho',
  'Roca',
  'Fantasma',
  'Dragon',
  'Siniestro',
  'Acero',
  'Hada',
];

const _pokemonColors = [
  'Negro',
  'Azul',
  'Marron',
  'Gris',
  'Verde',
  'Rosa',
  'Violeta',
  'Rojo',
  'Blanco',
  'Amarillo',
];

const _pokemonRegions = [
  'Kanto',
  'Johto',
  'Hoenn',
  'Sinnoh',
  'Teselia',
  'Kalos',
  'Alola',
  'Galar',
  'Hisui',
  'Paldea',
];

const _pokemonHabitats = [
  'Cuevas',
  'Bosques',
  'Praderas',
  'Montanas',
  'Lugares raros',
  'Terreno agreste',
  'Mar',
  'Zona urbana',
  'Orilla del agua',
];

const _questionStats = [
  'HP',
  'Ataque',
  'Defensa',
  'Ataque esp.',
  'Defensa esp.',
  'Velocidad',
];

const _questionMoves = [
  (name: 'Placaje', apiName: 'tackle'),
  (name: 'Aranazo', apiName: 'scratch'),
  (name: 'Impactrueno', apiName: 'thunder-shock'),
];

const _questionAbilities = [
  (name: 'Espesura', apiName: 'overgrow'),
  (name: 'Mar llamas', apiName: 'blaze'),
];
