import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

enum PokedleDexScope {
  classic,
  full;

  String get label {
    return switch (this) {
      PokedleDexScope.classic => 'Gen 1-2',
      PokedleDexScope.full => 'Todos',
    };
  }

  static PokedleDexScope fromName(String? name) {
    for (final scope in PokedleDexScope.values) {
      if (scope.name == name) {
        return scope;
      }
    }

    return PokedleDexScope.classic;
  }
}

enum PokedleAttemptMode {
  hard,
  easy;

  String get label {
    return switch (this) {
      PokedleAttemptMode.hard => 'Dificil',
      PokedleAttemptMode.easy => 'Facil',
    };
  }

  int? get maxAttempts {
    return switch (this) {
      PokedleAttemptMode.hard => 10,
      PokedleAttemptMode.easy => null,
    };
  }

  static PokedleAttemptMode fromName(String? name) {
    for (final mode in PokedleAttemptMode.values) {
      if (mode.name == name) {
        return mode;
      }
    }

    return PokedleAttemptMode.hard;
  }
}

class PokedleSettings {
  const PokedleSettings({required this.dexScope, required this.attemptMode});

  const PokedleSettings.defaults()
    : dexScope = PokedleDexScope.classic,
      attemptMode = PokedleAttemptMode.hard;

  final PokedleDexScope dexScope;
  final PokedleAttemptMode attemptMode;
}

class PokedleDailyResult {
  const PokedleDailyResult({
    required this.sessionKey,
    required this.dateKey,
    required this.dexScope,
    required this.attemptMode,
    required this.targetId,
    required this.won,
    required this.attempts,
    required this.completedAt,
  });

  final String sessionKey;
  final String dateKey;
  final PokedleDexScope dexScope;
  final PokedleAttemptMode attemptMode;
  final int targetId;
  final bool won;
  final int attempts;
  final DateTime completedAt;

  Map<String, dynamic> toJson() {
    return {
      'sessionKey': sessionKey,
      'dateKey': dateKey,
      'dexScope': dexScope.name,
      'attemptMode': attemptMode.name,
      'targetId': targetId,
      'won': won,
      'attempts': attempts,
      'completedAt': completedAt.toIso8601String(),
    };
  }

  factory PokedleDailyResult.fromJson(Map<String, dynamic> json) {
    return PokedleDailyResult(
      sessionKey: json['sessionKey'] as String,
      dateKey: json['dateKey'] as String,
      dexScope: PokedleDexScope.fromName(json['dexScope'] as String?),
      attemptMode: PokedleAttemptMode.fromName(json['attemptMode'] as String?),
      targetId: json['targetId'] as int,
      won: json['won'] as bool? ?? false,
      attempts: json['attempts'] as int? ?? 0,
      completedAt:
          DateTime.tryParse(json['completedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

abstract class PokedleProgressRepository {
  Future<List<int>> readGuessIds(String dateKey);

  Future<void> writeGuessIds(String dateKey, List<int> pokemonIds);

  Future<PokedleSettings> readSettings();

  Future<void> writeSettings(PokedleSettings settings);

  Future<PokedleDailyResult?> readResult(String sessionKey);

  Future<void> writeResult(PokedleDailyResult result);

  Future<List<PokedleDailyResult>> readResults();
}

class LocalPokedleProgressRepository implements PokedleProgressRepository {
  LocalPokedleProgressRepository(this._preferences);

  final SharedPreferences _preferences;

  static const _prefix = 'pokedle.guesses.';
  static const _scopeKey = 'pokedle.settings.dexScope';
  static const _attemptModeKey = 'pokedle.settings.attemptMode';
  static const _resultsKey = 'pokedle.results';

  @override
  Future<List<int>> readGuessIds(String dateKey) async {
    final values = _preferences.getStringList('$_prefix$dateKey') ?? [];

    return values.map(int.parse).toList();
  }

  @override
  Future<void> writeGuessIds(String dateKey, List<int> pokemonIds) async {
    await _preferences.setStringList(
      '$_prefix$dateKey',
      pokemonIds.map((id) => '$id').toList(),
    );
  }

  @override
  Future<PokedleSettings> readSettings() async {
    return PokedleSettings(
      dexScope: PokedleDexScope.fromName(_preferences.getString(_scopeKey)),
      attemptMode: PokedleAttemptMode.fromName(
        _preferences.getString(_attemptModeKey),
      ),
    );
  }

  @override
  Future<void> writeSettings(PokedleSettings settings) async {
    await _preferences.setString(_scopeKey, settings.dexScope.name);
    await _preferences.setString(_attemptModeKey, settings.attemptMode.name);
  }

  @override
  Future<PokedleDailyResult?> readResult(String sessionKey) async {
    final results = await readResults();

    for (final result in results) {
      if (result.sessionKey == sessionKey) {
        return result;
      }
    }

    return null;
  }

  @override
  Future<void> writeResult(PokedleDailyResult result) async {
    final results = await readResults();
    final nextResults = [
      for (final existingResult in results)
        if (existingResult.sessionKey != result.sessionKey) existingResult,
      result,
    ]..sort((first, second) => first.dateKey.compareTo(second.dateKey));

    await _preferences.setStringList(
      _resultsKey,
      nextResults.map((item) => jsonEncode(item.toJson())).toList(),
    );
  }

  @override
  Future<List<PokedleDailyResult>> readResults() async {
    final values = _preferences.getStringList(_resultsKey) ?? [];

    return values.map(_decodeResult).nonNulls.toList()
      ..sort((first, second) => first.dateKey.compareTo(second.dateKey));
  }

  PokedleDailyResult? _decodeResult(String value) {
    try {
      return PokedleDailyResult.fromJson(
        jsonDecode(value) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }
}

class MemoryPokedleProgressRepository implements PokedleProgressRepository {
  final Map<String, List<int>> _guessIdsByDate = {};
  final Map<String, PokedleDailyResult> _resultsBySession = {};
  PokedleSettings _settings = const PokedleSettings.defaults();

  @override
  Future<List<int>> readGuessIds(String dateKey) async {
    return [...?_guessIdsByDate[dateKey]];
  }

  @override
  Future<void> writeGuessIds(String dateKey, List<int> pokemonIds) async {
    _guessIdsByDate[dateKey] = [...pokemonIds];
  }

  @override
  Future<PokedleSettings> readSettings() async {
    return _settings;
  }

  @override
  Future<void> writeSettings(PokedleSettings settings) async {
    _settings = settings;
  }

  @override
  Future<PokedleDailyResult?> readResult(String sessionKey) async {
    return _resultsBySession[sessionKey];
  }

  @override
  Future<void> writeResult(PokedleDailyResult result) async {
    _resultsBySession[result.sessionKey] = result;
  }

  @override
  Future<List<PokedleDailyResult>> readResults() async {
    return _resultsBySession.values.toList()
      ..sort((first, second) => first.dateKey.compareTo(second.dateKey));
  }
}
