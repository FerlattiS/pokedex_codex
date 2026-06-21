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

abstract class PokemonQuestionsProgressRepository {
  Future<PokemonQuestionsGameState?> readState(String sessionKey);

  Future<void> writeState(PokemonQuestionsGameState state);
}

class LocalPokemonQuestionsProgressRepository
    implements PokemonQuestionsProgressRepository {
  LocalPokemonQuestionsProgressRepository(this._preferences);

  final SharedPreferences _preferences;

  static const _prefix = 'pokemonQuestions.state.';

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
}

class MemoryPokemonQuestionsProgressRepository
    implements PokemonQuestionsProgressRepository {
  final Map<String, PokemonQuestionsGameState> _statesBySession = {};

  @override
  Future<PokemonQuestionsGameState?> readState(String sessionKey) async {
    return _statesBySession[sessionKey];
  }

  @override
  Future<void> writeState(PokemonQuestionsGameState state) async {
    _statesBySession[state.sessionKey] = state;
  }
}
