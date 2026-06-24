import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/pokemon_preview.dart';

class PokemonCacheStats {
  const PokemonCacheStats({
    required this.catalogEntries,
    required this.detailEntries,
    required this.abilityEntries,
    required this.moveEntries,
    required this.approximateBytes,
  });

  final int catalogEntries;
  final int detailEntries;
  final int abilityEntries;
  final int moveEntries;
  final int approximateBytes;

  int get totalEntries =>
      catalogEntries + detailEntries + abilityEntries + moveEntries;
}

abstract class PokemonCacheStore {
  Future<List<PokemonPreview>?> readCatalog({
    required int limit,
    bool allowExpired = false,
  });

  Future<void> writeCatalog({
    required int limit,
    required List<PokemonPreview> pokemon,
  });

  Future<PokemonPreview?> readDetail(int id, {bool allowExpired = false});

  Future<void> writeDetail(PokemonPreview pokemon);

  Future<PokemonAbilityDetail?> readAbility(
    String abilityName, {
    bool allowExpired = false,
  });

  Future<void> writeAbility(String abilityName, PokemonAbilityDetail ability);

  Future<PokemonMoveDetail?> readMove(
    String moveName, {
    bool allowExpired = false,
  });

  Future<void> writeMove(String moveName, PokemonMoveDetail move);

  Future<PokemonCacheStats> readStats();

  Future<void> clear();
}

class SharedPreferencesPokemonCacheStore implements PokemonCacheStore {
  SharedPreferencesPokemonCacheStore(this._preferences);

  final SharedPreferences _preferences;

  static const _schemaVersion = 3;
  static const _versionKey = 'pokemon.cache.version';
  static const _prefix = 'pokemon.cache.v3.';
  static const _catalogKey = '${_prefix}catalog';
  static const _catalogLimitKey = '${_prefix}catalog.limit';
  static const _catalogTimestampKey = '${_prefix}catalog.timestamp';
  static const _detailPrefix = '${_prefix}detail.';
  static const _abilityPrefix = '${_prefix}ability.';
  static const _movePrefix = '${_prefix}move.';
  static const _timestampSuffix = '.timestamp';
  static const _maxDetailEntries = 120;
  static const _maxAbilityEntries = 80;
  static const _maxMoveEntries = 120;
  static const _catalogMaxAge = Duration(days: 7);
  static const _detailMaxAge = Duration(days: 30);
  static const _supportingDataMaxAge = Duration(days: 60);

  @override
  Future<List<PokemonPreview>?> readCatalog({
    required int limit,
    bool allowExpired = false,
  }) async {
    await _ensureVersion();
    final cachedLimit = _preferences.getInt(_catalogLimitKey) ?? 0;
    final rawValue = _preferences.getString(_catalogKey);

    if (rawValue == null ||
        cachedLimit < limit ||
        (!allowExpired && _isExpired(_catalogTimestampKey, _catalogMaxAge))) {
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
    await _ensureVersion();
    await _preferences.setString(
      _catalogKey,
      jsonEncode(pokemon.map((item) => item.toJson()).toList()),
    );
    await _preferences.setInt(_catalogLimitKey, limit);
    await _writeTimestamp(_catalogTimestampKey);
  }

  @override
  Future<PokemonPreview?> readDetail(
    int id, {
    bool allowExpired = false,
  }) async {
    await _ensureVersion();
    final key = '$_detailPrefix$id';
    final rawValue = _preferences.getString(key);
    if (rawValue == null ||
        (!allowExpired && _isExpired('$key$_timestampSuffix', _detailMaxAge))) {
      return null;
    }

    return PokemonPreview.fromJson(
      jsonDecode(rawValue) as Map<String, dynamic>,
    );
  }

  @override
  Future<void> writeDetail(PokemonPreview pokemon) async {
    await _ensureVersion();
    final key = '$_detailPrefix${pokemon.id}';
    await _preferences.setString(key, jsonEncode(pokemon.toJson()));
    await _writeTimestamp('$key$_timestampSuffix');
    await _trimEntries(_detailPrefix, _maxDetailEntries);
  }

  @override
  Future<PokemonAbilityDetail?> readAbility(
    String abilityName, {
    bool allowExpired = false,
  }) async {
    await _ensureVersion();
    final key = '$_abilityPrefix$abilityName';
    final rawValue = _preferences.getString(key);
    if (rawValue == null ||
        (!allowExpired &&
            _isExpired('$key$_timestampSuffix', _supportingDataMaxAge))) {
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
    await _ensureVersion();
    final key = '$_abilityPrefix$abilityName';
    await _preferences.setString(key, jsonEncode(ability.toJson()));
    await _writeTimestamp('$key$_timestampSuffix');
    await _trimEntries(_abilityPrefix, _maxAbilityEntries);
  }

  @override
  Future<PokemonMoveDetail?> readMove(
    String moveName, {
    bool allowExpired = false,
  }) async {
    await _ensureVersion();
    final key = '$_movePrefix$moveName';
    final rawValue = _preferences.getString(key);
    if (rawValue == null ||
        (!allowExpired &&
            _isExpired('$key$_timestampSuffix', _supportingDataMaxAge))) {
      return null;
    }

    return PokemonMoveDetail.fromJson(
      jsonDecode(rawValue) as Map<String, dynamic>,
    );
  }

  @override
  Future<void> writeMove(String moveName, PokemonMoveDetail move) async {
    await _ensureVersion();
    final key = '$_movePrefix$moveName';
    await _preferences.setString(key, jsonEncode(move.toJson()));
    await _writeTimestamp('$key$_timestampSuffix');
    await _trimEntries(_movePrefix, _maxMoveEntries);
  }

  @override
  Future<PokemonCacheStats> readStats() async {
    await _ensureVersion();
    final keys = _preferences.getKeys();
    final dataKeys = keys.where(
      (key) => key.startsWith(_prefix) && !key.endsWith(_timestampSuffix),
    );
    var bytes = 0;
    for (final key in dataKeys) {
      final value = _preferences.get(key);
      bytes += key.length + (value?.toString().length ?? 0);
    }

    return PokemonCacheStats(
      catalogEntries: _preferences.containsKey(_catalogKey) ? 1 : 0,
      detailEntries: _dataKeysForPrefix(_detailPrefix).length,
      abilityEntries: _dataKeysForPrefix(_abilityPrefix).length,
      moveEntries: _dataKeysForPrefix(_movePrefix).length,
      approximateBytes: bytes,
    );
  }

  @override
  Future<void> clear() async {
    final keys = _preferences.getKeys().where(
      (key) => key.startsWith('pokemon.cache.'),
    );
    for (final key in keys.toList()) {
      await _preferences.remove(key);
    }
    await _preferences.setInt(_versionKey, _schemaVersion);
  }

  Future<void> _ensureVersion() async {
    if (_preferences.getInt(_versionKey) == _schemaVersion) {
      return;
    }
    await clear();
  }

  bool _isExpired(String timestampKey, Duration maxAge) {
    final timestamp = _preferences.getInt(timestampKey);
    if (timestamp == null) {
      return true;
    }
    return DateTime.now().millisecondsSinceEpoch - timestamp >
        maxAge.inMilliseconds;
  }

  Future<void> _writeTimestamp(String key) async {
    await _preferences.setInt(key, DateTime.now().millisecondsSinceEpoch);
  }

  Set<String> _dataKeysForPrefix(String prefix) {
    return _preferences.getKeys().where((key) {
      return key.startsWith(prefix) && !key.endsWith(_timestampSuffix);
    }).toSet();
  }

  Future<void> _trimEntries(String prefix, int maxEntries) async {
    final keys = _dataKeysForPrefix(prefix);
    if (keys.length <= maxEntries) {
      return;
    }

    final oldestFirst = keys.toList()
      ..sort((first, second) {
        final firstTimestamp =
            _preferences.getInt('$first$_timestampSuffix') ?? 0;
        final secondTimestamp =
            _preferences.getInt('$second$_timestampSuffix') ?? 0;
        return firstTimestamp.compareTo(secondTimestamp);
      });

    for (final key in oldestFirst.take(keys.length - maxEntries)) {
      await _preferences.remove(key);
      await _preferences.remove('$key$_timestampSuffix');
    }
  }
}
