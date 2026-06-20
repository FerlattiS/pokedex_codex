import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/pokemon_preview.dart';

abstract class PokemonCacheStore {
  Future<List<PokemonPreview>?> readCatalog({required int limit});

  Future<void> writeCatalog({
    required int limit,
    required List<PokemonPreview> pokemon,
  });

  Future<PokemonPreview?> readDetail(int id);

  Future<void> writeDetail(PokemonPreview pokemon);

  Future<PokemonAbilityDetail?> readAbility(String abilityName);

  Future<void> writeAbility(String abilityName, PokemonAbilityDetail ability);

  Future<PokemonMoveDetail?> readMove(String moveName);

  Future<void> writeMove(String moveName, PokemonMoveDetail move);
}

class SharedPreferencesPokemonCacheStore implements PokemonCacheStore {
  SharedPreferencesPokemonCacheStore(this._preferences);

  final SharedPreferences _preferences;

  static const _catalogKey = 'pokemon.cache.catalog';
  static const _catalogLimitKey = 'pokemon.cache.catalog.limit';
  static const _detailPrefix = 'pokemon.cache.detail.';
  static const _abilityPrefix = 'pokemon.cache.ability.';
  static const _movePrefix = 'pokemon.cache.move.';

  @override
  Future<List<PokemonPreview>?> readCatalog({required int limit}) async {
    final cachedLimit = _preferences.getInt(_catalogLimitKey) ?? 0;
    final rawValue = _preferences.getString(_catalogKey);

    if (rawValue == null || cachedLimit < limit) {
      return null;
    }

    final data = jsonDecode(rawValue) as List<dynamic>;

    return data
        .cast<Map<String, dynamic>>()
        .map(PokemonPreview.fromJson)
        .take(limit)
        .toList();
  }

  @override
  Future<void> writeCatalog({
    required int limit,
    required List<PokemonPreview> pokemon,
  }) async {
    await _preferences.setString(
      _catalogKey,
      jsonEncode(pokemon.map((item) => item.toJson()).toList()),
    );
    await _preferences.setInt(_catalogLimitKey, limit);
  }

  @override
  Future<PokemonPreview?> readDetail(int id) async {
    final rawValue = _preferences.getString('$_detailPrefix$id');
    if (rawValue == null) {
      return null;
    }

    return PokemonPreview.fromJson(
      jsonDecode(rawValue) as Map<String, dynamic>,
    );
  }

  @override
  Future<void> writeDetail(PokemonPreview pokemon) async {
    await _preferences.setString(
      '$_detailPrefix${pokemon.id}',
      jsonEncode(pokemon.toJson()),
    );
  }

  @override
  Future<PokemonAbilityDetail?> readAbility(String abilityName) async {
    final rawValue = _preferences.getString('$_abilityPrefix$abilityName');
    if (rawValue == null) {
      return null;
    }

    return PokemonAbilityDetail.fromJson(
      jsonDecode(rawValue) as Map<String, dynamic>,
    );
  }

  @override
  Future<void> writeAbility(
    String abilityName,
    PokemonAbilityDetail ability,
  ) async {
    await _preferences.setString(
      '$_abilityPrefix$abilityName',
      jsonEncode(ability.toJson()),
    );
  }

  @override
  Future<PokemonMoveDetail?> readMove(String moveName) async {
    final rawValue = _preferences.getString('$_movePrefix$moveName');
    if (rawValue == null) {
      return null;
    }

    return PokemonMoveDetail.fromJson(
      jsonDecode(rawValue) as Map<String, dynamic>,
    );
  }

  @override
  Future<void> writeMove(String moveName, PokemonMoveDetail move) async {
    await _preferences.setString(
      '$_movePrefix$moveName',
      jsonEncode(move.toJson()),
    );
  }
}
