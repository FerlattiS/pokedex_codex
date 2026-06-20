import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/pokemon_preview.dart';

abstract class PokemonRepository {
  Future<List<PokemonPreview>> fetchPokemonCatalog({int limit = 1302});

  Future<List<PokemonPreview>> fetchPokemonByTypes(List<String> typeNames);

  Future<PokemonPreview> fetchPokemonDetail(int id);

  Future<PokemonAbilityDetail> fetchAbilityDetail(String abilityName);

  Future<PokemonMoveDetail> fetchMoveDetail(String moveName);
}

class PokeApiPokemonRepository implements PokemonRepository {
  PokeApiPokemonRepository({http.Client? client, Uri? baseUri})
    : _client = client ?? http.Client(),
      _baseUri = baseUri ?? Uri.parse('https://pokeapi.co/api/v2');

  final http.Client _client;
  final Uri _baseUri;
  final Map<String, List<PokemonPreview>> _typeCache = {};
  final Map<int, PokemonPreview> _detailCache = {};
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

    final catalog = results.map((result) {
      final item = result as Map<String, dynamic>;
      return _previewFromListItem(item);
    }).toList();

    _catalogCache = catalog;
    _catalogLimit = limit;

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
        final pokemon = data['pokemon'] as List<dynamic>;

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
    final filtered = byId.values.toList()
      ..sort((first, second) => first.id.compareTo(second.id));

    _typeCache[cacheKey] = filtered;

    return filtered;
  }

  @override
  Future<PokemonPreview> fetchPokemonDetail(int id) {
    final cachedDetail = _detailCache[id];
    if (cachedDetail != null) {
      return Future.value(cachedDetail);
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
    );

    _detailCache[pokemon.id] = pokemon;

    return pokemon;
  }

  @override
  Future<PokemonAbilityDetail> fetchAbilityDetail(String abilityName) async {
    final cachedAbility = _abilityCache[abilityName];
    if (cachedAbility != null) {
      return cachedAbility;
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

    return detail;
  }

  @override
  Future<PokemonMoveDetail> fetchMoveDetail(String moveName) async {
    final cachedMove = _moveCache[moveName];
    if (cachedMove != null) {
      return cachedMove;
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
