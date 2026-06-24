import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class PokemonQuestionsGameState {
  const PokemonQuestionsGameState({
    required this.sessionKey,
    this.askedQuestionIds = const [],
    this.guessIds = const [],
  });

  final String sessionKey;
  final List<String> askedQuestionIds;
  final List<int> guessIds;

  Map<String, dynamic> toJson() {
    return {
      'sessionKey': sessionKey,
      'askedQuestionIds': askedQuestionIds,
      'guessIds': guessIds,
    };
  }

  factory PokemonQuestionsGameState.fromJson(Map<String, dynamic> json) {
    return PokemonQuestionsGameState(
      sessionKey: json['sessionKey'] as String,
      askedQuestionIds: (json['askedQuestionIds'] as List<dynamic>? ?? [])
          .cast<String>(),
      guessIds: (json['guessIds'] as List<dynamic>? ?? []).cast<int>(),
    );
  }
}

class PokemonQuestionsPreferences {
  const PokemonQuestionsPreferences({
    this.selectedCategory,
    this.favoriteQuestionIds = const [],
  });

  final String? selectedCategory;
  final List<String> favoriteQuestionIds;

  Map<String, dynamic> toJson() {
    return {
      'selectedCategory': selectedCategory,
      'favoriteQuestionIds': favoriteQuestionIds,
    };
  }

  factory PokemonQuestionsPreferences.fromJson(Map<String, dynamic> json) {
    return PokemonQuestionsPreferences(
      selectedCategory: json['selectedCategory'] as String?,
      favoriteQuestionIds: (json['favoriteQuestionIds'] as List<dynamic>? ?? [])
          .cast<String>(),
    );
  }
}

abstract class PokemonQuestionsProgressRepository {
  Future<PokemonQuestionsGameState?> readState(String sessionKey);

  Future<void> writeState(PokemonQuestionsGameState state);

  Future<PokemonQuestionsPreferences> readPreferences();

  Future<void> writePreferences(PokemonQuestionsPreferences preferences);
}

class LocalPokemonQuestionsProgressRepository
    implements PokemonQuestionsProgressRepository {
  LocalPokemonQuestionsProgressRepository(this._preferences);

  final SharedPreferences _preferences;

  static const _prefix = 'pokemonQuestions.state.';
  static const _preferencesKey = 'pokemonQuestions.preferences';

  @override
  Future<PokemonQuestionsGameState?> readState(String sessionKey) async {
    final value = _preferences.getString('$_prefix$sessionKey');
    if (value == null) {
      return null;
    }

    try {
      return PokemonQuestionsGameState.fromJson(
        jsonDecode(value) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> writeState(PokemonQuestionsGameState state) async {
    await _preferences.setString(
      '$_prefix${state.sessionKey}',
      jsonEncode(state.toJson()),
    );
  }

  @override
  Future<PokemonQuestionsPreferences> readPreferences() async {
    final value = _preferences.getString(_preferencesKey);
    if (value == null) {
      return const PokemonQuestionsPreferences();
    }

    try {
      return PokemonQuestionsPreferences.fromJson(
        jsonDecode(value) as Map<String, dynamic>,
      );
    } catch (_) {
      return const PokemonQuestionsPreferences();
    }
  }

  @override
  Future<void> writePreferences(PokemonQuestionsPreferences preferences) async {
    await _preferences.setString(
      _preferencesKey,
      jsonEncode(preferences.toJson()),
    );
  }
}

class MemoryPokemonQuestionsProgressRepository
    implements PokemonQuestionsProgressRepository {
  final Map<String, PokemonQuestionsGameState> _statesBySession = {};
  PokemonQuestionsPreferences _preferences =
      const PokemonQuestionsPreferences();

  @override
  Future<PokemonQuestionsGameState?> readState(String sessionKey) async {
    return _statesBySession[sessionKey];
  }

  @override
  Future<void> writeState(PokemonQuestionsGameState state) async {
    _statesBySession[state.sessionKey] = state;
  }

  @override
  Future<PokemonQuestionsPreferences> readPreferences() async {
    return _preferences;
  }

  @override
  Future<void> writePreferences(PokemonQuestionsPreferences preferences) async {
    _preferences = preferences;
  }
}
