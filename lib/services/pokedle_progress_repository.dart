import 'package:shared_preferences/shared_preferences.dart';

abstract class PokedleProgressRepository {
  Future<List<int>> readGuessIds(String dateKey);

  Future<void> writeGuessIds(String dateKey, List<int> pokemonIds);
}

class LocalPokedleProgressRepository implements PokedleProgressRepository {
  LocalPokedleProgressRepository(this._preferences);

  final SharedPreferences _preferences;

  static const _prefix = 'pokedle.guesses.';

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
}

class MemoryPokedleProgressRepository implements PokedleProgressRepository {
  final Map<String, List<int>> _guessIdsByDate = {};

  @override
  Future<List<int>> readGuessIds(String dateKey) async {
    return [...?_guessIdsByDate[dateKey]];
  }

  @override
  Future<void> writeGuessIds(String dateKey, List<int> pokemonIds) async {
    _guessIdsByDate[dateKey] = [...pokemonIds];
  }
}
