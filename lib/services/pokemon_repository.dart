import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/pokemon_preview.dart';
import 'pokemon_cache_store.dart';

const _typeApiNames = <String>[
  'normal',
  'fire',
  'water',
  'electric',
  'grass',
  'ice',
  'fighting',
  'poison',
  'ground',
  'flying',
  'psychic',
  'bug',
  'rock',
  'ghost',
  'dragon',
  'dark',
  'steel',
  'fairy',
];

abstract class PokemonRepository {
  Future<List<PokemonPreview>> fetchPokemonCatalog({int limit = 1302});

  Future<List<PokemonPreview>> fetchPokemonByTypes(List<String> typeNames);

  Future<PokemonPreview> fetchPokemonMetadata(int id);

  Future<PokemonPreview> fetchPokemonDetail(int id);

  Future<PokemonAbilityDetail> fetchAbilityDetail(String abilityName);

  Future<PokemonMoveDetail> fetchMoveDetail(String moveName);
}

class PokeApiPokemonRepository implements PokemonRepository {
  PokeApiPokemonRepository({http.Client? client, Uri? baseUri, this.cacheStore})
    : _client = client ?? http.Client(),
      _baseUri = baseUri ?? Uri.parse('https://pokeapi.co/api/v2');

  final http.Client _client;
  final Uri _baseUri;
  final PokemonCacheStore? cacheStore;
  final Map<String, List<PokemonPreview>> _typeCache = {};
  final Map<int, PokemonPreview> _detailCache = {};
  final Map<int, PokemonPreview> _metadataCache = {};
  final Map<String, PokemonAbilityDetail> _abilityCache = {};
  final Map<String, PokemonMoveDetail> _moveCache = {};
  List<PokemonPreview>? _catalogCache;
  var _catalogLimit = 0;

  @override
  Future<List<PokemonPreview>> fetchPokemonCatalog({int limit = 1302}) async {
    final cachedCatalog = _catalogCache;
    if (cachedCatalog != null && _catalogLimit >= limit) {
      return cachedCatalog.take(limit).toList();
    }

    final storedCatalog = await cacheStore?.readCatalog(limit: limit);
    if (storedCatalog != null) {
      _catalogCache = storedCatalog;
      _catalogLimit = limit;

      return storedCatalog;
    }

    final listUri = _baseUri.replace(
      path: '${_baseUri.path}/pokemon',
      queryParameters: {'limit': '$limit', 'offset': '0'},
    );
    final response = await _client.get(listUri);

    if (response.statusCode != 200) {
      throw Exception('No se pudo cargar la lista de Pokemon');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final results = data['results'] as List<dynamic>;

    final typesByPokemonId = await _fetchCatalogTypesByPokemonId(limit);
    final catalog = results.map((result) {
      final item = result as Map<String, dynamic>;
      final id = _readIdFromUrl(item['url'] as String);
      return _previewFromListItem(item, types: typesByPokemonId[id] ?? []);
    }).toList();

    _catalogCache = catalog;
    _catalogLimit = limit;
    await cacheStore?.writeCatalog(limit: limit, pokemon: catalog);

    return catalog;
  }

  @override
  Future<List<PokemonPreview>> fetchPokemonByTypes(
    List<String> typeNames,
  ) async {
    if (typeNames.isEmpty) {
      return fetchPokemonCatalog();
    }

    final sortedTypes = typeNames.toList()..sort();
    final cacheKey = sortedTypes.join('|');
    final displayTypes = typeNames.toList();
    final cachedTypes = _typeCache[cacheKey];
    if (cachedTypes != null) {
      return cachedTypes;
    }

    final typeSets = await Future.wait(
      sortedTypes.map((typeName) async {
        final typeUri = _baseUri.replace(
          path: '${_baseUri.path}/type/$typeName',
        );
        final response = await _client.get(typeUri);

        if (response.statusCode != 200) {
          throw Exception('No se pudo cargar el tipo $typeName');
        }

        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final pokemon = data['pokemon'] as List<dynamic>? ?? [];

        return pokemon.map((slot) {
          final slotData = slot as Map<String, dynamic>;
          final pokemonData = slotData['pokemon'] as Map<String, dynamic>;
          return _previewFromListItem(pokemonData, types: displayTypes);
        }).toList();
      }),
    );

    final commonIds = typeSets
        .map((pokemon) => pokemon.map((item) => item.id).toSet())
        .reduce((value, element) => value.intersection(element));
    final byId = {
      for (final pokemon in typeSets.expand((items) => items))
        if (commonIds.contains(pokemon.id)) pokemon.id: pokemon,
    };
    final catalogById = {
      for (final pokemon in _catalogCache ?? <PokemonPreview>[])
        pokemon.id: pokemon,
    };
    final filtered = byId.values.map((pokemon) {
      return catalogById[pokemon.id] ?? pokemon;
    }).toList()..sort((first, second) => first.id.compareTo(second.id));

    _typeCache[cacheKey] = filtered;

    return filtered;
  }

  @override
  Future<PokemonPreview> fetchPokemonMetadata(int id) async {
    final cachedDetail = _detailCache[id];
    if (cachedDetail != null && cachedDetail.evolutionLine.isNotEmpty) {
      return cachedDetail;
    }

    final cachedMetadata = _metadataCache[id];
    if (cachedMetadata != null) {
      return cachedMetadata;
    }

    final speciesUri = _baseUri.replace(
      path: '${_baseUri.path}/pokemon-species/$id',
    );
    final speciesResponse = await _client.get(speciesUri);

    if (speciesResponse.statusCode != 200) {
      throw Exception('No se pudo cargar la metadata del Pokemon');
    }

    final metadata = await _readPokemonMetadata(speciesResponse, id);
    _metadataCache[id] = metadata;

    return metadata;
  }

  @override
  Future<PokemonPreview> fetchPokemonDetail(int id) {
    final cachedDetail = _detailCache[id];
    if (cachedDetail != null) {
      return Future.value(cachedDetail);
    }

    return _readOrFetchPokemonDetail(id);
  }

  Future<PokemonPreview> _readOrFetchPokemonDetail(int id) async {
    final storedDetail = await cacheStore?.readDetail(id);
    if (storedDetail != null) {
      _detailCache[id] = storedDetail;

      return storedDetail;
    }

    return _fetchPokemonDetail(id);
  }

  Future<PokemonPreview> _fetchPokemonDetail(int id) async {
    final detailUri = _baseUri.replace(path: '${_baseUri.path}/pokemon/$id');
    final speciesUri = _baseUri.replace(
      path: '${_baseUri.path}/pokemon-species/$id',
    );
    final responses = await Future.wait([
      _client.get(detailUri),
      _client.get(speciesUri),
    ]);
    final response = responses[0];
    final speciesResponse = responses[1];

    if (response.statusCode != 200) {
      throw Exception('No se pudo cargar el Pokemon');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final types = data['types'] as List<dynamic>;
    final abilities = data['abilities'] as List<dynamic>;
    final stats = data['stats'] as List<dynamic>;
    final moves = data['moves'] as List<dynamic>;
    final sprites = data['sprites'] as Map<String, dynamic>;
    final otherSprites = sprites['other'] as Map<String, dynamic>?;
    final officialArtwork =
        otherSprites?['official-artwork'] as Map<String, dynamic>?;

    final metadata = await _readPokemonMetadata(
      speciesResponse,
      data['id'] as int,
    );
    final pokemon = PokemonPreview(
      id: data['id'] as int,
      name: _formatName(data['name'] as String),
      types: types.map(_readTypeName).toList(),
      description: _readDescription(speciesResponse),
      height: _formatMetric(data['height'] as int),
      weight: _formatMetric(data['weight'] as int, unit: 'kg'),
      abilities: abilities.map(_readAbility).toList(),
      stats: stats.map(_readStat).toList(),
      moves: moves.map(_readMoveSummary).nonNulls.toList(),
      imageUrl:
          officialArtwork?['front_default'] as String? ??
          sprites['front_default'] as String?,
      isLegendary: metadata.isLegendary,
      isMythical: metadata.isMythical,
      evolvesByItem: metadata.evolvesByItem,
      evolutionStage: metadata.evolutionStage,
      evolutionLine: metadata.evolutionLine,
    );

    _detailCache[pokemon.id] = pokemon;
    _metadataCache[pokemon.id] = metadata;
    await cacheStore?.writeDetail(pokemon);

    return pokemon;
  }

  @override
  Future<PokemonAbilityDetail> fetchAbilityDetail(String abilityName) async {
    final cachedAbility = _abilityCache[abilityName];
    if (cachedAbility != null) {
      return cachedAbility;
    }

    final storedAbility = await cacheStore?.readAbility(abilityName);
    if (storedAbility != null) {
      _abilityCache[abilityName] = storedAbility;

      return storedAbility;
    }

    final response = await _client.get(
      _baseUri.replace(path: '${_baseUri.path}/ability/$abilityName'),
    );

    if (response.statusCode != 200) {
      throw Exception('No se pudo cargar la habilidad');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final detail = PokemonAbilityDetail(
      name: _readLocalizedName(data, fallbackName: abilityName),
      englishName: _readEnglishName(data, fallbackName: abilityName),
      description: _readFlavorText(data),
      englishDescription: _readFlavorText(data, languageCode: 'en'),
      technicalDetail: _readEffectText(data),
    );

    _abilityCache[abilityName] = detail;
    await cacheStore?.writeAbility(abilityName, detail);

    return detail;
  }

  @override
  Future<PokemonMoveDetail> fetchMoveDetail(String moveName) async {
    final cachedMove = _moveCache[moveName];
    if (cachedMove != null) {
      return cachedMove;
    }

    final storedMove = await cacheStore?.readMove(moveName);
    if (storedMove != null) {
      _moveCache[moveName] = storedMove;

      return storedMove;
    }

    final response = await _client.get(
      _baseUri.replace(path: '${_baseUri.path}/move/$moveName'),
    );

    if (response.statusCode != 200) {
      throw Exception('No se pudo cargar el movimiento');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final type = data['type'] as Map<String, dynamic>;
    final damageClass = data['damage_class'] as Map<String, dynamic>;
    final detail = PokemonMoveDetail(
      name: _readLocalizedName(data, fallbackName: moveName),
      englishName: _readEnglishName(data, fallbackName: moveName),
      type: _formatTypeName(type['name'] as String),
      damageClass: _formatName(damageClass['name'] as String),
      power: data['power'] as int?,
      pp: data['pp'] as int,
      accuracy: data['accuracy'] as int?,
      description: _readFlavorText(data),
      technicalDetail: _readEffectText(data),
    );

    _moveCache[moveName] = detail;
    await cacheStore?.writeMove(moveName, detail);

    return detail;
  }

  PokemonPreview _previewFromListItem(
    Map<String, dynamic> item, {
    List<String> types = const [],
  }) {
    final id = _readIdFromUrl(item['url'] as String);

    return PokemonPreview(
      id: id,
      name: _formatName(item['name'] as String),
      types: types.map(_formatTypeName).toList(),
      imageUrl:
          'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$id.png',
    );
  }

  Future<Map<int, List<String>>> _fetchCatalogTypesByPokemonId(
    int limit,
  ) async {
    final typesByPokemonId = <int, List<String>>{};
    await Future.wait(
      _typeApiNames.map((typeName) async {
        final typeUri = _baseUri.replace(
          path: '${_baseUri.path}/type/$typeName',
        );
        final response = await _client.get(typeUri);

        if (response.statusCode != 200) {
          return;
        }

        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final pokemon = data['pokemon'] as List<dynamic>? ?? [];
        for (final slot in pokemon) {
          final slotData = slot as Map<String, dynamic>;
          final pokemonData = slotData['pokemon'] as Map<String, dynamic>;
          final id = _readIdFromUrl(pokemonData['url'] as String);
          if (id > limit) {
            continue;
          }

          typesByPokemonId
              .putIfAbsent(id, () => [])
              .add(_formatTypeName(typeName));
        }
      }),
    );

    return typesByPokemonId;
  }

  String _readTypeName(dynamic typeSlot) {
    final typeData = typeSlot as Map<String, dynamic>;
    final type = typeData['type'] as Map<String, dynamic>;
    return _formatTypeName(type['name'] as String);
  }

  PokemonAbility _readAbility(dynamic abilitySlot) {
    final abilityData = abilitySlot as Map<String, dynamic>;
    final ability = abilityData['ability'] as Map<String, dynamic>;
    final apiName = ability['name'] as String;

    return PokemonAbility(name: _formatName(apiName), apiName: apiName);
  }

  PokemonMoveSummary? _readMoveSummary(dynamic moveSlot) {
    final moveData = moveSlot as Map<String, dynamic>;
    final move = moveData['move'] as Map<String, dynamic>;
    final details = moveData['version_group_details'] as List<dynamic>;

    if (details.isEmpty) {
      return null;
    }

    final detail = details.last as Map<String, dynamic>;
    final method = detail['move_learn_method'] as Map<String, dynamic>;
    final apiName = move['name'] as String;

    return PokemonMoveSummary(
      name: _formatName(apiName),
      apiName: apiName,
      learnMethod: _formatLearnMethod(method['name'] as String),
      level: detail['level_learned_at'] as int,
    );
  }

  String _readDescription(http.Response response) {
    if (response.statusCode != 200) {
      return 'Datos obtenidos desde PokeAPI.';
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final entries = data['flavor_text_entries'] as List<dynamic>;
    final entry = entries.cast<Map<String, dynamic>>().firstWhere(
      (entry) {
        final language = entry['language'] as Map<String, dynamic>;
        return language['name'] == 'es';
      },
      orElse: () => entries.cast<Map<String, dynamic>>().firstWhere((entry) {
        final language = entry['language'] as Map<String, dynamic>;
        return language['name'] == 'en';
      }, orElse: () => const {'flavor_text': 'Datos obtenidos desde PokeAPI.'}),
    );

    return _cleanDescription(entry['flavor_text'] as String);
  }

  Future<PokemonPreview> _readPokemonMetadata(
    http.Response speciesResponse,
    int pokemonId,
  ) async {
    if (speciesResponse.statusCode != 200) {
      return PokemonPreview(id: pokemonId, name: '#$pokemonId');
    }

    final speciesData =
        jsonDecode(speciesResponse.body) as Map<String, dynamic>;
    final speciesName = speciesData['name'] as String? ?? '#$pokemonId';
    final evolutionChain =
        speciesData['evolution_chain'] as Map<String, dynamic>?;
    final evolutionChainUrl = evolutionChain?['url'] as String?;
    var evolutionLine = <PokemonEvolutionStep>[
      PokemonEvolutionStep(
        id: pokemonId,
        name: _formatName(speciesName),
        method: 'Base',
      ),
    ];
    var evolutionStage = PokemonEvolutionStage.unknown;
    var evolvesByItem = false;

    if (evolutionChainUrl != null) {
      final evolutionResponse = await _client.get(Uri.parse(evolutionChainUrl));
      if (evolutionResponse.statusCode == 200) {
        final evolutionData =
            jsonDecode(evolutionResponse.body) as Map<String, dynamic>;
        final chain = evolutionData['chain'] as Map<String, dynamic>;
        evolutionLine = _readEvolutionLine(chain);
        evolutionStage = _readEvolutionStage(chain, speciesName);
        evolvesByItem = _readEvolvesByItem(chain, speciesName);
      }
    }

    return PokemonPreview(
      id: pokemonId,
      name: _formatName(speciesName),
      isLegendary: speciesData['is_legendary'] as bool? ?? false,
      isMythical: speciesData['is_mythical'] as bool? ?? false,
      evolvesByItem: evolvesByItem,
      evolutionStage: evolutionStage,
      evolutionLine: evolutionLine,
    );
  }

  List<PokemonEvolutionStep> _readEvolutionLine(Map<String, dynamic> chain) {
    final steps = <PokemonEvolutionStep>[];

    void visit(Map<String, dynamic> node, String method) {
      final species = node['species'] as Map<String, dynamic>;
      steps.add(
        PokemonEvolutionStep(
          id: _readIdFromUrl(species['url'] as String),
          name: _formatName(species['name'] as String),
          method: method,
        ),
      );

      final evolvesTo = node['evolves_to'] as List<dynamic>? ?? [];
      for (final child in evolvesTo) {
        final childNode = child as Map<String, dynamic>;
        final details = childNode['evolution_details'] as List<dynamic>? ?? [];
        final detail = details.isEmpty
            ? null
            : details.cast<Map<String, dynamic>>().first;
        visit(childNode, _formatEvolutionMethod(detail));
      }
    }

    visit(chain, 'Base');

    if (steps.length == 1) {
      return [
        PokemonEvolutionStep(
          id: steps.first.id,
          name: steps.first.name,
          method: 'Sin evolucion',
        ),
      ];
    }

    return steps;
  }

  PokemonEvolutionStage _readEvolutionStage(
    Map<String, dynamic> chain,
    String speciesName,
  ) {
    final info = _findEvolutionNode(chain, speciesName);
    if (info == null) {
      return PokemonEvolutionStage.unknown;
    }

    if (info.totalNodes == 1) {
      return PokemonEvolutionStage.standalone;
    }

    if (info.depth == 0) {
      return PokemonEvolutionStage.base;
    }

    if (info.hasChildren) {
      return PokemonEvolutionStage.middle;
    }

    return PokemonEvolutionStage.finalStage;
  }

  bool _readEvolvesByItem(Map<String, dynamic> chain, String speciesName) {
    final info = _findEvolutionNode(chain, speciesName);
    if (info == null) {
      return false;
    }

    return info.outgoingDetails.any(_evolutionDetailUsesItem);
  }

  _EvolutionNodeInfo? _findEvolutionNode(
    Map<String, dynamic> chain,
    String speciesName,
  ) {
    var totalNodes = 0;
    _EvolutionNodeInfo? result;

    void visit(Map<String, dynamic> node, int depth) {
      totalNodes += 1;
      final species = node['species'] as Map<String, dynamic>;
      final evolvesTo = node['evolves_to'] as List<dynamic>? ?? [];

      if (species['name'] == speciesName) {
        result = _EvolutionNodeInfo(
          depth: depth,
          hasChildren: evolvesTo.isNotEmpty,
          outgoingDetails: [
            for (final child in evolvesTo)
              ...((child as Map<String, dynamic>)['evolution_details']
                          as List<dynamic>? ??
                      [])
                  .cast<Map<String, dynamic>>(),
          ],
          totalNodes: 0,
        );
      }

      for (final child in evolvesTo) {
        visit(child as Map<String, dynamic>, depth + 1);
      }
    }

    visit(chain, 0);

    final found = result;
    if (found == null) {
      return null;
    }

    return _EvolutionNodeInfo(
      depth: found.depth,
      hasChildren: found.hasChildren,
      outgoingDetails: found.outgoingDetails,
      totalNodes: totalNodes,
    );
  }

  bool _evolutionDetailUsesItem(Map<String, dynamic> detail) {
    final trigger = detail['trigger'] as Map<String, dynamic>?;
    return trigger?['name'] == 'use-item' ||
        detail['item'] != null ||
        detail['held_item'] != null;
  }

  String _formatEvolutionMethod(Map<String, dynamic>? detail) {
    if (detail == null) {
      return 'Metodo no disponible';
    }

    final trigger = detail['trigger'] as Map<String, dynamic>?;
    final triggerName = trigger?['name'] as String?;
    final item = _readNamedResource(detail['item']);
    final heldItem = _readNamedResource(detail['held_item']);
    final knownMove = _readNamedResource(detail['known_move']);
    final location = _readNamedResource(detail['location']);
    final minLevel = detail['min_level'] as int?;
    final minHappiness = detail['min_happiness'] as int?;
    final minBeauty = detail['min_beauty'] as int?;
    final minAffection = detail['min_affection'] as int?;
    final timeOfDay = detail['time_of_day'] as String? ?? '';
    final parts = <String>[];

    switch (triggerName) {
      case 'level-up':
        if (minLevel != null) {
          parts.add('Nivel $minLevel');
        } else {
          parts.add('Subir nivel');
        }
      case 'use-item':
        parts.add(item == null ? 'Usar objeto' : 'Usar $item');
      case 'trade':
        parts.add(
          heldItem == null ? 'Intercambio' : 'Intercambio con $heldItem',
        );
      case 'shed':
        parts.add('Espacio libre en equipo');
      case 'spin':
        parts.add('Giro especial');
      case 'tower-of-darkness':
        parts.add('Torre de las Sombras');
      case 'tower-of-waters':
        parts.add('Torre de las Aguas');
      case 'three-critical-hits':
        parts.add('Tres golpes criticos');
      case 'take-damage':
        parts.add('Tras recibir dano');
      case 'other':
        parts.add('Metodo especial');
      default:
        parts.add(_formatName(triggerName ?? 'Metodo especial'));
    }

    if (knownMove != null) {
      parts.add('con $knownMove');
    }
    if (location != null) {
      parts.add('en $location');
    }
    if (minHappiness != null) {
      parts.add('amistad $minHappiness+');
    }
    if (minBeauty != null) {
      parts.add('belleza $minBeauty+');
    }
    if (minAffection != null) {
      parts.add('afecto $minAffection+');
    }
    if (timeOfDay.isNotEmpty) {
      parts.add(timeOfDay == 'day' ? 'de dia' : 'de noche');
    }

    return parts.join(' - ');
  }

  String? _readNamedResource(dynamic value) {
    if (value == null) {
      return null;
    }

    final data = value as Map<String, dynamic>;
    return _formatName((data['name'] as String).replaceAll('-', ' '));
  }

  String _cleanDescription(String value) {
    return value.replaceAll('\n', ' ').replaceAll('\f', ' ');
  }

  PokemonStat _readStat(dynamic statSlot) {
    final statData = statSlot as Map<String, dynamic>;
    final stat = statData['stat'] as Map<String, dynamic>;

    return PokemonStat(
      name: _formatStatName(stat['name'] as String),
      value: statData['base_stat'] as int,
    );
  }

  String _readLocalizedName(
    Map<String, dynamic> data, {
    required String fallbackName,
  }) {
    return _readNameForLanguage(data, 'es', fallbackName: fallbackName) ??
        _readNameForLanguage(data, 'en', fallbackName: fallbackName) ??
        _formatName(fallbackName);
  }

  String _readEnglishName(
    Map<String, dynamic> data, {
    required String fallbackName,
  }) {
    return _readNameForLanguage(data, 'en', fallbackName: fallbackName) ??
        _formatName(fallbackName);
  }

  String? _readNameForLanguage(
    Map<String, dynamic> data,
    String languageCode, {
    required String fallbackName,
  }) {
    final names = data['names'] as List<dynamic>? ?? [];
    for (final item in names) {
      final nameData = item as Map<String, dynamic>;
      final language = nameData['language'] as Map<String, dynamic>;
      if (language['name'] == languageCode) {
        return nameData['name'] as String;
      }
    }

    return null;
  }

  String _readFlavorText(
    Map<String, dynamic> data, {
    String languageCode = 'es',
  }) {
    final entries = data['flavor_text_entries'] as List<dynamic>? ?? [];
    final fallbackText = languageCode == 'es'
        ? _readFlavorText(data, languageCode: 'en')
        : 'Descripcion no disponible.';

    for (final item in entries) {
      final entry = item as Map<String, dynamic>;
      final language = entry['language'] as Map<String, dynamic>;
      if (language['name'] == languageCode) {
        return _cleanDescription(entry['flavor_text'] as String);
      }
    }

    return fallbackText;
  }

  String _readEffectText(Map<String, dynamic> data) {
    final entries = data['effect_entries'] as List<dynamic>? ?? [];
    for (final item in entries) {
      final entry = item as Map<String, dynamic>;
      final language = entry['language'] as Map<String, dynamic>;
      if (language['name'] == 'en') {
        return _cleanDescription(entry['effect'] as String);
      }
    }

    return 'Detalle tecnico no disponible.';
  }

  String _formatTypeName(String value) {
    return switch (value) {
      'water' => 'Agua',
      'ground' => 'Tierra',
      'fire' => 'Fuego',
      'grass' => 'Planta',
      'electric' => 'Electrico',
      'normal' => 'Normal',
      'fighting' => 'Lucha',
      'poison' => 'Veneno',
      'flying' => 'Volador',
      'psychic' => 'Psiquico',
      'bug' => 'Bicho',
      'rock' => 'Roca',
      'ghost' => 'Fantasma',
      'dragon' => 'Dragon',
      'dark' => 'Siniestro',
      'steel' => 'Acero',
      'fairy' => 'Hada',
      'ice' => 'Hielo',
      _ => _formatName(value),
    };
  }

  String _formatName(String value) {
    if (value.isEmpty) {
      return value;
    }

    return value[0].toUpperCase() + value.substring(1);
  }

  String _formatLearnMethod(String value) {
    return switch (value) {
      'level-up' => 'Nivel',
      'machine' => 'Maquina',
      'egg' => 'Huevo',
      'tutor' => 'Tutor',
      'stadium-surfing-pikachu' => 'Evento',
      'light-ball-egg' => 'Huevo especial',
      'colosseum-purification' => 'Purificacion',
      'xd-shadow' => 'Shadow',
      'xd-purification' => 'Purificacion XD',
      'form-change' => 'Cambio de forma',
      'zygarde-cube' => 'Cubo Zygarde',
      _ => _formatName(value),
    };
  }

  String _formatStatName(String value) {
    return switch (value) {
      'hp' => 'HP',
      'attack' => 'Ataque',
      'defense' => 'Defensa',
      'special-attack' => 'Ataque esp.',
      'special-defense' => 'Defensa esp.',
      'speed' => 'Velocidad',
      _ => _formatName(value),
    };
  }

  String _formatMetric(int value, {String unit = 'm'}) {
    return '${(value / 10).toStringAsFixed(1)} $unit';
  }

  int _readIdFromUrl(String url) {
    final segments = Uri.parse(url).pathSegments.where((segment) {
      return segment.isNotEmpty;
    }).toList();

    return int.parse(segments.last);
  }
}

class _EvolutionNodeInfo {
  const _EvolutionNodeInfo({
    required this.depth,
    required this.hasChildren,
    required this.outgoingDetails,
    required this.totalNodes,
  });

  final int depth;
  final bool hasChildren;
  final List<Map<String, dynamic>> outgoingDetails;
  final int totalNodes;
}
